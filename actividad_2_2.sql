SET SERVEROUTPUT ON

DECLARE

    TYPE tp_varray_multas IS VARRAY(7) 
        OF NUMBER(4);
    
    v_multas tp_varray_multas := tp_varray_multas(1200, 1300, 1700, 1900, 1100, 2000, 2300);
    
    r_pago_moroso pago_moroso%ROWTYPE;
    
    CURSOR c_ate_pago_m IS (
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

BEGIN

    FOR i IN c_ate_pago_m LOOP
 
        r_pago_moroso.monto_multa :=
        CASE i.especialidad_atencion
            WHEN 'Cirugía General' THEN v_multas(1) * i.dias_morosidad
            WHEN 'Dermatología' THEN v_multas(1) * i.dias_morosidad
            WHEN 'Ortopedia y Traumatología' THEN v_multas(2) * i.dias_morosidad
            WHEN 'Inmunología' THEN v_multas(3) * i.dias_morosidad
            WHEN 'Otorrinolaringología' THEN v_multas(3) * i.dias_morosidad
            WHEN 'Fisiatría'  THEN v_multas(4) * i.dias_morosidad
            WHEN 'Medicina Interna' THEN v_multas(4) * i.dias_morosidad
            WHEN 'Medicina General' THEN v_multas(5) * i.dias_morosidad
            WHEN 'Psiquiatría Adultos' THEN v_multas(6) * i.dias_morosidad
            WHEN 'Cirugía Digestiva' THEN v_multas(7) * i.dias_morosidad
            WHEN 'Reumatología' THEN v_multas(7) * i.dias_morosidad
        END;
        
        DBMS_OUTPUT.PUT_LINE(r_pago_moroso.monto_multa);
    
    END LOOP;

END;