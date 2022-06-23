-- FUNCION fn_edad_pac

create or replace FUNCTION fn_edad_pac(p_pac_run IN NUMBER) RETURN NUMBER IS

    v_edad NUMBER(3);

BEGIN

    SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12)
        INTO v_edad
        FROM paciente
        WHERE pac_run = p_pac_run;

    RETURN v_edad;

END fn_edad_pac;

-- FUNCION fn_especialidad

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

-- PACKAGE pkg_multa

-- PACKAGE HEAD

create or replace PACKAGE pkg_multa IS
    v_valor_multa NUMBER(5);
    v_valor_descuento NUMBER(5);
    FUNCTION fn_dcto_edad(p_pac_run IN NUMBER) RETURN NUMBER;
END pkg_multa;

-- PACKAGE BODY

create or replace PACKAGE BODY pkg_multa IS

    FUNCTION fn_dcto_edad(p_pac_run IN NUMBER) RETURN NUMBER IS

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

END pkg_multa;

-- PROCEDURE SP_PAGOS_MOROSOS_ANNO_ANT

create or replace PROCEDURE SP_PAGOS_MOROSOS_ANNO_ANT IS

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

    TYPE t_tipo_varray IS VARRAY(7) OF
        NUMBER(4);
    va_val_multas t_tipo_varray := t_tipo_varray(1200, 1300, 1700, 1900, 1100, 2000, 2300);

    v_observacion VARCHAR2(200);

BEGIN

    FOR i IN c_atenciones LOOP

        IF fn_especialidad(i.med_run) = 'Medicina General'
            THEN pkg_multa.v_valor_multa := i.dias_morosidad * va_val_multas(1);
        ELSIF fn_especialidad(i.med_run) = 'Traumatologia'
            THEN pkg_multa.v_valor_multa := i.dias_morosidad * va_val_multas(2);
        ELSIF fn_especialidad(i.med_run) = 'Neurologia' OR fn_especialidad(i.med_run) = 'Pediatria'
            THEN pkg_multa.v_valor_multa := i.dias_morosidad * va_val_multas(3);
        ELSIF fn_especialidad(i.med_run) = 'Oftalmologia'
            THEN pkg_multa.v_valor_multa := i.dias_morosidad * va_val_multas(4);
        ELSIF fn_especialidad(i.med_run) = 'Geriatria'
            THEN pkg_multa.v_valor_multa := i.dias_morosidad * va_val_multas(5);
        ELSIF fn_especialidad(i.med_run) = 'Ginecologia' OR fn_especialidad(i.med_run) = 'Gastroenterologia'
            THEN pkg_multa.v_valor_multa := i.dias_morosidad * va_val_multas(6);
        ELSIF fn_especialidad(i.med_run) = 'Dermatologia'
            THEN pkg_multa.v_valor_multa := i.dias_morosidad * va_val_multas(7);
        END IF;

        v_observacion := NULL;

        IF fn_edad_pac(i.pac_run) >= 70 THEN
            pkg_multa.v_valor_descuento := ROUND(pkg_multa.v_valor_multa * pkg_multa.fn_dcto_edad(i.pac_run)/100);
            pkg_multa.v_valor_multa := pkg_multa.v_valor_multa - pkg_multa.v_valor_descuento;
            v_observacion := 'OBSERVACION: Paciente tenia '||fn_edad_pac(i.pac_run)||' a la fecha de la atencion. Se aplico descuento paciente mayor a 70 años';
        END IF;

        INSERT INTO pago_moroso
            VALUES (i.pac_run, 
                i.dv_run, 
                i.pac_nombre, 
                i.ate_id, 
                i.fecha_venc_pago, 
                i.fecha_pago, 
                i.dias_morosidad, 
                fn_especialidad(i.med_run), 
                i.costo_atencion, 
                pkg_multa.v_valor_multa, 
                v_observacion);

    END LOOP;

END;

-- EJECUCION

TRUNCATE TABLE pago_moroso;
EXEC SP_PAGOS_MOROSOS_ANNO_ANT;