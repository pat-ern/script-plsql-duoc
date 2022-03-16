-- CASO 1

SET SERVEROUTPUT ON

VAR v_run NUMBER
EXEC :v_run := 11846972

DECLARE
    v_numrun_emp        empleado.numrun_emp%TYPE; 
    v_dvrun_emp         empleado.dvrun_emp%TYPE; 
    v_pnombre_emp       empleado.pnombre_emp%TYPE; 
    v_snombre_emp       empleado.snombre_emp%TYPE;
    v_appaterno_emp     empleado.appaterno_emp%TYPE;
    v_apmaterno_emp     empleado.apmaterno_emp%TYPE;
    v_sueldo_base       empleado.sueldo_base%TYPE;
    v_nombre_comuna     comuna.nombre_comuna%TYPE;
    v_porc_movil_normal  proy_movilizacion.porc_movil_normal%TYPE;
    v_valor_movil_normal proy_movilizacion.valor_movil_normal%TYPE;
    v_valor_movil_extra  proy_movilizacion.valor_movil_extra%TYPE;
    v_valor_total_movil  proy_movilizacion.valor_total_movil%TYPE;

BEGIN
    SELECT numrun_emp, 
        dvrun_emp, 
        pnombre_emp, 
        snombre_emp,
        appaterno_emp,
        apmaterno_emp,
        sueldo_base,
        nombre_comuna
        INTO v_numrun_emp, 
            v_dvrun_emp, 
            v_pnombre_emp, 
            v_snombre_emp,
            v_appaterno_emp,
            v_apmaterno_emp,
            v_sueldo_base,
            v_nombre_comuna
            
        FROM empleado NATURAL JOIN comuna
        WHERE numrun_emp = :v_run;
    
    v_porc_movil_normal := TRUNC(v_sueldo_base/100000);
    v_valor_movil_normal := v_sueldo_base * v_porc_movil_normal/100;
    
    IF v_nombre_comuna = 'María Pinto' THEN
        v_valor_movil_extra := 20000;
    END IF;
    
    IF v_nombre_comuna = 'Curacaví' THEN
        v_valor_movil_extra := 25000;
    END IF;
    
    IF v_nombre_comuna = 'Talagante' THEN
        v_valor_movil_extra := 30000;
    END IF;
    
    IF v_nombre_comuna = 'El Monte' THEN
        v_valor_movil_extra := 35000;
    END IF;
    
    IF v_nombre_comuna = 'Buin' THEN
        v_valor_movil_extra := 40000;
    END IF;
    
    v_valor_total_movil := v_valor_movil_normal + v_valor_movil_extra;
    
    INSERT INTO proy_movilizacion
    VALUES (EXTRACT (YEAR FROM SYSDATE), v_numrun_emp, v_dvrun_emp, v_pnombre_emp||' '||v_snombre_emp||' '||v_appaterno_emp||' '||v_apmaterno_emp, v_sueldo_base, v_porc_movil_normal, v_valor_movil_normal, v_valor_movil_extra, v_valor_total_movil);
    COMMIT;
    
    /*
    DBMS_OUTPUT.PUT_LINE('v_numrun_emp '||v_numrun_emp);
    DBMS_OUTPUT.PUT_LINE('v_pnombre_emp '||v_pnombre_emp);
    DBMS_OUTPUT.PUT_LINE('v_appaterno_emp '||v_appaterno_emp);
    DBMS_OUTPUT.PUT_LINE('v_nombre_comuna '||v_nombre_comuna);
    DBMS_OUTPUT.PUT_LINE('v_porc_movil_normal '||v_porc_movil_normal);
    DBMS_OUTPUT.PUT_LINE('v_valor_movil_normal '||v_valor_movil_normal);
    DBMS_OUTPUT.PUT_LINE('v_valor_movil_extra '||v_valor_movil_extra);
    DBMS_OUTPUT.PUT_LINE('v_valor_total_movil '||v_valor_total_movil);
    */
    
END;
    
