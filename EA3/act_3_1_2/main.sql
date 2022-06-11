SET SERVEROUTPUT ON

DECLARE

    CURSOR c_gasto_comun(p_anno_mes NUMBER) IS 
        SELECT * 
        FROM gasto_comun
        WHERE anno_mes_pcgc = p_anno_mes
        ORDER BY id_edif;

BEGIN

    FOR i IN c_gasto_comun(202205) LOOP
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE(i.anno_mes_pcgc||' '||i.id_edif||' '||i.nro_depto||' '||fn_agua_comb(i.id_edif)); -- AGUA COMBUSTIBLE TOTAL
        DBMS_OUTPUT.PUT_LINE('Dias atraso '||fn_dias_atraso(i.anno_mes_pcgc, i.id_edif, i.nro_depto)); -- DIAS DE ATRASO PERIODO ANTERIOR
        DBMS_OUTPUT.PUT_LINE('Saldo anterior '||fn_saldo_anterior(i.anno_mes_pcgc, i.id_edif, i.nro_depto)); -- SALDO DEUDA ACUMULADO MES ANTERIOR
        
    END LOOP;

END;