-- CASO 1 (Desarrollado con profesora Alejandra en reforzamiento)

VAR b_tramo_1 NUMBER
VAR b_tramo_2 NUMBER
VAR b_tramo_3 NUMBER
VAR b_tramo_4 NUMBER

EXEC :b_tramo_1 := 500000
EXEC :b_tramo_2 := 700000
EXEC :b_tramo_3 := 700001
EXEC :b_tramo_4 := 900000

DECLARE

    CURSOR cur_meses_transac IS
        SELECT DISTINCT TO_CHAR(fecha_transaccion, 'MMYYYY') mes_anno
        FROM transaccion_tarjeta_cliente
        WHERE EXTRACT(YEAR FROM fecha_transaccion) = EXTRACT(YEAR FROM SYSDATE)-1
        ORDER BY mes_anno;

    CURSOR cur_transac_clientes(p_mes_anno_tran VARCHAR2) IS
        SELECT c.numrun, 
            c.dvrun, c.cod_tipo_cliente,
            ttc.nro_tarjeta,
            ttc.cod_tptran_tarjeta,
            ttc.nro_transaccion,
            ttc.fecha_transaccion,
            ttc.monto_transaccion,
            ttt.nombre_tptran_tarjeta 
        FROM cliente c 
        JOIN tarjeta_cliente tc ON tc.numrun = c.numrun
        JOIN transaccion_tarjeta_cliente ttc ON ttc.nro_tarjeta = tc.nro_tarjeta
        JOIN tipo_transaccion_tarjeta ttt ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta 
        WHERE TO_CHAR(ttc.fecha_transaccion, 'MMYYYY' ) = p_mes_anno_tran
        ORDER BY ttc.fecha_transaccion;
        
    TYPE t_tipo_varray_puntos IS VARRAY(4) 
        OF NUMBER(3);
        
    va_puntos t_tipo_varray_puntos := t_tipo_varray_puntos(250,300,550,700);
    
    v_puntos_normales NUMBER(8);
    v_puntos_extras NUMBER(8);
    v_tot_puntos NUMBER(8);   
    
    v_monto_tot_com NUMBER(8);
    v_tot_ptos_com NUMBER(8);
    v_monto_tot_ava NUMBER(8);
    v_tot_ptos_ava NUMBER(8);
    v_monto_tot_sava NUMBER(8);
    v_tot_ptos_sava NUMBER(8);
    
    
BEGIN

    EXECUTE IMMEDIATE ('TRUNCATE TABLE detalle_puntos_tarjeta_catb');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE resumen_puntos_tarjeta_catb');
    
    FOR reg_meses_transac IN cur_meses_transac LOOP
    
        v_monto_tot_com := 0;
        v_tot_ptos_com := 0;
        v_monto_tot_ava := 0;
        v_tot_ptos_ava := 0;
        v_monto_tot_sava := 0;
        v_tot_ptos_sava := 0;
    
        FOR reg_transacciones IN cur_transac_clientes(reg_meses_transac.mes_anno) LOOP
        
            v_puntos_extras:= 0;
            v_puntos_normales := TRUNC(reg_transacciones.monto_transaccion/100000)*va_puntos(1);
            
            IF reg_transacciones.cod_tipo_cliente IN (30, 40) THEN
            
                IF reg_transacciones.monto_transaccion BETWEEN :b_tramo_1 AND :b_tramo_2 THEN
                    v_puntos_extras := TRUNC(reg_transacciones.monto_transaccion/100000)*va_puntos(2);
                ELSIF reg_transacciones.monto_transaccion BETWEEN :b_tramo_3 AND :b_tramo_4 THEN
                    v_puntos_extras := TRUNC(reg_transacciones.monto_transaccion/100000)*va_puntos(3);
                ELSIF reg_transacciones.monto_transaccion > :b_tramo_4 THEN
                    v_puntos_extras := TRUNC(reg_transacciones.monto_transaccion/100000)*va_puntos(4);    
                END IF;
                
            END IF;
            
            v_tot_puntos := v_puntos_normales + v_puntos_extras;
            
            INSERT INTO detalle_puntos_tarjeta_catb 
                VALUES (reg_transacciones.numrun,
                    reg_transacciones.dvrun,
                    reg_transacciones.nro_tarjeta,
                    reg_transacciones.nro_transaccion,
                    reg_transacciones.fecha_transaccion,
                    reg_transacciones.nombre_tptran_tarjeta,
                    reg_transacciones.monto_transaccion,
                    v_tot_puntos);
                    
            IF reg_transacciones.cod_tptran_tarjeta = 101 THEN
                v_monto_tot_com := v_monto_tot_com + reg_transacciones.monto_transaccion;
                v_tot_ptos_com := v_tot_ptos_com + v_tot_puntos;
            ELSIF reg_transacciones.cod_tptran_tarjeta = 102 THEN
                v_monto_tot_ava := v_monto_tot_ava + reg_transacciones.monto_transaccion;
                v_tot_ptos_ava := v_tot_ptos_ava + v_tot_puntos;
            ELSE v_monto_tot_sava := v_monto_tot_sava + reg_transacciones.monto_transaccion;
                v_tot_ptos_sava := v_tot_ptos_sava + v_tot_puntos; 
            END IF;
            
        END LOOP;
        
        INSERT INTO resumen_puntos_tarjeta_catb 
            VALUES (reg_meses_transac.mes_anno,
            v_monto_tot_com,
            v_tot_ptos_com,
            v_monto_tot_ava,
            v_tot_ptos_ava,
            v_monto_tot_sava,
            v_tot_ptos_sava);
        
    END LOOP;

END;

-- CASO 2

SET SERVEROUTPUT ON

DECLARE

    CURSOR c_resumen IS    
        SELECT DISTINCT TO_CHAR(ttc.fecha_transaccion, 'MMYYYY') fecha,
            ttt.nombre_tptran_tarjeta tipo_transaccion
        FROM transaccion_tarjeta_cliente ttc
        JOIN tipo_transaccion_tarjeta ttt ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
        WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = EXTRACT(YEAR FROM SYSDATE)
        AND ttt.cod_tptran_tarjeta IN (102, 103)
        ORDER BY TO_CHAR(ttc.fecha_transaccion, 'MMYYYY'), 
            ttt.nombre_tptran_tarjeta;

    CURSOR c_detalle(p_fecha VARCHAR, p_tipo_tran VARCHAR) IS
        SELECT c.numrun, c.dvrun,
            tc.nro_tarjeta,
            ttc.nro_transaccion,
            ttc.fecha_transaccion,
            ttt.nombre_tptran_tarjeta tipo_transaccion,
            ROUND(ttc.monto_transaccion * (ttt.tasaint_tptran_tarjeta + 1)) monto_total_transaccion
        FROM cliente c
        JOIN tarjeta_cliente tc ON tc.numrun = c.numrun
        JOIN transaccion_tarjeta_cliente ttc ON ttc.nro_tarjeta = tc.nro_tarjeta 
        JOIN tipo_transaccion_tarjeta ttt ON ttt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
        WHERE TO_CHAR(ttc.fecha_transaccion, 'MMYYYY') = p_fecha
        AND ttt.nombre_tptran_tarjeta = p_tipo_tran
        ORDER BY ttc.fecha_transaccion, c.numrun;
        
    rt_tabla_detalle detalle_aporte_sbif%ROWTYPE;
    
    rt_tabla_resumen resumen_aporte_sbif%ROWTYPE;
    
    v_porc_sbif tramo_aporte_sbif.porc_aporte_sbif%TYPE;
    
    v_monto_total NUMBER(7);
    v_monto_aporte NUMBER(7);

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_aporte_sbif';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE resumen_aporte_sbif';
    
    FOR r_resumen IN c_resumen LOOP
    
    v_monto_total := 0;
    v_monto_aporte := 0;
    
        
        FOR r_detalle IN c_detalle(r_resumen.fecha, r_resumen.tipo_transaccion) LOOP
        
            rt_tabla_detalle.numrun := r_detalle.numrun;
            rt_tabla_detalle.dvrun := r_detalle.dvrun;
            rt_tabla_detalle.nro_tarjeta := r_detalle.nro_tarjeta;
            rt_tabla_detalle.nro_transaccion := r_detalle.nro_transaccion;
            rt_tabla_detalle.fecha_transaccion := r_detalle.fecha_transaccion;
            rt_tabla_detalle.tipo_transaccion := r_detalle.tipo_transaccion;
            rt_tabla_detalle.monto_transaccion := r_detalle.monto_total_transaccion;

            SELECT porc_aporte_sbif 
            INTO v_porc_sbif
            FROM tramo_aporte_sbif
            WHERE rt_tabla_detalle.monto_transaccion BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;
            
            rt_tabla_detalle.aporte_sbif := ROUND(rt_tabla_detalle.monto_transaccion * v_porc_sbif/100);
            
            INSERT INTO detalle_aporte_sbif VALUES rt_tabla_detalle;
            
            v_monto_total := v_monto_total + rt_tabla_detalle.monto_transaccion;
            v_monto_aporte := v_monto_aporte + rt_tabla_detalle.aporte_sbif;
    
        END LOOP;
        
        rt_tabla_resumen.mes_anno := r_resumen.fecha;
        rt_tabla_resumen.tipo_transaccion := r_resumen.tipo_transaccion;
        rt_tabla_resumen.monto_total_transacciones := v_monto_total;
        rt_tabla_resumen.aporte_total_abif := v_monto_aporte;
        
        INSERT INTO resumen_aporte_sbif VALUES rt_tabla_resumen;
        
    END LOOP;

END;

-- CASO 3 (Me falta hacer que la tabla quede ordenada segun requerimiento)

SET SERVEROUTPUT ON

DECLARE

    -- Cursor con las transacciones 
    CURSOR c_transac IS
        SELECT nro_tarjeta,
            fecha_transaccion,
            nro_transaccion,
            cod_tptran_tarjeta,
            monto_total_transaccion,
            total_cuotas_transaccion
        FROM transaccion_tarjeta_cliente;

    -- Cursor de las cuotas pagadas en una determinada transaccion (por nro tarjeta y nro transac)
    -- Deben ser cuotas pagadas el año anterior
    CURSOR c_cuotas(p_tarjeta NUMBER, p_nro_transac NUMBER) IS
        SELECT TO_CHAR(fecha_pago, 'MM/YYYY') mes_anno,
            nro_cuota,
            fecha_venc_cuota,
            valor_cuota,
            fecha_pago,
            monto_pagado
        FROM cuota_transac_tarjeta_cliente
        WHERE nro_tarjeta = p_tarjeta AND nro_transaccion = p_nro_transac
        AND EXTRACT(YEAR FROM fecha_pago) = EXTRACT(YEAR FROM SYSDATE) - 1;

    r_balance_anual balance_anual_detalle_transac%ROWTYPE; -- Registro para el INSERT
    
    -- Otros valores necesarios para tabla final
    v_run_cliente VARCHAR(12);
    v_nombre_tptran VARCHAR2(50);
    v_deuda_cuota NUMBER (10);
    v_ultima_cuota DATE;
    v_deuda_total_restante NUMBER(10);

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE balance_anual_detalle_transac';

    FOR r_transac IN c_transac LOOP

        -- Consulta por rut cliente
        SELECT cli.numrun||'-'||cli.dvrun
            INTO v_run_cliente
            FROM tarjeta_cliente tc
            JOIN cliente cli ON cli.numrun = tc.numrun
            WHERE nro_tarjeta = r_transac.nro_tarjeta;
            
        -- Consulta por tipo de transaccion (nombre)
        SELECT nombre_tptran_tarjeta 
            INTO v_nombre_tptran
            FROM tipo_transaccion_tarjeta
            WHERE cod_tptran_tarjeta = r_transac.cod_tptran_tarjeta;
    
        FOR r_cuotas IN c_cuotas(r_transac.nro_tarjeta, r_transac.nro_transaccion) LOOP
        
            -- Consulta por vencimiento de la ultima cuota de transaccion
            SELECT MAX(fecha_venc_cuota)
                INTO v_ultima_cuota
                FROM cuota_transac_tarjeta_cliente
                WHERE nro_tarjeta = r_transac.nro_tarjeta
                AND nro_transaccion = r_transac.nro_transaccion;
            
            -- Diferencia entre valor de la cuota y monto pagado por esa cuota
            v_deuda_cuota := r_cuotas.valor_cuota - r_cuotas.monto_pagado;
            
            /*  Calcula la deuda restante, con el monto total adeudado menos valor de la cuota multiplicado por el numero de la cuota
                por lo tanto el valor siempre va disminuyendo */
            v_deuda_total_restante := r_transac.monto_total_transaccion - r_cuotas.nro_cuota * r_cuotas.valor_cuota;
            
            -- Poblado de registro
            r_balance_anual.mes_anno := r_cuotas.mes_anno;
            r_balance_anual.run_cliente := v_run_cliente;
            r_balance_anual.nro_tarjeta := r_transac.nro_tarjeta;
            r_balance_anual.fecha_transaccion := r_transac.fecha_transaccion;
            r_balance_anual.nro_transaccion := r_transac.nro_transaccion;
            r_balance_anual.tipo_transaccion := v_nombre_tptran;
            r_balance_anual.monto_total_transaccion := r_transac.monto_total_transaccion;
            r_balance_anual.fecha_venc_ult_cuota := v_ultima_cuota;
            r_balance_anual.nro_cuota_pagada := r_cuotas.nro_cuota||'/'||r_transac.total_cuotas_transaccion;
            r_balance_anual.fecha_venc_cuota := r_cuotas.fecha_venc_cuota;
            r_balance_anual.valor_cuota := r_cuotas.valor_cuota;
            r_balance_anual.fecha_pago := r_cuotas.fecha_pago;
            r_balance_anual.monto_pagado := r_cuotas.monto_pagado;
            r_balance_anual.deuda_pago_cuota := v_deuda_cuota;
            r_balance_anual.deuda_por_pagar := v_deuda_total_restante + v_deuda_cuota; -- se considera deuda de cuota
            
            INSERT INTO balance_anual_detalle_transac VALUES r_balance_anual;
        
        END LOOP;

    END LOOP;

END;