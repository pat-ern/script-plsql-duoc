-- CASO 1

-- agregar requerimiento de ganar menos de 500 mil y no ser empleado x 

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

-- CASO 1 SOLUCION PROFE

SET SERVEROUTPUT ON

VAR v_porc_bonif NUMBER 
EXEC :v_porc_bonif := 40

DECLARE
       v_run_empleado     VARCHAR2(10);
       v_nombre_empleado  VARCHAR2(55);
       v_sueldo_emp       empleado.sueldo_emp%TYPE;
       v_bonif_empleado   NUMBER(10);
BEGIN
     DBMS_OUTPUT.PUT_LINE('DATOS CALCULOBONIFICACIÓN DEL ' || :v_porc_bonif || '% DEL SUELDO');
     SELECT numrut_emp || '-' || dvrut_emp,
            nombre_emp || ' ' || appaterno_emp || ' ' || apmaterno_emp,
            sueldo_emp
       INTO v_run_empleado,
            v_nombre_empleado,
            v_sueldo_emp
       FROM empleado
      WHERE numrut_emp = &RUN_EMPLEADO;
      
      v_bonif_empleado := v_sueldo_emp * (:v_porc_bonif / 100);
      
      DBMS_OUTPUT.PUT_LINE('Nombre Empleado: ' || v_nombre_empleado);
      DBMS_OUTPUT.PUT_LINE('RUN : ' || v_run_empleado);
      DBMS_OUTPUT.PUT_LINE('Sueldo: ' || v_sueldo_emp);
      DBMS_OUTPUT.PUT_LINE('Bonificación extra : ' || v_bonif_empleado);
     
END;

-- CASO 2

VAR b_run_cliente NUMBER
EXEC :b_run_cliente:=&RUN;

DECLARE
    v_nom_cli VARCHAR2(40);
    v_rut_cli VARCHAR2(12);
    v_est_civil estado_civil.desc_estcivil%TYPE;
    v_renta_cli VARCHAR2(20);
    v_min_renta NUMBER(10):=&RENTA_MINIMA; -- duda con problema de redaccion y ej de pruebas
    
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

-- CASO 2 VERSION PROFE

SET SERVEROUTPUT ON

VAR v_numrun_cli NUMBER 
EXEC :v_numrun_cli := 12487147

DECLARE
       v_run_cliente     VARCHAR2(10);
       v_nombre_cliente  VARCHAR2(55);
       v_renta_cli       cliente.renta_cli%TYPE;
       v_desc_estcivil   estado_civil.desc_estcivil%TYPE;
BEGIN
     DBMS_OUTPUT.PUT_LINE('DATOS DEL CLIENTE');
     DBMS_OUTPUT.PUT_LINE('-----------------');
     
     SELECT numrut_cli || '-' || dvrut_cli,
            nombre_cli || ' ' || appaterno_cli || ' ' || apmaterno_cli,
            renta_cli,
            desc_estcivil
       INTO v_run_cliente,
            v_nombre_cliente,
            v_renta_cli,
            v_desc_estcivil
       FROM cliente NATURAL JOIN estado_civil
      WHERE numrut_cli = :v_numrun_cli;
      
            
      DBMS_OUTPUT.PUT_LINE('Nombre : ' || v_nombre_cliente);
      DBMS_OUTPUT.PUT_LINE('RUN : ' || v_run_cliente);
      DBMS_OUTPUT.PUT_LINE('Estado Civil : ' || v_desc_estcivil);
      DBMS_OUTPUT.PUT_LINE('Renta : ' || TO_CHAR(v_renta_cli, '$999G999G999'));
     
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
    
-- CASO 3 VERSION PROFE

SET SERVEROUTPUT ON

VAR v_numrun_emp NUMBER 
EXEC :v_numrun_emp := 12260812

UNDEFINE v_reajuste_1
UNDEFINE v_reajuste_2

DECLARE
       v_run_empleado     VARCHAR2(10);
       v_nombre_empleado  VARCHAR2(55);
       v_sueldo_emp       empleado.sueldo_emp%TYPE;
      
BEGIN
     
     SELECT numrut_emp || '-' || dvrut_emp,
            nombre_emp || ' ' || appaterno_emp || ' ' || apmaterno_emp,
            sueldo_emp

       INTO v_run_empleado,
            v_nombre_empleado,
            v_sueldo_emp

       FROM empleado
      WHERE numrut_emp = :v_numrun_emp
        AND sueldo_emp >= 200000 
        AND sueldo_emp <= 400000;
      
      DBMS_OUTPUT.PUT_LINE('NOMBRE DEL EMPLEADO : ' || v_nombre_empleado);
      DBMS_OUTPUT.PUT_LINE('RUN : ' || v_run_empleado);
      
      DBMS_OUTPUT.PUT_LINE('SIMULACION 1 : Aumentar en ' || &&v_reajuste_1 || '% el salario de todos los empleados');
      DBMS_OUTPUT.PUT_LINE('Sueldo Actual: ' || v_sueldo_emp);
      DBMS_OUTPUT.PUT_LINE('Sueldo Reajustado : ' || TO_CHAR(ROUND(v_sueldo_emp + (v_sueldo_emp * (&&v_reajuste_1 /100)))));
      DBMS_OUTPUT.PUT_LINE('Reajuste : ' || TO_CHAR(ROUND(v_sueldo_emp * (&&v_reajuste_1 /100))));
            
      DBMS_OUTPUT.PUT_LINE('SIMULACION 2 : Aumentar en ' || &&v_reajuste_2 || '% que poseen salarios entre $200.000 y $400.000');
      DBMS_OUTPUT.PUT_LINE('Sueldo Actual: ' || v_sueldo_emp);
      DBMS_OUTPUT.PUT_LINE('Sueldo Reajustado : ' || TO_CHAR(ROUND(v_sueldo_emp + (v_sueldo_emp * (&&v_reajuste_2 /100)))));
      DBMS_OUTPUT.PUT_LINE('Reajuste : ' || TO_CHAR(ROUND(v_sueldo_emp * (&&v_reajuste_2 /100))));
     
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

-- CASO 4 VERSION PROFE

SET SERVEROUTPUT ON

/*
A	Casa sin Amoblar
B	Casa Amoblada
C	Departamento sin Amoblar
D	Departamento Amoblado
E	Local Comercial
F	Parcela sin Casa
G	Parcela con Casa
H	Sitio
*/

DECLARE
       v_count_tipo_propiedad    NUMBER(10);
       v_desc_tipo_propiedad     tipo_propiedad.desc_tipo_propiedad%TYPE;
       v_sum_valor_arriendo      NUMBER(10);
      
BEGIN
     
     SELECT COUNT(id_tipo_propiedad),
            desc_tipo_propiedad,
            SUM(valor_arriendo)

       INTO v_count_tipo_propiedad,
            v_desc_tipo_propiedad,
            v_sum_valor_arriendo

       FROM propiedad NATURAL JOIN tipo_propiedad
       WHERE id_tipo_propiedad = UPPER('&v_id_tipo_propiedad')
       GROUP BY  desc_tipo_propiedad;
      
      DBMS_OUTPUT.PUT_LINE('RESUMEN DE : ' || v_desc_tipo_propiedad);
      DBMS_OUTPUT.PUT_LINE('Total de Propiedades : ' || v_count_tipo_propiedad);
      DBMS_OUTPUT.PUT_LINE('Valor Total Arriendo : ' || TO_CHAR(v_sum_valor_arriendo, '$999G999G999'));
     
     
END;
