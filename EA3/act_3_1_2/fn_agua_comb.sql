create or replace FUNCTION fn_agua_comb(p_id_edif IN NUMBER) RETURN NUMBER IS

    v_total NUMBER;
    
BEGIN

    SELECT SUM(agua_individual_gc) + SUM(combustible_individual_gc)
        INTO v_total
    FROM gasto_comun
    WHERE id_edif = p_id_edif
    GROUP BY id_edif;

    RETURN v_total;
    
END fn_agua_comb;