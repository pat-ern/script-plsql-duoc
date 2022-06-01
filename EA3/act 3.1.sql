-- CASO 1

-- HOJA PRINCIPAL

ROLLBACK;

VAR b_anno_mes NUMBER
EXEC :b_anno_mes := 202205

VAR b_uf NUMBER
EXEC :b_uf := 29509

EXEC P_GENERAR_GCPC(:b_anno_mes,:b_uf)

-- PROCEDIMIENTO p_insertar_gcpc

create or replace PROCEDURE p_insertar_gcpc
    (p_anno_mes NUMBER,
    p_id_edif NUMBER,
    p_nom_edif VARCHAR2,
    p_run_adm VARCHAR2,
    p_nom_adm VARCHAR2,
    p_nro_depto NUMBER,
    p_run_resp VARCHAR2,
    p_nom_resp VARCHAR2,
    p_val_multa NUMBER,
    p_obs VARCHAR2) AS
BEGIN
    INSERT INTO gasto_comun_pago_cero 
    VALUES (p_anno_mes, 
        p_id_edif, 
        p_nom_edif, 
        p_run_adm, 
        p_nom_adm, 
        p_nro_depto, 
        p_run_resp, 
        p_nom_resp, 
        p_val_multa, 
        p_obs);
END p_insertar_gcpc;

-- PROCEDIMIENTO p_generar_gcpc

create or replace PROCEDURE p_generar_gcpc(p_anno_mes NUMBER, p_uf NUMBER) IS

    CURSOR c_gcpcero_mes_ant IS
    
        SELECT p_anno_mes anno_mes_pcgc,
            gc.id_edif,
            ed.nombre_edif nombre_edif,
            TO_CHAR(adm.numrun_adm, 'FM09G999G999')||'-'||adm.dvrun_adm run_administrador,
            INITCAP(adm.pnombre_adm||' '||adm.snombre_adm||' '||adm.appaterno_adm||' '||adm.apmaterno_adm) nombre_administrador,
            gc.nro_depto, 
            TO_CHAR(rpgc.numrun_rpgc, 'FM09G999G999')||'-'||rpgc.dvrun_rpgc run_responsable_pago_gc, 
            INITCAP(rpgc.pnombre_rpgc||' '||rpgc.snombre_rpgc||' '||rpgc.appaterno_rpgc||' '||rpgc.apmaterno_rpgc) nombre_responsable_pago_gc,
            0 valor_multa_pago_cero,
            '' observacion
        FROM gasto_comun gc
        JOIN departamento dep ON dep.nro_depto = gc.nro_depto AND dep.id_edif = gc.id_edif
        JOIN edificio ed ON ed.id_edif = dep.id_edif
        JOIN administrador adm ON adm.numrun_adm = ed.numrun_adm
        JOIN responsable_pago_gasto_comun rpgc ON rpgc.numrun_rpgc = gc.numrun_rpgc
        LEFT OUTER JOIN pago_gasto_comun pgc ON pgc.anno_mes_pcgc = gc.anno_mes_pcgc
        AND pgc.id_edif = gc.id_edif AND pgc.nro_depto = gc.nro_depto
        WHERE gc.anno_mes_pcgc = p_anno_mes - 1
        AND pgc.fecha_cancelacion_pgc IS NULL
        ORDER BY nombre_edif, gc.nro_depto;

    rt_gcpc gasto_comun_pago_cero%ROWTYPE;

    v_flag NUMBER;
    v_fecha DATE;


BEGIN

    OPEN c_gcpcero_mes_ant;

    LOOP
    
        FETCH c_gcpcero_mes_ant INTO rt_gcpc;
        EXIT WHEN c_gcpcero_mes_ant%NOTFOUND;

        -- CONSULTAS: SI DEBE MAS DE 1 GASTO COMUN
        BEGIN
            SELECT 1
                INTO v_flag
                FROM pago_gasto_comun
                WHERE anno_mes_pcgc = p_anno_mes - 2
                AND id_edif = rt_gcpc.id_edif
                AND nro_depto = rt_gcpc.nro_depto;

        EXCEPTION WHEN NO_DATA_FOUND THEN
            v_flag := 2;
            SELECT fecha_pago_gc
                INTO v_fecha
                FROM gasto_comun 
                WHERE anno_mes_pcgc = p_anno_mes
                AND id_edif = rt_gcpc.id_edif
                AND nro_depto = rt_gcpc.nro_depto;
        END;

        -- VALOR MULTA
        rt_gcpc.valor_multa_pago_cero :=
            CASE v_flag
            WHEN 1 THEN p_uf
            ELSE p_uf * 2
            END;

        -- OBSERVACION    
        rt_gcpc.observacion := 'Se realizara el corte del combustible y agua'||
            CASE v_flag
            WHEN 1 THEN  '.'
            ELSE ' a contar del '||TO_CHAR(v_fecha, 'DD/MM/YYYY')||'.'
            END;

        P_INSERTAR_GCPC(rt_gcpc.anno_mes_pcgc,
            rt_gcpc.id_edif,
            rt_gcpc.nombre_edif,
            rt_gcpc.run_administrador,
            rt_gcpc.nombre_admnistrador,
            rt_gcpc.nro_depto,
            rt_gcpc.run_responsable_pago_gc,
            rt_gcpc.nombre_responsable_pago_gc,
            rt_gcpc.valor_multa_pago_cero,
            rt_gcpc.observacion);

        -- UPDATE TABLA GASTO COMUN    
        UPDATE gasto_comun 
            SET multa_gc = rt_gcpc.valor_multa_pago_cero
            WHERE anno_mes_pcgc = p_anno_mes 
            AND id_edif = rt_gcpc.id_edif
            AND nro_depto = rt_gcpc.nro_depto;

    END LOOP;

    CLOSE c_gcpcero_mes_ant;

END;