-- CASO 2.3.2 VERSION PROFE

SET SERVEROUTPUT ON

DECLARE

    CURSOR c_resumen IS    
        SELECT TO_CHAR(ttc.fecha_transaccion, 'MMYYYY') fecha,
            ttt.cod_tptran_tarjeta,
            ttt.nombre_tptran_tarjeta tipo_transaccion,
            SUM(ttc.monto_total_transaccion) monto_total
        FROM transaccion_tarjeta_cliente ttc
        JOIN tipo_transaccion_tarjeta ttt ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = EXTRACT(YEAR FROM SYSDATE)
        AND ttt.cod_tptran_tarjeta NOT IN (101)
        GROUP BY TO_CHAR(ttc.fecha_transaccion, 'MMYYYY'),
            ttt.cod_tptran_tarjeta,
            ttt.nombre_tptran_tarjeta
        ORDER BY 1, 3;

    CURSOR c_detalle(p_fecha VARCHAR, p_tipo_tran VARCHAR) IS
        SELECT cli.numrun, cli.dvrun,
            tc.nro_tarjeta,
            ttc.nro_transaccion,
            ttc.fecha_transaccion,
            monto_total_transaccion
        FROM cliente cli
        JOIN tarjeta_cliente tc ON tc.numrun = cli.numrun
        JOIN transaccion_tarjeta_cliente ttc ON ttc.nro_tarjeta = tc.nro_tarjeta 
        WHERE TO_CHAR(ttc.fecha_transaccion, 'MMYYYY') = p_fecha
        AND ttc.cod_tptran_tarjeta = p_tipo_tran
        ORDER BY ttc.fecha_transaccion, cli.numrun;
        
    r_res c_resumen%ROWTYPE;
    r_det c_detalle%ROWTYPE;
        
BEGIN 

    OPEN c_resumen;
    
    LOOP
        FETCH c_resumen INTO r_res;
        EXIT WHEN c_resumen%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Detalle ------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Resumen: '||r_res.fecha||' TP.TRAN: '||r_res.tipo_transaccion||'Total: '||r_res.monto_total);

        
        OPEN c_detalle(r_res.fecha, r_res.tipo_transaccion);
        
            LOOP
                FETCH c_detalle INTO r_det;
                EXIT WHEN c_detalle%NOTFOUND;
                DBMS_OUTPUT.PUT_LINE('Detalle ------------------------------------');
                DBMS_OUTPUT.PUT_LINE('Numrun: '||r_det.numrun||' DVRUN: '||r_det.dvrun||'Fecha: '||r_det.fecha_transaccion);
            END LOOP;
        
        CLOSE c_detalle;
        
    END LOOP;
    
    CLOSE c_resumen;

END;