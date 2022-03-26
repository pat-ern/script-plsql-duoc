-- CASO 1

/*

1200 por cada 100.000

Trab Ind

-1.000.000				--- 100 +
1.000.001 a 3.000.000	--- 300 +
+3.000.000				--- 550 +

consultar por :

o	KAREN SOFIA PRADENAS MANDIOLA
o	SILVANA MARTINA VALENZUELA DUARTE
o	DENISSE ALICIA DIAZ MIRANDA
o	AMANDA ROMINA LIZANA MARAMBIO
o	LUIS CLAUDIO LUNA JORQUERA

21242003

*/

SET SERVEROUTPUT ON

VAR b_run NUMBER
EXEC :b_run := &RUN

DECLARE

    v_nro_cliente cliente_todosuma.nro_cliente%TYPE; 
    v_run_cliente cliente_todosuma.run_cliente%TYPE;   
    v_nombre_cliente cliente_todosuma.nombre_cliente%TYPE;    
    v_tipo_cliente cliente_todosuma.tipo_cliente%TYPE;    
    v_monto_solic_creditos cliente_todosuma.monto_solic_creditos%TYPE;    
    v_monto_pesos_todosuma cliente_todosuma.monto_pesos_todosuma%TYPE;
    
    v_monto_base NUMBER(4) := &monto_base;
    v_monto_extra1 NUMBER(3) := &monto_extra1;
    v_monto_extra2 NUMBER(3) := &monto_extra2;
    v_monto_extra3 NUMBER(3) := &monto_extra3;
    v_monto_extra_total NUMBER(10);
    
    v_tramo1 NUMBER(7) := &tramo1;
    v_tramo2_min NUMBER(7) := &tramo2_min;
    v_tramo2_max NUMBER(7) := &tramo2_max;

BEGIN

    SELECT cli.nro_cliente, 
           TO_CHAR(cli.numrun, 'FM99G999G999')||'-'||cli.dvrun,
           cli.pnombre||' '||cli.snombre||' '||cli.appaterno||' '||cli.apmaterno,
           tpc.nombre_tipo_cliente,
           SUM(crc.monto_solicitado)
        INTO v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente, v_monto_solic_creditos
        FROM cliente cli 
        JOIN tipo_cliente tpc ON tpc.cod_tipo_cliente = cli.cod_tipo_cliente
        JOIN credito_cliente crc ON  crc.nro_cliente = cli.nro_cliente
        WHERE EXTRACT(YEAR FROM crc.fecha_otorga_cred) = EXTRACT(YEAR FROM SYSDATE) - 1
        AND cli.numrun = :b_run
        GROUP BY cli.nro_cliente, 
           cli.numrun,
           cli.dvrun,
           cli.pnombre||' '||cli.snombre||' '||cli.appaterno||' '||cli.apmaterno,
           tpc.nombre_tipo_cliente;
               
    IF v_tipo_cliente = 'Trabajadores independientes' THEN
        IF v_monto_solic_creditos < v_tramo1 THEN v_monto_extra_total := v_monto_base + v_monto_extra1;
        ELSIF v_monto_solic_creditos BETWEEN v_tramo2_min AND v_tramo2_max THEN v_monto_extra_total := v_monto_base + v_monto_extra2;
        ELSIF v_monto_solic_creditos > v_tramo2_max THEN v_monto_extra_total := v_monto_base + v_monto_extra3;
        END IF;
    ELSE v_monto_extra_total := v_monto_base;
    END IF;
    
    v_monto_pesos_todosuma := ROUND((v_monto_solic_creditos / 100000) * v_monto_extra_total);
    
    INSERT INTO cliente_todosuma
    VALUES (v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente, v_monto_solic_creditos, v_monto_pesos_todosuma);
    COMMIT;

END;

-- CASO 2
/*
pruebas:
12362093
07455786
06604005
08925537
24617341
*/

SET SERVEROUTPUT ON

DECLARE

    v_run                   NUMBER(8) := &RUN;
    
    v_nro_cliente           cumpleanno_cliente.nro_cliente%TYPE;  
    v_run_cliente           cumpleanno_cliente.run_cliente%TYPE;
    v_nombre_cliente        cumpleanno_cliente.nombre_cliente%TYPE;
    v_profesion_oficio      cumpleanno_cliente.profesion_oficio%TYPE;
    v_dia_cumpleano         cumpleanno_cliente.dia_cumpleano%TYPE;
    v_fecha_nacimiento      cliente.fecha_nacimiento%TYPE;
    v_monto_total_ahorrado  producto_inversion_cliente.monto_total_ahorrado%TYPE;
    
    v_monto_gifcard         cumpleanno_cliente.monto_gifcard%TYPE;
    v_observacion           cumpleanno_cliente.observacion%TYPE;

BEGIN

    SELECT nro_cliente,
        TO_CHAR(numrun, 'FM09G999G999')||'-'||dvrun,
        INITCAP(pnombre||' '||snombre||' '||appaterno||' '||apmaterno),
        nombre_prof_ofic,
        TO_CHAR(fecha_nacimiento, 'DD')||' de '||TO_CHAR(fecha_nacimiento, 'Month'),
        fecha_nacimiento,
        monto_total_ahorrado
        
        INTO v_nro_cliente,
            v_run_cliente,
            v_nombre_cliente,
            v_profesion_oficio,
            v_dia_cumpleano,
            v_fecha_nacimiento,
            v_monto_total_ahorrado
        
        FROM cliente NATURAL JOIN profesion_oficio
        NATURAL JOIN producto_inversion_cliente
        WHERE numrun = v_run;
        
    IF EXTRACT(MONTH FROM v_fecha_nacimiento) = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, 1)) THEN -- TRUE si esta de cumple el mes siguiente   
        IF v_monto_total_ahorrado BETWEEN 0 AND 900000 THEN v_monto_gifcard := 0;
        ELSIF v_monto_total_ahorrado BETWEEN 900001 AND 2000000 THEN v_monto_gifcard := 50000;
        ELSIF v_monto_total_ahorrado BETWEEN 2000001 AND 5000000 THEN v_monto_gifcard := 100000;
        ELSIF v_monto_total_ahorrado BETWEEN 5000001 AND 8000000 THEN v_monto_gifcard := 200000;
        ELSIF v_monto_total_ahorrado BETWEEN 8000001 AND 15000000 THEN v_monto_gifcard := 300000;
        END IF;
    ELSE v_observacion := 'El cliente no esta de cumpleaños en el mes procesado';
    END IF;

    INSERT INTO cumpleanno_cliente
        VALUES (v_nro_cliente,
                v_run_cliente,
                v_nombre_cliente,
                v_profesion_oficio,
                v_dia_cumpleano,
                v_monto_gifcard,
                v_observacion);
    
EXCEPTION WHEN NO_DATA_FOUND THEN -- cuando no arroja data es porque no tiene productos de inversion

    SELECT nro_cliente,
        TO_CHAR(numrun, 'FM09G999G999')||'-'||dvrun,
        INITCAP(pnombre||' '||snombre||' '||appaterno||' '||apmaterno),
        nombre_prof_ofic,
        TO_CHAR(fecha_nacimiento, 'DD')||' de '||TO_CHAR(fecha_nacimiento, 'Month'),
        fecha_nacimiento
        
        INTO v_nro_cliente,
            v_run_cliente,
            v_nombre_cliente,
            v_profesion_oficio,
            v_dia_cumpleano,
            v_fecha_nacimiento
        
        FROM cliente NATURAL JOIN profesion_oficio
        WHERE numrun = v_run;  
                                                  
    IF EXTRACT(MONTH FROM v_fecha_nacimiento) = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, 1)) THEN -- TRUE si esta de cumple el mes siguiente
        v_monto_gifcard := 0;
    ELSE v_observacion := 'El cliente no esta de cumpleaños en el mes procesado';
    END IF;

    INSERT INTO cumpleanno_cliente
    VALUES (v_nro_cliente,
            v_run_cliente,
            v_nombre_cliente,
            v_profesion_oficio,
            v_dia_cumpleano,
            v_monto_gifcard,
            v_observacion);

END;

