-- CASO 1

SET SERVEROUTPUT ON

VAR v_run NUMBER
EXEC :v_run := 11846972

DECLARE
    v_numrun_emp empleado.numrun_emp%TYPE; 
    v_dvrun_emp empleado.dvrun_emp%TYPE; 
    v_pnombre_emp empleado.pnombre_emp%TYPE; 
    v_snombre_emp empleado.snombre_emp%TYPE;
    v_appaterno_emp empleado.appaterno_emp%TYPE;
    v_apmaterno_emp empleado.apmaterno_emp%TYPE;
    v_sueldo_base empleado.sueldo_base%TYPE;
    v_nombre_comuna comuna.nombre_comuna%TYPE;

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
    
    DBMS_OUTPUT.PUT_LINE('v_numrun_emp'||v_numrun_emp);
    DBMS_OUTPUT.PUT_LINE('v_pnombre_emp'||v_pnombre_emp);
    DBMS_OUTPUT.PUT_LINE('v_appaterno_emp'||v_appaterno_emp);
    DBMS_OUTPUT.PUT_LINE('v_nombre_comuna'||v_nombre_comuna);
END;
    
