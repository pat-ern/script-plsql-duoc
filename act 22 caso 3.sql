SET SERVEROUTPUT ON

DECLARE

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
    
    r_infomsii info_medico_sii%ROWTYPE;
    
    v_rn_enc NUMBER(4) := 100;
    v_dv_enc NUMBER(4) := 10;
    v_sb_enc NUMBER(4) := 900;
    
    v_meses_trab NUMBER(4);
    v_num_aten NUMBER (2);
    v_porc tramo_asig_atmed.porc_asig%TYPE;

BEGIN

    FOR i IN c_medicos LOOP
    
        -- Asignacion directa de valores provenientes del cursor/tablas
        r_infomsii.anno_tributario := i.anno_tributario;
        r_infomsii.numrun := i.numrun;
        r_infomsii.dv_run := i.dv_run;
        r_infomsii.nombre_completo := i.nombre_completo;
        r_infomsii.cargo := i.cargo;
        r_infomsii.sueldo_base_mensual := i.sueldo_base_mensual;
        
        SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_contrato))-EXTRACT(MONTH FROM SYSDATE)+1
            INTO v_meses_trab
            FROM medico
            WHERE med_run = i.numrun;
            
        IF v_meses_trab > 12 THEN
            r_infomsii.meses_trabajados := 12;
        ELSE 
            r_infomsii.meses_trabajados := v_meses_trab;
        END IF;
        
        r_infomsii.sueldo_base_anual := r_infomsii.sueldo_base_mensual*12;
        
        -- BONIF POR ATENCIONES DURANTE EL AÑO
        
        SELECT NVL(COUNT(a.ate_id), 0)
            INTO v_num_aten
            FROM medico m
            LEFT JOIN atencion a ON a.med_run = m.med_run
            WHERE m.med_run = i.numrun
            AND EXTRACT(YEAR FROM a.fecha_atencion) = EXTRACT(YEAR FROM SYSDATE)-1;
            
        SELECT porc_asig
            INTO v_porc
            FROM tramo_asig_atmed
            WHERE v_num_aten BETWEEN tramo_inf_atm AND tramo_sup_atm;
            
        r_infomsii.bonif_especial := r_infomsii.sueldo_base_mensual*v_porc/100;
            
        DBMS_OUTPUT.PUT_LINE(r_infomsii.anno_tributario);
        DBMS_OUTPUT.PUT_LINE(r_infomsii.numrun||v_rn_enc);
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(v_dv_enc, 'FM099')||r_infomsii.dv_run);
        DBMS_OUTPUT.PUT_LINE(r_infomsii.nombre_completo);
        DBMS_OUTPUT.PUT_LINE(r_infomsii.cargo);
        DBMS_OUTPUT.PUT_LINE(r_infomsii.meses_trabajados);
        DBMS_OUTPUT.PUT_LINE(r_infomsii.sueldo_base_mensual||v_sb_enc);
        DBMS_OUTPUT.PUT_LINE(r_infomsii.sueldo_base_anual);
        -- BONIF ESPECIAL
        -- SUELDO BRUTO ANUAL
        -- RENTA IMPONIBLE ANUAL
        DBMS_OUTPUT.PUT_LINE(r_infomsii.bonif_especial);
        DBMS_OUTPUT.PUT_LINE('-----------------------------');
        
        v_rn_enc := v_rn_enc +1;
        v_dv_enc := v_dv_enc +3;
        v_sb_enc := v_sb_enc -10;
    
    END LOOP;

END;