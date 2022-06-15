create or replace FUNCTION fn_prorrateo_depto(p_anno_mes IN NUMBER, p_id_edif IN NUMBER, p_nro_depto IN NUMBER) RETURN NUMBER IS

    v_agua_comb NUMBER;
    v_porc NUMBER;
    v_total NUMBER;
    
BEGIN

    SELECT SUM(agua_individual_gc) + SUM(combustible_individual_gc)
        INTO v_agua_comb
    FROM gasto_comun
    WHERE id_edif = p_id_edif
    AND anno_mes_pcgc = p_anno_mes
    GROUP BY id_edif;
    
    SELECT porc_prorrateo_depto
        INTO v_porc
    FROM departamento
    WHERE id_edif = p_id_edif
    AND nro_depto = p_nro_depto;
    
    v_total := ROUND(v_agua_comb * v_porc/100);

    RETURN v_total;
    
END fn_prorrateo_depto;