create or replace FUNCTION fn_dias_atraso(p_anno_mes IN NUMBER, p_id_edif IN NUMBER, p_nro_depto IN NUMBER) RETURN NUMBER IS

    v_fecha_pago_gc gasto_comun.fecha_pago_gc%TYPE;
    v_dias_atraso NUMBER;

BEGIN

    SELECT (CASE 
            WHEN pgc.fecha_cancelacion_pgc - gc.fecha_pago_gc < 0 THEN 0 
            ELSE pgc.fecha_cancelacion_pgc - gc.fecha_pago_gc END)
        INTO v_dias_atraso
        FROM gasto_comun gc
        JOIN pago_gasto_comun pgc 
            ON pgc.anno_mes_pcgc = gc.anno_mes_pcgc
            AND pgc.id_edif = gc.id_edif 
            AND pgc.nro_depto = gc.nro_depto
        WHERE gc.anno_mes_pcgc = p_anno_mes-1
            AND gc.id_edif = p_id_edif
            AND gc.nro_depto = p_nro_depto;

    RETURN v_dias_atraso;


EXCEPTION
    
    WHEN OTHERS THEN
        
        SELECT fecha_pago_gc
            INTO v_fecha_pago_gc
            FROM gasto_comun
            WHERE anno_mes_pcgc = p_anno_mes-1
            AND id_edif = p_id_edif
            AND nro_depto = p_nro_depto;
            
        v_dias_atraso := TRUNC(SYSDATE - v_fecha_pago_gc);
        
        RETURN v_dias_atraso;

END fn_dias_atraso;