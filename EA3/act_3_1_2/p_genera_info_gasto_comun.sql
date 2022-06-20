create or replace PROCEDURE p_genera_info_gasto_comun(p_periodo NUMBER, p_porcentaje NUMBER) AS

    CURSOR c_resumen_gc(p_anno_mes NUMBER) IS 
        SELECT anno_mes_pcgc, id_edif 
        FROM gasto_comun
        WHERE anno_mes_pcgc = p_anno_mes
        GROUP BY anno_mes_pcgc, id_edif
        ORDER BY id_edif;

    CURSOR c_gasto_comun(p_anno_mes NUMBER, p_id_edif NUMBER) IS 
        SELECT * 
        FROM gasto_comun
        WHERE anno_mes_pcgc = p_anno_mes
        AND id_edif = p_id_edif
        ORDER BY id_edif, nro_depto;

    v_fondo_reserva gasto_comun.fondo_reserva_gc%TYPE;
    v_prorrateo NUMBER(6);
    v_dias_atraso NUMBER(4);
    v_multa_atraso gasto_comun.multa_gc%TYPE;
    v_valor_servicio gasto_comun.servicio_gc%TYPE;
    v_tot_gasto_comun gasto_comun.monto_total_gc%TYPE;

    rt_resumen_gc resumen_gasto_comun%ROWTYPE;

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE resumen_gasto_comun';

    FOR i IN c_resumen_gc(p_periodo) LOOP

        rt_resumen_gc.anno_mes_pcgc := i.anno_mes_pcgc;
        rt_resumen_gc.id_edif := i.id_edif;

        -- INICIALIZADORES
        rt_resumen_gc.prorrateado_gc := 0;
        rt_resumen_gc.fondo_reserva_gc := 0;
        rt_resumen_gc.agua_individual_gc := 0;
        rt_resumen_gc.combustible_individual_gc := 0;
        rt_resumen_gc.lavanderia_gc := 0;
        rt_resumen_gc.evento_gc := 0;
        rt_resumen_gc.servicio_gc := 0;
        rt_resumen_gc.monto_atrasado_gc := 0;
        rt_resumen_gc.multa_gc := 0;
        rt_resumen_gc.monto_total_gc := 0;

        FOR j IN c_gasto_comun(rt_resumen_gc.anno_mes_pcgc, rt_resumen_gc.id_edif) LOOP

            v_prorrateo := fn_prorrateo_depto(j.anno_mes_pcgc, j.id_edif, j.nro_depto);
            v_fondo_reserva := ROUND(fn_prorrateo_depto(j.anno_mes_pcgc, j.id_edif, j.nro_depto) * p_porcentaje/100);
            v_valor_servicio := j.lavanderia_gc + j.evento_gc;
            -- FALTA MONTO ATRASADO
            v_dias_atraso := fn_dias_atraso(j.anno_mes_pcgc, j.id_edif, j.nro_depto);
            v_multa_atraso := fn_multa_atraso(j.anno_mes_pcgc, j.id_edif, j.nro_depto, v_dias_atraso);
            v_tot_gasto_comun := v_prorrateo + v_fondo_reserva + j.agua_individual_gc + 
                j.combustible_individual_gc + v_valor_servicio + j.monto_atrasado_gc +
                v_multa_atraso;  


            UPDATE gasto_comun 
                SET prorrateado_gc = v_prorrateo,
                    fondo_reserva_gc = v_fondo_reserva, 
                    servicio_gc = v_valor_servicio, 
                    multa_gc = v_multa_atraso, 
                    monto_total_gc = v_tot_gasto_comun
                WHERE anno_mes_pcgc = j.anno_mes_pcgc
                    AND id_edif = j.id_edif
                    AND nro_depto = j.nro_depto;

            -- ACUMULADORES
            rt_resumen_gc.prorrateado_gc := rt_resumen_gc.prorrateado_gc + v_prorrateo;
            rt_resumen_gc.fondo_reserva_gc := rt_resumen_gc.fondo_reserva_gc + v_fondo_reserva;
            rt_resumen_gc.agua_individual_gc := rt_resumen_gc.agua_individual_gc + j.agua_individual_gc;
            rt_resumen_gc.combustible_individual_gc := rt_resumen_gc.combustible_individual_gc + j.combustible_individual_gc;
            rt_resumen_gc.lavanderia_gc := rt_resumen_gc.lavanderia_gc + j.lavanderia_gc;
            rt_resumen_gc.evento_gc := rt_resumen_gc.evento_gc + j.evento_gc;
            rt_resumen_gc.servicio_gc := rt_resumen_gc.servicio_gc + v_valor_servicio;
            rt_resumen_gc.monto_atrasado_gc := rt_resumen_gc.monto_atrasado_gc + j.monto_atrasado_gc;
            rt_resumen_gc.multa_gc := rt_resumen_gc.multa_gc + v_multa_atraso;
            rt_resumen_gc.monto_total_gc := rt_resumen_gc.monto_total_gc + v_tot_gasto_comun;

        END LOOP;

        INSERT INTO resumen_gasto_comun VALUES rt_resumen_gc;

    END LOOP;

END;