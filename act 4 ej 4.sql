SET SERVEROUTPUT ON

TRUNCATE TABLE bonif_por_utilidad;

VAR b_monto_utilidades NUMBER
EXEC :b_monto_utilidades := 200000000

VAR b_porc_util_total NUMBER
EXEC :b_porc_util_total := 30/100

VAR b_porc_util_a NUMBER
EXEC :b_porc_util_a := 35/100

VAR b_porc_util_b NUMBER
EXEC :b_porc_util_b := 25/100

VAR b_porc_util_c NUMBER
EXEC :b_porc_util_c := 20/100

VAR b_porc_util_d NUMBER
EXEC :b_porc_util_d := 15/100

VAR b_porc_util_e NUMBER
EXEC :b_porc_util_e := 5/100

DECLARE

    v_anno_proceso          bonif_por_utilidad.anno_proceso%TYPE := 2022; 
    v_id_emp                bonif_por_utilidad.id_emp%TYPE;
    v_sueldo_base           bonif_por_utilidad.sueldo_base%TYPE;
    v_valor_bonif_utilidad  bonif_por_utilidad.valor_bonif_utilidad%TYPE;
    
    v_count_emp             NUMBER(4);
    v_min_id_emp            bonif_por_utilidad.id_emp%TYPE;
    
    v_cant_emps_a           NUMBER(2);
    v_cant_emps_b           NUMBER(2);
    v_cant_emps_c           NUMBER(2);
    v_cant_emps_d           NUMBER(2);
    v_cant_emps_e           NUMBER(2);

BEGIN

    SELECT COUNT(id_emp), MIN(id_emp)
        INTO v_count_emp, v_min_id_emp
        FROM empleado;
        
    SELECT COUNT(id_emp)
        INTO v_cant_emps_a
        FROM empleado
        WHERE sueldo_base BETWEEN 320000 AND 600000;

    SELECT COUNT(id_emp)
        INTO v_cant_emps_b
        FROM empleado
        WHERE sueldo_base BETWEEN 600001 AND 1300000;

    SELECT COUNT(id_emp)
        INTO v_cant_emps_c
        FROM empleado
        WHERE sueldo_base BETWEEN 1300001 AND 1800000;

    SELECT COUNT(id_emp)
        INTO v_cant_emps_d
        FROM empleado
        WHERE sueldo_base BETWEEN 1800001 AND 2200000;

    SELECT COUNT(id_emp)
        INTO v_cant_emps_e
        FROM empleado
        WHERE sueldo_base >= 2200001;

    FOR i IN 1 .. v_count_emp LOOP
    
        SELECT id_emp,
            sueldo_base
            INTO v_id_emp,
                v_sueldo_base
            FROM empleado
            WHERE id_emp = v_min_id_emp;
            
        -- calculo de monto
        
        IF v_sueldo_base BETWEEN 320000 AND 600000 THEN
            v_valor_bonif_utilidad := (:b_monto_utilidades*:b_porc_util_total*:b_porc_util_a)/v_cant_emps_a;
        ELSIF v_sueldo_base BETWEEN 600001 AND 1300000 THEN
            v_valor_bonif_utilidad := (:b_monto_utilidades*:b_porc_util_total*:b_porc_util_b)/v_cant_emps_b;
        ELSIF v_sueldo_base BETWEEN 1300001 AND 1800000 THEN
            v_valor_bonif_utilidad := (:b_monto_utilidades*:b_porc_util_total*:b_porc_util_c)/v_cant_emps_c;
        ELSIF v_sueldo_base BETWEEN 1800001 AND 2200000 THEN
            v_valor_bonif_utilidad := (:b_monto_utilidades*:b_porc_util_total*:b_porc_util_d)/v_cant_emps_d;
        ELSIF v_sueldo_base >= 2200001 THEN
            v_valor_bonif_utilidad := (:b_monto_utilidades*:b_porc_util_total*:b_porc_util_e)/v_cant_emps_e;
        END IF;

        INSERT  INTO bonif_por_utilidad
        VALUES (v_anno_proceso, --ingreso parametrico
                v_id_emp, --sentencia select
                v_sueldo_base, --sentencia select
                ROUND(v_valor_bonif_utilidad)); --calculado 
                
        v_min_id_emp := v_min_id_emp + 10;
            
    END LOOP;

END;