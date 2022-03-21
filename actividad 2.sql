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
    
END;
    

-- CASO 2

/*
12648200
11649964
12456905
12260812
12642309
*/

DECLARE

v_run empleado.numrun_emp%TYPE := &RUN;

v_mes_anno VARCHAR2(6);
v_numrun_emp NUMBER(8);
v_dvrun_emp CHAR;
v_nombre_empleado VARCHAR2(40);
v_nombre_usuario VARCHAR2(10); 
v_clave_usuario VARCHAR2(20);

BEGIN

SELECT TO_CHAR(SYSDATE, 'MMYYYY') MES_ANNO,
    numrun_emp NUMRUN_EMP,
    dvrun_emp DVRUN_EMP,
    pnombre_emp||' '||snombre_emp||' '||appaterno_emp||' '||apmaterno_emp NOMBRE_EMPLEADO,
    SUBSTR(pnombre_emp, 0, 3)||LENGTH(pnombre_emp)||'*'||SUBSTR(TO_CHAR(sueldo_base, '9999999'), -1, 1)||dvrun_emp||ROUND(MONTHS_BETWEEN(SYSDATE, fecha_contrato)/12)||
    CASE WHEN ROUND(MONTHS_BETWEEN(SYSDATE, fecha_contrato)/12) < 10 THEN 'X'
        ELSE NULL
    END NOMBRE_USUARIO,
    SUBSTR(TO_CHAR(numrun_emp, '99999999'), 4, 1)||(EXTRACT (YEAR FROM fecha_nac))+2||SUBSTR(TO_CHAR(sueldo_base-1, '9999999'), -3, 3)||
    LOWER(CASE id_estado_civil 
        WHEN 10 THEN SUBSTR(appaterno_emp, 0, 2)
        WHEN 60 THEN SUBSTR(appaterno_emp, 0, 2)
        WHEN 20 THEN SUBSTR(appaterno_emp, 0, 1)||SUBSTR(appaterno_emp, -1, 1)
        WHEN 30 THEN SUBSTR(appaterno_emp, 0, 1)||SUBSTR(appaterno_emp, -1, 1)
        WHEN 40 THEN SUBSTR(appaterno_emp, -3, 2)
        WHEN 50 THEN SUBSTR(appaterno_emp, -2, 2)
    END)||
    TO_CHAR(SYSDATE, 'MMYYYY')||SUBSTR(nombre_comuna, 0, 1) CLAVE_USUARIO
        INTO v_mes_anno, v_numrun_emp, v_dvrun_emp, v_nombre_empleado, v_nombre_usuario, v_clave_usuario
    FROM empleado NATURAL JOIN comuna
    WHERE numrun_emp = v_run;

INSERT INTO usuario_clave 
VALUES (v_mes_anno, v_numrun_emp, v_dvrun_emp, v_nombre_empleado, v_nombre_usuario, v_clave_usuario);
COMMIT;
    
END;