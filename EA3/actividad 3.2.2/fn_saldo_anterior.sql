create or replace FUNCTION fn_saldo_anterior(p_anno_mes IN NUMBER, p_id_edif IN NUMBER, p_nro_depto IN NUMBER) RETURN NUMBER IS

    v_saldo NUMBER;

BEGIN

    SELECT gc.monto_total_gc - pgc.monto_cancelado_pgc
        INTO v_saldo
        FROM gasto_comun gc
        JOIN pago_gasto_comun pgc 
            ON pgc.anno_mes_pcgc = gc.anno_mes_pcgc
            AND pgc.id_edif = gc.id_edif
            AND pgc.nro_depto = gc.nro_depto
        WHERE gc.anno_mes_pcgc = p_anno_mes-1
            AND gc.id_edif = p_id_edif
            AND gc.nro_depto = p_nro_depto;
            
    RETURN v_saldo;

EXCEPTION

    WHEN OTHERS THEN
        v_saldo := 0;
        RETURN v_saldo;

END fn_saldo_anterior;