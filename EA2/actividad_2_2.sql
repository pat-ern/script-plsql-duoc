-- CASO 1

SET SERVEROUTPUT ON

DECLARE

    -- declaracion tipo varray
    TYPE tp_varray_multas IS VARRAY(7) 
        OF NUMBER(4);
    
    -- inicializacion y poblado de varray
    v_multas tp_varray_multas := tp_varray_multas(1200, 1300, 1700, 1900, 1100, 2000, 2300); 

    -- declaracion registro con arquitectura de tabla pago_moroso
    r_pagos_morosos pago_moroso%ROWTYPE; 
    
    -- declaracion de cursor explicito con query de atenciones con pagos morosos 
    -- no usar parentesis si se usa order by
    CURSOR c_pagos_morosos IS 
        SELECT p.pac_run pac_run, 
            p.dv_run pac_dv_run, 
            p.pnombre||' '||p.snombre||' '||p.apaterno||' '||p.amaterno pac_nombre,
            a.ate_id ate_id,
            pa.fecha_venc_pago fecha_venc_pago,
            pa.fecha_pago fecha_pago,
            pa.fecha_pago-pa.fecha_venc_pago dias_morosidad,
            e.nombre especialidad_atencion,
            0 monto_multa
        FROM paciente p
        JOIN atencion a ON a.pac_run = p.pac_run
        JOIN pago_atencion pa ON pa.ate_id = a.ate_id
        JOIN especialidad e ON e.esp_id = a.esp_id
        WHERE pa.fecha_pago-pa.fecha_venc_pago > 0
        AND EXTRACT(YEAR FROM pa.fecha_venc_pago)=EXTRACT(YEAR FROM SYSDATE)-1
        ORDER BY pa.fecha_venc_pago,
            p.apaterno;
        
    v_edad NUMBER(3);
    v_porc porc_descto_3ra_edad.porcentaje_descto%TYPE := 0;

BEGIN

    -- trunca tabla en ejecucion
    EXECUTE IMMEDIATE 'TRUNCATE TABLE pago_moroso'; 

    OPEN c_pagos_morosos;
    
    LOOP
    
        -- se llena el registro con el fetch de cursor
        FETCH c_pagos_morosos INTO r_pagos_morosos; 
        
        -- sale del loop si se termina el cursor
        EXIT WHEN c_pagos_morosos%NOTFOUND; 

        -- poblado de variable monto_multa en registro segun resultado de control de condiciones
        r_pagos_morosos.monto_multa := 
        CASE r_pagos_morosos.especialidad_atencion
            WHEN 'Cirugía General' THEN v_multas(1) * r_pagos_morosos.dias_morosidad
            WHEN 'Dermatología' THEN v_multas(1) * r_pagos_morosos.dias_morosidad
            WHEN 'Ortopedia y Traumatología' THEN v_multas(2) * r_pagos_morosos.dias_morosidad
            WHEN 'Inmunología' THEN v_multas(3) * r_pagos_morosos.dias_morosidad
            WHEN 'Otorrinolaringología' THEN v_multas(3) * r_pagos_morosos.dias_morosidad
            WHEN 'Fisiatría'  THEN v_multas(4) * r_pagos_morosos.dias_morosidad
            WHEN 'Medicina Interna' THEN v_multas(4) * r_pagos_morosos.dias_morosidad
            WHEN 'Medicina General' THEN v_multas(5) * r_pagos_morosos.dias_morosidad
            WHEN 'Psiquiatría Adultos' THEN v_multas(6) * r_pagos_morosos.dias_morosidad
            WHEN 'Cirugía Digestiva' THEN v_multas(7) * r_pagos_morosos.dias_morosidad
            WHEN 'Reumatología' THEN v_multas(7) * r_pagos_morosos.dias_morosidad
        END;
        
        -- asignacion en variable edad
        SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12) 
            INTO v_edad
            FROM paciente
            WHERE pac_run = r_pagos_morosos.pac_run;
        
        -- si paciente moroso es de la tercera edad recibe descuentos segun tabla
        -- si no se ejecuta el sentencia/into v_porc sigue siendo 0
        IF v_edad >= 65 THEN 
            SELECT porcentaje_descto 
                INTO v_porc
                FROM porc_descto_3ra_edad
                WHERE v_edad BETWEEN anno_ini AND anno_ter;
        END IF;
            
        -- aplicacion de descuentos
        r_pagos_morosos.monto_multa := r_pagos_morosos.monto_multa - r_pagos_morosos.monto_multa*v_porc/100; 
        
        -- insert utilizando registro
        INSERT INTO pago_moroso VALUES r_pagos_morosos; 
        
    END LOOP;
    
    CLOSE c_pagos_morosos;

END;

-- CASO 2

-- se elimina tabla para resetear ultimo valor de secuencia
DROP TABLE MEDICO_SERVICIO_COMUNIDAD CASCADE CONSTRAINTS; 

CREATE TABLE MEDICO_SERVICIO_COMUNIDAD
(id_med_scomun NUMBER(2) GENERATED ALWAYS AS IDENTITY MINVALUE 1 
MAXVALUE 9999999999999999999999999999
INCREMENT BY 1 START WITH 1
CONSTRAINT PK_MED_SERV_COMUNIDAD PRIMARY KEY,
 unidad VARCHAR2(50) NOT NULL,
 run_medico VARCHAR2(15) NOT NULL,
 nombre_medico VARCHAR2(50) NOT NULL,
 correo_institucional VARCHAR2(25) NOT NULL,
 total_aten_medicas NUMBER(2) NOT NULL,
 destinacion VARCHAR2(50) NOT NULL);

DECLARE

    -- cursor explicito con datos de medicos y cantidad de atenciones en año anterior
    CURSOR c_medicos IS 
    SELECT 0 id_med_scomun,
        u.nombre unidad,
        TO_CHAR(m.med_run,'09G999G999')||'-'||m.dv_run run_medico, 
        pnombre||' '||m.snombre||' '||m.apaterno||' '||m.amaterno nombre_medico,
        SUBSTR(u.nombre, 0, 2)||SUBSTR(m.apaterno, -3, 2)||'@medicocktk.cl' correo_institucional,
        COUNT(ate_id) total_aten_medicas,
        '' destinacion
    FROM medico m
    JOIN unidad u ON u.uni_id = m.uni_id
    LEFT JOIN atencion a ON m.med_run = a.med_run
    AND EXTRACT(YEAR FROM a.fecha_atencion) = EXTRACT(YEAR FROM SYSDATE)-1
    GROUP BY u.nombre,
        TO_CHAR(m.med_run,'09G999G999')||'-'||m.dv_run, 
        m.pnombre||' '||m.snombre||' '||m.apaterno||' '||m.amaterno,
        SUBSTR(u.nombre, 0, 2)||SUBSTR(m.apaterno, -3, 2)||'@medicocktk.cl',
        m.apaterno, ''
    ORDER BY u.nombre,
        m.apaterno;
        
    -- variable para determinar posteriormente el numero maximo de atenciones
    v_max_atenciones NUMBER(2) := -1;
    
    -- registro con identica arquitectura a tabla a modificar
    r_atenciones medico_servicio_comunidad%ROWTYPE;
    
    -- declaracion de tipo de array para utiliar posteriormente
    TYPE vt_tipo_destinaciones IS VARRAY(3) OF
        VARCHAR(50);
    
    -- declaracion e inicializaicon de array con destinaciones
    v_destinaciones vt_tipo_destinaciones := vt_tipo_destinaciones(
        'Servicio de Atención Primaria de Urgencia (SAPU)',
        'Hospitales del área de la Salud Pública',
        'Centros de Salud Familiar (CESFAM)');

BEGIN
    
    -- ciclo para determinar maximo de atenciones en cursor c_medicos
    FOR reg_aten IN c_medicos LOOP
        IF reg_aten.total_aten_medicas > v_max_atenciones THEN
            v_max_atenciones := reg_aten.total_aten_medicas;
        END IF;
    END LOOP;

    OPEN c_medicos;
    
    LOOP
    
        -- se introducen datos (los que estan ya listos) de cursor en fila actual del registro
        FETCH c_medicos INTO r_atenciones;
        
        EXIT WHEN c_medicos%NOTFOUND;
        
        -- control de condiciones para determinar destinacion
        IF r_atenciones.unidad = 'ATENCIÓN AMBULATORIA' OR r_atenciones.unidad = 'ATENCIÓN ADULTO' THEN
            r_atenciones.destinacion := v_destinaciones(1);
        ELSIF r_atenciones.unidad = 'ATENCIÓN URGENCIA' THEN
            IF r_atenciones.total_aten_medicas BETWEEN 0 AND 3 THEN
                r_atenciones.destinacion := v_destinaciones(1);
            ELSIF r_atenciones.total_aten_medicas > 3 THEN
                r_atenciones.destinacion := v_destinaciones(2);
            END IF;
        ELSIF r_atenciones.unidad = 'CARDIOLOGÍA' OR r_atenciones.unidad = 'ONCOLÓGICA' THEN
            r_atenciones.destinacion := v_destinaciones(2);
        ELSIF r_atenciones.unidad = 'CIRUGÍA' OR r_atenciones.unidad = 'CIRUGÍA PLÁSTICA' THEN
            IF r_atenciones.total_aten_medicas BETWEEN 0 AND 3 THEN
                r_atenciones.destinacion := v_destinaciones(1);
            ELSIF r_atenciones.total_aten_medicas > 3 THEN
                r_atenciones.destinacion := v_destinaciones(2);
            END IF;
        ELSIF r_atenciones.unidad = 'PACIENTE CRÍTICO' THEN
            r_atenciones.destinacion := v_destinaciones(2);
        ELSIF r_atenciones.unidad = 'PSIQUIATRÍA Y SALUD MENTAL' THEN
            r_atenciones.destinacion := v_destinaciones(3);
        ELSIF r_atenciones.unidad = 'TRAUMATOLOGÍA ADULTO' THEN
            IF r_atenciones.total_aten_medicas BETWEEN 0 AND 3 THEN
                r_atenciones.destinacion := v_destinaciones(1);
            ELSIF r_atenciones.total_aten_medicas > 3 THEN
                r_atenciones.destinacion := v_destinaciones(2);
            END IF;
        END IF;

        -- insercion en tabla (el valor de la PK no es introducido ya que se genera de forma automatica)
        INSERT INTO medico_servicio_comunidad (
                unidad,
                run_medico,
                nombre_medico,
                correo_institucional,
                total_aten_medicas,
                destinacion)
            VALUES (
                r_atenciones.unidad,
                r_atenciones.run_medico,
                r_atenciones.nombre_medico,
                r_atenciones.correo_institucional,
                r_atenciones.total_aten_medicas,
                r_atenciones.destinacion);
    
    END LOOP;
    
    CLOSE c_medicos;

END;

-- CASO 3

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