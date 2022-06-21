create or replace FUNCTION fn_multa_atraso(p_anno_mes IN NUMBER, p_id_edif IN NUMBER, p_nro_depto IN NUMBER, p_cant_dias IN NUMBER) RETURN NUMBER IS

    v_porc_ma multa_atraso.porc_ma%TYPE;
    v_multa_gc gasto_comun.multa_gc%TYPE;
    v_monto_total_gc gasto_comun.monto_total_gc%TYPE;
    v_multa_total NUMBER;

BEGIN

    BEGIN
        SELECT porc_ma
        INTO v_porc_ma
        FROM multa_atraso
        WHERE p_cant_dias BETWEEN tot_dias_inf_ma AND tot_dias_sup_ma
        AND TO_CHAR(p_anno_mes) <= TO_CHAR(fter_vig_ma, 'YYYYMM');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_porc_ma :=1;

    END;

    SELECT multa_gc, monto_total_gc
        INTO v_multa_gc, v_monto_total_gc
        FROM gasto_comun
        WHERE anno_mes_pcgc = p_anno_mes-1
        AND id_edif = p_id_edif
        AND nro_depto = p_nro_depto;

    IF v_porc_ma = 1 THEN
        v_multa_total := v_multa_gc;
    ELSE v_multa_total := ROUND(v_monto_total_gc * v_porc_ma) + v_multa_gc;
    END IF;
    
    return v_multa_total;

END fn_multa_atraso;