SET SERVEROUTPUT ON

-- Ganancia mensual de la clinica
VAR b_ganan_anual NUMBER
EXEC :b_ganan_anual := 500000000

-- Porcentaje movilizacion
VAR b_movilizacion NUMBER
EXEC :b_movilizacion := 12

-- Porcentaje colacion
VAR b_colacion NUMBER
EXEC :b_colacion := 20

DECLARE

    -- Declaracion de cursor explicito con datos de todos los medicos
    CURSOR c_medicos IS
    SELECT EXTRACT(YEAR FROM SYSDATE) anno_tributario,
        med_run numrun,
        dv_run,
        pnombre||' '||snombre||' '||apaterno||' '||amaterno nombre_completo,
        c.nombre cargo,
        m.fecha_contrato fecha_contrato,
        m.sueldo_base sueldo_base_mensual
    FROM medico m
    JOIN cargo c ON c.car_id = m.car_id
    ORDER BY med_run;
    
    -- Declaracion de registro
    r_infomsii info_medico_sii%ROWTYPE;

    -- Contadores para encriptar informacion
    v_rn_enc NUMBER(4) := 100;
    v_dv_enc NUMBER(4) := 10;
    v_sb_enc NUMBER(4) := 900;
    
    -- Otras variables de uso intermedio
    v_meses_trab NUMBER(4);
    v_num_aten NUMBER (2);
    v_num_aten_nested NUMBER (2);
    v_porc tramo_asig_atmed.porc_asig%TYPE;
    v_bono_gana NUMBER(7);
    v_bono_aten NUMBER(7);
    v_num_at_sobre_cinco NUMBER(2);
    
    -- Declaracion de tipo de varray
    TYPE vr_tipo_porc IS VARRAY(3) OF
        NUMBER(9);
    
    -- Declaracion y asignacion de valores de porcentajes y ganancias en varray
    vr_porcentajes vr_tipo_porc := vr_tipo_porc(
        :b_ganan_anual,:b_movilizacion,:b_colacion);

BEGIN
    
    -- Se trunca tabla en tiempo de ejecucion
    EXECUTE IMMEDIATE 'TRUNCATE TABLE info_medico_sii';

    -- Iteracion principal para realizar cada insert
    FOR i IN c_medicos LOOP
    
        -- Asignacion directa de valores provenientes del cursor/tablas
        r_infomsii.anno_tributario := i.anno_tributario;
        r_infomsii.numrun := i.numrun;
        r_infomsii.dv_run := i.dv_run;
        r_infomsii.nombre_completo := i.nombre_completo;
        r_infomsii.cargo := i.cargo;
        r_infomsii.sueldo_base_mensual := i.sueldo_base_mensual;
        
        -- Calculo de meses trabajados
        SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_contrato))-EXTRACT(MONTH FROM SYSDATE)+1
            INTO v_meses_trab
            FROM medico
            WHERE med_run = i.numrun;
            
        IF v_meses_trab > 12 THEN
            r_infomsii.meses_trabajados := 12;
        ELSE 
            r_infomsii.meses_trabajados := v_meses_trab;
        END IF;  
        
        -- Calculo sueldo base anual
        r_infomsii.sueldo_base_anual := r_infomsii.sueldo_base_mensual*r_infomsii.meses_trabajados;  
        
        -- Calculo bonificaciones por atenciones
        SELECT
            COUNT(a.ate_id)
            INTO v_num_aten
            FROM medico m
            LEFT JOIN atencion a ON a.med_run = m.med_run
            AND EXTRACT(YEAR FROM a.fecha_atencion) = EXTRACT(YEAR FROM SYSDATE)-1
            WHERE m.med_run = i.numrun
            GROUP BY m.med_run;
        
        IF v_num_aten > 0 THEN
            SELECT porc_asig
                INTO v_porc
                FROM tramo_asig_atmed
                WHERE v_num_aten BETWEEN tramo_inf_atm AND tramo_sup_atm;
        ELSE v_porc := 0;
        END IF;
        
        IF v_num_aten > 0 THEN
            v_bono_aten := r_infomsii.sueldo_base_mensual*v_porc/100;
        ELSE v_bono_aten := 0;
        END IF;  
        
        -- Calculo bonificaciones por ganancias clinica        
        v_num_at_sobre_cinco := 0;
        
        IF v_num_aten > 5 THEN -- En este control de condicion se decide si el medico recibe bono de ganancias en diciembre
            
            -- En este loop se obtiene el total de medicos que superaron las 5 atenciones anuales
            FOR e IN (SELECT * FROM medico) LOOP 

                SELECT COUNT(a.ate_id)
                    INTO v_num_aten_nested
                    FROM medico m
                    LEFT JOIN atencion a ON a.med_run = m.med_run
                    AND EXTRACT(YEAR FROM a.fecha_atencion) = EXTRACT(YEAR FROM SYSDATE)-1
                    WHERE m.med_run = e.med_run;
                
                --- Cada vez que se encuentre un medico con mas de 5 atenciones el contador se incrementa
                IF v_num_aten_nested > 5 THEN
                    v_num_at_sobre_cinco := v_num_at_sobre_cinco+1;
                END IF;
                
            END LOOP;   
        
        END IF;
        
        -- Se asigna a la variable de bono_ganancias la cantidad correspondiente
        IF v_num_aten > 5 THEN
            v_bono_gana := (vr_porcentajes(1)*3/100)/v_num_at_sobre_cinco;
        ELSE v_bono_gana := 0;
        END IF;
        
        -- Calculo total bonificaciones (ganancias + atenciones)
        r_infomsii.bonif_especial := v_bono_gana + v_bono_aten;  
        
        -- Calculo renta imponible anual
        r_infomsii.renta_imponible_anual := r_infomsii.sueldo_base_anual + r_infomsii.bonif_especial;

        -- Calculo sueldo bruto anual
        r_infomsii.sueldo_bruto_anual := 
            r_infomsii.sueldo_base_anual + 
            r_infomsii.bonif_especial + 
            r_infomsii.meses_trabajados *
                (ROUND(r_infomsii.sueldo_base_mensual*vr_porcentajes(2)/100) + 
                ROUND(r_infomsii.sueldo_base_mensual*vr_porcentajes(3)/100));
        
        -- Insercion en tabla de destino
        INSERT INTO info_medico_sii 
            VALUES (r_infomsii.anno_tributario,
                r_infomsii.numrun||v_rn_enc,
                TO_CHAR(v_dv_enc, 'FM099')||r_infomsii.dv_run,
                r_infomsii.nombre_completo,
                r_infomsii.cargo,
                r_infomsii.meses_trabajados,
                r_infomsii.sueldo_base_mensual||v_sb_enc,
                r_infomsii.sueldo_base_anual,
                r_infomsii.bonif_especial,
                r_infomsii.sueldo_bruto_anual,
                r_infomsii.renta_imponible_anual);
        
        -- Al final de cada iteracion cambian los valores para encriptar run dvrun y sueldo
        v_rn_enc := v_rn_enc +1;
        v_dv_enc := v_dv_enc +3;
        v_sb_enc := v_sb_enc -10;
    
    END LOOP;

END;