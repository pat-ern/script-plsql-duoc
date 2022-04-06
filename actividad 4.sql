-- CASO 1

TRUNCATE TABLE proy_movilizacion;

SET SERVEROUTPUT ON

VAR b_anno_proceso NUMBER
EXEC :b_anno_proceso := EXTRACT(YEAR FROM SYSDATE)

DECLARE

    --VARIABLES OBTENIDAS EN SENTENCIA SELECT1
    v_min_id            empleado.id_emp%TYPE;            
    v_max_id            empleado.id_emp%TYPE;
    
    --VARIABLES OBTENIDAS EN SENTENCIA SELECT2
    v_id_emp            empleado.id_emp%TYPE;
    v_numrun_emp        empleado.numrun_emp%TYPE; 
    v_dvrun_emp         empleado.dvrun_emp%TYPE; 
    v_pnombre_emp       empleado.pnombre_emp%TYPE; 
    v_snombre_emp       empleado.snombre_emp%TYPE;
    v_appaterno_emp     empleado.appaterno_emp%TYPE;
    v_apmaterno_emp     empleado.apmaterno_emp%TYPE;
    v_sueldo_base       empleado.sueldo_base%TYPE;
    v_nombre_comuna     comuna.nombre_comuna%TYPE;
    
    --VARIABLES CALCULADAS
    v_porc_movil_normal  proy_movilizacion.porc_movil_normal%TYPE;
    v_valor_movil_normal proy_movilizacion.valor_movil_normal%TYPE;
    v_valor_movil_extra  proy_movilizacion.valor_movil_extra%TYPE;
    v_valor_total_movil  proy_movilizacion.valor_total_movil%TYPE;

BEGIN

    SELECT MIN(id_emp), MAX(id_emp)
        INTO v_min_id, v_max_id    
        FROM empleado;  
        
    WHILE v_max_id >= v_min_id LOOP --CONDICION

        SELECT id_emp,
            numrun_emp,
            dvrun_emp, 
            pnombre_emp, 
            snombre_emp,
            appaterno_emp,
            apmaterno_emp,
            sueldo_base,
            nombre_comuna
            
            INTO v_id_emp,
                v_numrun_emp, 
                v_dvrun_emp, 
                v_pnombre_emp, 
                v_snombre_emp,
                v_appaterno_emp,
                v_apmaterno_emp,
                v_sueldo_base,
                v_nombre_comuna
                
            FROM empleado NATURAL JOIN comuna
            WHERE id_emp = v_min_id; --CONDICION PARA RESULTADO DE FILA UNICA
        
        --ASIGNACION DE VALORES SEGUN COMUNA      
        CASE v_nombre_comuna 
            WHEN 'María Pinto' THEN v_valor_movil_extra := 20000;
            WHEN 'Curacaví' THEN v_valor_movil_extra := 25000;
            WHEN 'Talagante' THEN v_valor_movil_extra := 30000;
            WHEN 'El Monte' THEN v_valor_movil_extra := 35000;
            WHEN 'Buin' THEN v_valor_movil_extra := 40000;
            ELSE v_valor_movil_extra := 0;
        END CASE;
        
        --CALCULO DE VALORES
        v_porc_movil_normal := TRUNC(v_sueldo_base/100000);
        v_valor_movil_normal := v_sueldo_base * v_porc_movil_normal/100;
        v_valor_total_movil := v_valor_movil_normal + v_valor_movil_extra;
        
        --INSERCION EN TABLA PROY_MOVILIZACION
        INSERT INTO proy_movilizacion
        VALUES (:b_anno_proceso, 
                v_id_emp, 
                v_numrun_emp, 
                v_dvrun_emp, 
                v_pnombre_emp||' '||v_snombre_emp||' '||v_appaterno_emp||' '||v_apmaterno_emp, 
                v_nombre_comuna, 
                v_sueldo_base, 
                v_porc_movil_normal, 
                v_valor_movil_normal, 
                v_valor_movil_extra, 
                v_valor_total_movil);
                
        COMMIT;
        
        --INCREMENTO DE MIN_ID
        v_min_id := v_min_id + 10;
        
    END LOOP;    
    
END;

/*

REQUERIMIENTOS PENDIENTES: 

Uso de variables BIND para definir: 
a) Comunas a las que se les paga movilización adicional.
b) Valor de movilización adicional para las comunas indicadas.

*/

-- CASO 2

TRUNCATE TABLE usuario_clave;

SET SERVEROUTPUT ON

DECLARE

    v_max_id                empleado.id_emp%TYPE;
    v_min_id                empleado.id_emp%TYPE;
    
    v_id_emp                empleado.id_emp%TYPE;
    v_numrun_emp            empleado.numrun_emp%TYPE; 
    v_dvrun_emp             empleado.dvrun_emp%TYPE;
    v_pnombre_emp           empleado.pnombre_emp%TYPE;
    v_snombre_emp           empleado.snombre_emp%TYPE;
    v_appaterno_emp         empleado.appaterno_emp%TYPE;
    v_apmaterno_emp         empleado.apmaterno_emp%TYPE;
    v_fecha_nac             empleado.fecha_nac%TYPE;
    v_fecha_contrato        empleado.fecha_contrato%TYPE;
    v_sueldo_base           empleado.sueldo_base%TYPE;
    v_nombre_estado_civil   estado_civil.nombre_estado_civil%TYPE;
    
    v_nombre_usuario VARCHAR2(30); 
    v_clave_usuario VARCHAR2(30);

BEGIN

    SELECT MIN(id_emp), MAX(id_emp)
        INTO v_min_id, v_max_id    
        FROM empleado;  
        
    WHILE v_max_id >= v_min_id LOOP --CONDICION

        SELECT id_emp,
            numrun_emp,
            dvrun_emp,
            pnombre_emp,
            snombre_emp,
            appaterno_emp,
            apmaterno_emp,
            fecha_nac,
            fecha_contrato,
            sueldo_base,
            nombre_estado_civil

            INTO v_id_emp,
                v_numrun_emp, 
                v_dvrun_emp, 
                v_pnombre_emp, 
                v_snombre_emp,
                v_appaterno_emp,
                v_apmaterno_emp,
                v_fecha_nac,
                v_fecha_contrato,
                v_sueldo_base,
                v_nombre_estado_civil

            FROM empleado NATURAL JOIN comuna
            NATURAL JOIN estado_civil
            
            WHERE id_emp = v_min_id;

        v_nombre_usuario :=  

        LOWER(SUBSTR(v_nombre_estado_civil, 0, 1))||
        SUBSTR(v_pnombre_emp, 0, 3)|| 
        LENGTH(v_pnombre_emp)|| 
        '*'||
        SUBSTR(TO_CHAR(v_sueldo_base, '9999999'), -1, 1)|| 
        v_dvrun_emp|| 
        ROUND(MONTHS_BETWEEN(SYSDATE, v_fecha_contrato)/12)|| 
        CASE WHEN ROUND(MONTHS_BETWEEN(SYSDATE, v_fecha_contrato)/12) < 10 THEN 'X'
            ELSE NULL
        END;

        v_clave_usuario :=  

        SUBSTR(TO_CHAR(v_numrun_emp, '99999999'), 4, 1)||-- tercer digito del run
        (EXTRACT (YEAR FROM v_fecha_nac)+2)||-- anno de nacimiento aumentado en 2
        SUBSTR(TO_CHAR(v_sueldo_base-1, '9999999'), -3, 3)||-- 3 ultimos digitos del sueldo disminuido en 1 
        LOWER(CASE v_nombre_estado_civil 
            WHEN 'CASADO' THEN SUBSTR(v_appaterno_emp, 0, 2)
            WHEN 'ACUERDO DE UNION CIVIL' THEN SUBSTR(v_appaterno_emp, 0, 2)
            WHEN 'DIVORCIADO' THEN SUBSTR(v_appaterno_emp, 0, 1)||SUBSTR(v_appaterno_emp, -1, 1)
            WHEN 'SOLTERO' THEN SUBSTR(v_appaterno_emp, 0, 1)||SUBSTR(v_appaterno_emp, -1, 1)
            WHEN 'VIUDO' THEN SUBSTR(v_appaterno_emp, -3, 2)
            WHEN 'SEPARADO' THEN SUBSTR(v_appaterno_emp, -2, 2)
        END)|| -- 2 letras del apellido paterno
        v_id_emp|| --id empleado
        TO_CHAR(SYSDATE, 'MMYYYY'); --mes y anno en formato numerico

        INSERT INTO usuario_clave 
            VALUES (v_id_emp, 
                    v_numrun_emp, 
                    v_dvrun_emp, 
                    v_pnombre_emp||' '||v_snombre_emp||' '||v_appaterno_emp||' '||v_apmaterno_emp, 
                    v_nombre_usuario, 
                    v_clave_usuario);
        COMMIT;
    
        v_min_id := v_min_id + 10;

    END LOOP;   

END;

-- CASO 3 

TRUNCATE TABLE hist_arriendo_anual_camion;

SET SERVEROUTPUT ON

DECLARE

    v_max_id                camion.id_camion%TYPE;
    v_min_id                camion.id_camion%TYPE;

    v_anno_proceso          hist_arriendo_anual_camion.anno_proceso%TYPE;
    v_nro_patente           hist_arriendo_anual_camion.nro_patente%TYPE;
    v_id_camion             hist_arriendo_anual_camion.id_camion%TYPE;
    v_valor_arriendo_dia    hist_arriendo_anual_camion.valor_arriendo_dia%TYPE;
    v_valor_garantia_dia    hist_arriendo_anual_camion.valor_garactia_dia%TYPE;
    v_total_veces_arrendado hist_arriendo_anual_camion.total_veces_arrendado%TYPE;

    v_porc_ajuste         NUMBER(3,3) := 1-&PORC_AJUSTE/100;

BEGIN

    SELECT MIN(id_camion), MAX(id_camion)
        INTO v_min_id, v_max_id    
        FROM camion;  

    FOR i IN v_min_id .. v_max_id LOOP

        SELECT EXTRACT(YEAR FROM SYSDATE),
            cam.nro_patente, 
            cam.id_camion,
            cam.valor_arriendo_dia,
            cam.valor_garantia_dia,
            COUNT(arr.id_arriendo)  

            INTO v_anno_proceso,
                v_nro_patente,
                v_id_camion,
                v_valor_arriendo_dia,
                v_valor_garantia_dia,
                v_total_veces_arrendado

        FROM camion cam LEFT JOIN arriendo_camion arr
        ON cam.id_camion = arr.id_camion 
        AND EXTRACT(YEAR FROM arr.fecha_ini_arriendo) = EXTRACT(YEAR FROM SYSDATE)-1
        
        WHERE cam.id_camion = v_min_id
        
        GROUP BY EXTRACT(YEAR FROM SYSDATE), 
                cam.nro_patente, 
                cam.id_camion,
                cam.valor_arriendo_dia, 
                cam.valor_garantia_dia; 
        
        INSERT INTO hist_arriendo_anual_camion
            VALUES (v_anno_proceso,
                    v_id_camion,
                    v_nro_patente, 
                    v_valor_arriendo_dia, 
                    v_valor_garantia_dia, 
                    v_total_veces_arrendado);
            
        IF v_total_veces_arrendado < 4 THEN
            v_valor_arriendo_dia := v_valor_arriendo_dia*v_porc_ajuste;
            v_valor_garantia_dia := v_valor_garantia_dia*v_porc_ajuste;
        END IF;
        
        UPDATE camion
            SET valor_arriendo_dia = v_valor_arriendo_dia,
                valor_garantia_dia = v_valor_garantia_dia
            WHERE nro_patente = v_nro_patente;
                    
        COMMIT;

    v_min_id := v_min_id + 1;

    END LOOP;            

END;

-- CASO 4

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