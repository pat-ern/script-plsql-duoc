SET SERVEROUTPUT ON

VAR b_annomes NUMBER
EXEC :b_annomes := 202205

DECLARE

    CURSOR c_gasto_comun(p_anno_mes NUMBER) IS 
        SELECT * 
        FROM gasto_comun
        WHERE anno_mes_pcgc = p_anno_mes
        ORDER BY id_edif, nro_depto;

    v_fondo_reserva gasto_comun.fondo_reserva_gc%TYPE;
    v_prorrateo NUMBER(6);
    v_dias_atraso NUMBER(4);
    v_multa_atraso gasto_comun.multa_gc%TYPE;
    v_valor_servicio gasto_comun.servicio_gc%TYPE;
    v_tot_gasto_comun gasto_comun.monto_total_gc%TYPE;
    
BEGIN

    FOR i IN c_gasto_comun(:b_annomes) LOOP
    
        v_fondo_reserva := ROUND(fn_prorrateo_depto(i.anno_mes_pcgc, i.id_edif, i.nro_depto) * 5/100);
        v_valor_servicio := i.lavanderia_gc + i.evento_gc;
        v_prorrateo := fn_prorrateo_depto(i.anno_mes_pcgc, i.id_edif, i.nro_depto);
        v_dias_atraso := fn_dias_atraso(i.anno_mes_pcgc, i.id_edif, i.nro_depto);
        v_multa_atraso := fn_multa_atraso(i.anno_mes_pcgc, i.id_edif, i.nro_depto, v_dias_atraso);
        
        v_tot_gasto_comun := v_prorrateo + v_fondo_reserva + i.agua_individual_gc + 
            i.combustible_individual_gc + v_valor_servicio + i.monto_atrasado_gc +
            v_multa_atraso;
            
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Periodo '||i.anno_mes_pcgc||' Id Edificio '||i.id_edif||' Nro Depto '||i.nro_depto); -- DEPTO
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Prorrateo Depto '||v_prorrateo);
        DBMS_OUTPUT.PUT_LINE('Fondo Reserva '||v_fondo_reserva);
        DBMS_OUTPUT.PUT_LINE('Multa atraso '||v_multa_atraso);
        DBMS_OUTPUT.PUT_LINE('Valor Servicio '||v_valor_servicio);
        DBMS_OUTPUT.PUT_LINE('Total Gasto Comun '||v_tot_gasto_comun);

    END LOOP;

END;