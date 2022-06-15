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
    
    v_valor_servicio gasto_comun.servicio_gc%TYPE;
    
    v_tot_gasto_comun gasto_comun.monto_total_gc%TYPE;

BEGIN

    FOR i IN c_gasto_comun(:b_annomes) LOOP
    
        v_fondo_reserva := ROUND(fn_prorrateo_depto(i.anno_mes_pcgc, i.id_edif, i.nro_depto) * 5/100);
        
        SELECT  lavanderia_gc + evento_gc
            INTO v_valor_servicio
            FROM gasto_comun
            WHERE anno_mes_pcgc = i.anno_mes_pcgc
            AND id_edif = i.id_edif
            AND nro_depto = i.nro_depto;
            
        -- Totalizar gasto comun
       
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Periodo '||i.anno_mes_pcgc||' Id Edificio '||i.id_edif||' Nro Depto '||i.nro_depto); -- DEPTO
        DBMS_OUTPUT.PUT_LINE('Prorrateo Depto '||fn_prorrateo_depto(i.anno_mes_pcgc, i.id_edif, i.nro_depto)||' Fondo Reserva '||v_fondo_reserva);
        DBMS_OUTPUT.PUT_LINE('Dias atraso '||fn_dias_atraso(i.anno_mes_pcgc, i.id_edif, i.nro_depto));
        DBMS_OUTPUT.PUT_LINE('Multa atraso '||fn_multa_atraso(i.anno_mes_pcgc, i.id_edif, i.nro_depto, fn_dias_atraso(i.anno_mes_pcgc, i.id_edif, i.nro_depto)));
        DBMS_OUTPUT.PUT_LINE('Valor Servicio '||v_valor_servicio);
        
        
        
    END LOOP;

END;
