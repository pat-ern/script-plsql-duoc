SET SERVEROUTPUT ON

DECLARE

    TYPE tp_varray_multas IS VARRAY(7) 
        OF NUMBER(4);
    
    v_multas tp_varray_multas := tp_varray_multas(1200, 1300, 1700, 1900, 1100, 2000, 2300);
    
    r_pagos_morosos pago_moroso%ROWTYPE;
    
    CURSOR c_pagos_morosos IS (
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
        --ORDER BY pa.fecha_venc_pago,
            --p.apaterno
        );
        
    v_edad NUMBER(3);
    v_porc porc_descto_3ra_edad.porcentaje_descto%TYPE := 0;

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE pago_moroso';

    OPEN c_pagos_morosos;
    
    LOOP
    
        FETCH c_pagos_morosos INTO r_pagos_morosos;
        
        EXIT WHEN c_pagos_morosos%NOTFOUND;

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
        
        SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12)
            INTO v_edad
            FROM paciente
            WHERE pac_run = r_pagos_morosos.pac_run;
        
        IF v_edad >= 65 THEN
            SELECT porcentaje_descto 
                INTO v_porc
                FROM porc_descto_3ra_edad
                WHERE v_edad BETWEEN anno_ini AND anno_ter;
        END IF;
            
        r_pagos_morosos.monto_multa := r_pagos_morosos.monto_multa - r_pagos_morosos.monto_multa*v_porc/100;
        
        INSERT INTO pago_moroso VALUES r_pagos_morosos;
        
    END LOOP;
    
    CLOSE c_pagos_morosos;

END;