create or replace FUNCTION fn_edad_pac(p_pac_run IN NUMBER) RETURN NUMBER IS

    v_edad NUMBER(3);

BEGIN

    SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12)
        INTO v_edad
        FROM paciente
        WHERE pac_run = p_pac_run;

    RETURN v_edad;

END fn_edad_pac;

--

create or replace FUNCTION fn_dcto_edad(p_pac_run IN NUMBER) RETURN NUMBER IS

    v_descuento porc_descto_3ra_edad.porcentaje_descto%TYPE;

BEGIN

    SELECT porcentaje_descto
        INTO v_descuento
        FROM porc_descto_3ra_edad
        WHERE fn_edad_pac(p_pac_run) BETWEEN anno_ini AND anno_ter;

    RETURN v_descuento;
    
EXCEPTION 

    WHEN OTHERS THEN
        RETURN 0;

END fn_dcto_edad;

--

create or replace FUNCTION fn_especialidad(p_med_run IN NUMBER) RETURN VARCHAR IS

    v_especialidad VARCHAR(80);

BEGIN

    SELECT nombre
        INTO v_especialidad
        FROM especialidad esp
        JOIN medico med
        ON med.esp_id = esp.esp_id
        WHERE med_run = p_med_run;
        
    RETURN v_especialidad;
    
END fn_especialidad;

--

SET SERVEROUTPUT ON

DECLARE 

    CURSOR c_atenciones IS
        SELECT pac.pac_run,
            pac.dv_run,
            pac.pnombre||' '||pac.snombre||' '||pac.apaterno||' '||pac.amaterno pac_nombre,
            ate.ate_id,
            pag.fecha_venc_pago,
            pag.fecha_pago,
            pag.fecha_pago - pag.fecha_venc_pago dias_morosidad,
            pag.valor_a_pagar costo_atencion,
            ate.med_run
        FROM atencion ate
        JOIN pago_atencion pag
        ON pag.ate_id = ate.ate_id
        JOIN paciente pac 
        ON pac.pac_run = ate.pac_run
        WHERE TO_CHAR(fecha_venc_pago, 'YYYY') = TO_CHAR(SYSDATE, 'YYYY')-1 
        AND pag.fecha_pago - pag.fecha_venc_pago > 0
        ORDER BY pag.fecha_venc_pago;
        
BEGIN

    FOR i IN c_atenciones LOOP
    
        DBMS_OUTPUT.PUT_LINE('Especialidad '||fn_especialidad(i.med_run));
        
        IF fn_edad_pac(i.pac_run) >= 70 THEN
            DBMS_OUTPUT.PUT_LINE('Edad '||fn_edad_pac(i.pac_run)||' Descuento '||fn_dcto_edad(i.pac_run));
        END IF;
        
    END LOOP;

END;