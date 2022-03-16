-- CASO 1

VAR b_porcentaje NUMBER
EXEC :b_porcentaje := &porcentaje

DECLARE
    v_nombre_ap VARCHAR2(40);
    v_rut_emp VARCHAR2(12);
    v_sueldo_emp empleado.sueldo_emp%TYPE;
    
BEGIN
    SELECT nombre_emp||' '||appaterno_emp||' '||apmaterno_emp,
            numrut_emp||'-'||dvrut_emp,
            sueldo_emp
        INTO v_nombre_ap, v_rut_emp, v_sueldo_emp
    FROM empleado
    WHERE numrut_emp = &input_rut;
    DBMS_OUTPUT.PUT_LINE('DATOS CALCULO BONIFICACION EXTRA DEL '||:b_porcentaje||'% DEL SUELDO');
    DBMS_OUTPUT.PUT_LINE('Nombre Empleado: '||v_nombre_ap);
    DBMS_OUTPUT.PUT_LINE('RUN: '||v_rut_emp);
    DBMS_OUTPUT.PUT_LINE('Sueldo: '||v_sueldo_emp);
    DBMS_OUTPUT.PUT_LINE('Bonificacion extra: '||v_sueldo_emp*:b_porcentaje/100);
    
END;

-- CASO 2

VAR b_run_cliente NUMBER
EXEC :b_run_cliente:=&RUN;

DECLARE
    v_nom_cli VARCHAR2(40);
    v_rut_cli VARCHAR2(12);
    v_est_civil estado_civil.desc_estcivil%TYPE;
    v_renta_cli VARCHAR2(20);
    v_min_renta NUMBER(10):=&RENTA_MINIMA; -- duda
    
BEGIN
    SELECT cli.nombre_cli||' '||cli.appaterno_cli||' '||cli.apmaterno_cli,
            cli.numrut_cli||'-'||cli.dvrut_cli,
            est.desc_estcivil,
            TO_CHAR(cli.renta_cli, 'FML99G999G999')
        INTO v_nom_cli, v_rut_cli, v_est_civil, v_renta_cli
    FROM cliente cli JOIN estado_civil est
    ON cli.id_estcivil = est.id_estcivil
    WHERE numrut_cli = :b_run_cliente;
    DBMS_OUTPUT.PUT_LINE('DATOS DEL CLIENTE');
    DBMS_OUTPUT.PUT_LINE('-----------------');
    DBMS_OUTPUT.PUT_LINE('Nombre: '||v_nom_cli);
    DBMS_OUTPUT.PUT_LINE('RUN: '||v_rut_cli);
    DBMS_OUTPUT.PUT_LINE('Estado civil: '||v_est_civil);
    DBMS_OUTPUT.PUT_LINE('Renta: '||v_renta_cli);
    
END;

-- CASO 3

VAR b_run_emp NUMBER
EXEC :b_run_emp := &RUN;

DECLARE
    v_nombre VARCHAR2(40);
    v_rut VARCHAR2(12);
    v_sueldo empleado.sueldo_emp%TYPE;
    
    v_porc_gral NUMBER  := &porc_aumento_general/100;
    v_porc_rango NUMBER := &porc_aumento_rango/100;
    
    v_sueldo_max NUMBER(10,3) := &sueldo_max;
    v_sueldo_min NUMBER(10,3) := &sueldo_min;
    
BEGIN
    SELECT nombre_emp||' '||appaterno_emp||' '||apmaterno_emp,
            numrut_emp||'-'||dvrut_emp,
            sueldo_emp
        INTO v_nombre, v_rut, v_sueldo
    FROM empleado
    WHERE numrut_emp = :b_run_emp;

    DBMS_OUTPUT.PUT_LINE('NOMBRE DEL EMPLEADO: '||v_nombre);
    DBMS_OUTPUT.PUT_LINE('RUN: '||v_rut);
    
    DBMS_OUTPUT.PUT_LINE('Simulacion 1: Aumentar en '||v_porc_gral*100||'% el salario de todos los empleados');
    DBMS_OUTPUT.PUT_LINE('Sueldo actual: '||v_sueldo);
    DBMS_OUTPUT.PUT_LINE('Sueldo reajustado: '||ROUND(v_sueldo*(1+v_porc_gral)));
    DBMS_OUTPUT.PUT_LINE('Ajuste: '||ROUND(v_sueldo * v_porc_gral));
    
    DBMS_OUTPUT.PUT_LINE('Simulacion 2: Aumentar en '||v_porc_rango*100||'% el salario de los empleados que poseen salarios entre '||TO_CHAR(v_sueldo_min, 'FML999G999')||' y '||TO_CHAR(v_sueldo_max, 'FML999G999'));
    DBMS_OUTPUT.PUT_LINE('Sueldo actual: '||v_sueldo);
    DBMS_OUTPUT.PUT_LINE('Sueldo reajustado: '||ROUND(v_sueldo*(1+v_porc_rango)));
    DBMS_OUTPUT.PUT_LINE('Ajuste: '||ROUND(v_sueldo*v_porc_rango));
    
END;

    
-- alternativa 

VAR b_run_emp NUMBER;
EXEC :b_run_emp := &RUN;

DECLARE
    v_nombre VARCHAR2(40);
    v_rut VARCHAR2(12);
    v_sueldo empleado.sueldo_emp%TYPE;
    
    v_porc_gral NUMBER  := &porc_aumento_general/100;
    v_porc_rango NUMBER := &porc_aumento_rango/100;
    
    v_sueldo_max NUMBER(10,3) := &sueldo_max;
    v_sueldo_min NUMBER(10,3) := &sueldo_min;
    
BEGIN
    SELECT nombre_emp||' '||appaterno_emp||' '||apmaterno_emp,
            numrut_emp||'-'||dvrut_emp,
            sueldo_emp
        INTO v_nombre, v_rut, v_sueldo
    FROM empleado
    WHERE numrut_emp = :b_run_emp;

    DBMS_OUTPUT.PUT_LINE('NOMBRE DEL EMPLEADO: '||v_nombre);
    DBMS_OUTPUT.PUT_LINE('RUN: '||v_rut);
    
    DBMS_OUTPUT.PUT_LINE('Simulacion 1: Aumentar en '||v_porc_gral*100||'% el salario de todos los empleados');
    DBMS_OUTPUT.PUT_LINE('Sueldo actual: '||v_sueldo);
    DBMS_OUTPUT.PUT_LINE('Sueldo reajustado: '||ROUND(v_sueldo*(1+v_porc_gral)));
    DBMS_OUTPUT.PUT_LINE('Ajuste: '||ROUND(v_sueldo * v_porc_gral));
    DBMS_OUTPUT.PUT_LINE('Simulacion 2: Aumentar en '||v_porc_rango*100||'% el salario de los empleados que poseen salarios entre '||
        TO_CHAR(v_sueldo_min, 'FML999G999')||' y '||TO_CHAR(v_sueldo_max, 'FML999G999'));
    
    IF v_sueldo BETWEEN v_sueldo_min AND v_sueldo_max THEN
        DBMS_OUTPUT.PUT_LINE('Sueldo actual: '||v_sueldo);
        DBMS_OUTPUT.PUT_LINE('Sueldo reajustado: '||ROUND(v_sueldo*(1+v_porc_rango)));
        DBMS_OUTPUT.PUT_LINE('Ajuste: '||ROUND(v_sueldo*v_porc_rango));
    ELSE 
        DBMS_OUTPUT.PUT_LINE('No corresponde un reajuste segun el rango de salario indicado para esta simulacion');
    END IF;
    
END;
    

-- CASO 4

DECLARE
    v_tipo_arr VARCHAR2(30); 
    v_total_prop NUMBER(2); 
    v_valor_total VARCHAR(20);
    v_id_prop tipo_propiedad.id_tipo_propiedad%TYPE := '&ID_PROPIEDAD';

BEGIN
    SELECT tp.desc_tipo_propiedad,
        COUNT(NRO_PROPIEDAD),
        TO_CHAR(SUM(valor_arriendo), 'FML9G999G999')
            INTO v_tipo_arr, v_total_prop, v_valor_total
        FROM propiedad pr JOIN tipo_propiedad tp
        ON pr.id_tipo_propiedad = tp.id_tipo_propiedad
        WHERE pr.id_tipo_propiedad = v_id_prop
        GROUP BY tp.desc_tipo_propiedad, tp.id_tipo_propiedad
        ORDER BY tp.id_tipo_propiedad;

    DBMS_OUTPUT.PUT_LINE('RESUMEN DE: '||v_tipo_arr);
    DBMS_OUTPUT.PUT_LINE('Total de Propiedades: '||v_total_prop);
    DBMS_OUTPUT.PUT_LINE('Valor Total Arriendo: '||v_valor_total);
    
END;  

/*
A   Casa sin Amoblar
B   Casa Amoblada
C   Departamento sin Amoblar
D   Departamento Amoblado
E   Local Comercial
F   Parcela sin Casa
G   Parcela con Casa
H   Sitio

*/