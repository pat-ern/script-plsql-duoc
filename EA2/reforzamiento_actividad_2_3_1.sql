-- CASO 1


VAR b_tramo_1 NUMBER
VAR b_tramo_2 NUMBER
VAR b_tramo_3 NUMBER
VAR b_tramo_4 NUMBER

EXEC b_tramo_1 := 500000
EXEC b_tramo_2 := 700000
EXEC b_tramo_3 := 700001
EXEC b_tramo_4 := 900000

DECLARE

    CURSOR cur_meses_transac IS
        SELECT DISTINCT TO_CHAR(fecha_transaccion, 'MMYYYY') mes_anno
        FROM transaccion_tarjeta_cliente
        WHERE EXTRACT(YEAR FROM fecha_transaccion)=EXTRACT(YEAR FROM SYSDATE)-1
        ORDER BY mes_anno;

    CURSOR cur_transc_clientes(p_mes_anno_tran VARCHAR2) IS
        SELECT c.numrun, 
            c.dvrun, c.cod_tipo_cliente,
            ttc.nro_tarjeta,
            ttc.cod_tptran_tarjeta,
            ttc.nro_transaccion,
            ttc.fecha_transaccion,
            ttc.monto_transaccion,
            ttt.nombre_tptran_tarjeta   
        FROM cliente c JOIn tarjeta_cliente tc
            ON c.numrun=tc.numrun
            JOIN transaccion_tarjeta_cliente ttc
            ON tc.nro_tarjeta=ttc.nro_tarjeta
            JOIN tipo_transaccion_tarjeta ttt
            ON ttc.cod_tptran_tarjeta=ttt.cod_tptran_tarjeta 
        WHERE TO_CHAR(ttc.fecha_transaccion, 'MMYYY' ) = p_mes_anno_tran
        ORDER BY ttc.fecha_transaccion;
        

        
    TYPE t_tipo_varray_puntos IS VARRAY(4) 
        OF NUMBER(3);
        
    va_puntos t_tipo_varray_puntos := (250,300,550,700);
    
    v_puntos_nor NUMBER(8);
    v_puntos_extras NUMBER(8);
    v_tot_puntos NUMBER(8);   
    
    v_monto_tot_com NUMBER(8);
    v_tot_ptos_com NUMBER(8);
    v_monto_tot_ava NUMBER(8);
    v_tot_ptos_ava NUMBER(8);
    v_monto_tot_sava NUMBER(8);
    v_tot_ptos_sava NUMBER(8);
    
    
BEGIN

    EXECUTE IMMEDIATE ('TRUNCATE TABLE detalle_puntos_tarjeta_catb'):
    EXECUTE IMMEDIATE ('TRUNCATE TABLE resumen_puntos_tarjeta_catb'):
    
    FOR reg_meses_transac IN cur_meses_transac LOOP
    
        v_monto_tot_com := 0;
        v_tot_ptos_com := 0;
        v_monto_tot_ava := 0;
        v_tot_ptos_ava := 0;
        v_monto_tot_sava := 0;
        v_tot_ptos_sava := 0;
    
        FOR reg_transacciones IN cur_transc_clientes(reg_meses_transac.mes_anno) LOOP
        
            v_puntos_extras:= 0;
            v_puntos_normales := TRUNC(reg_transacciones.monto_transaccion/100000)*varray_puntos(1);
            
            IF reg_transacciones.cod_tipo_cliente IN (30,40) THEN
            
                IF reg_transacciones.monto_transaccion BETWEEN :b_tramo_1 AND :b_tramo_2 THEN
                    v_puntos_extras := TRUNC(reg_transacciones.monto_transaccion/100000)*varray_puntos(2);
                ELSIF reg_transacciones.monto_transaccion BETWEEN :b_tramo_3 AND :b_tramo_4 THEN
                    v_puntos_extras := TRUNC(reg_transacciones.monto_transaccion/100000)*varray_puntos(3);
                ELSIF reg_transacciones.monto_transaccion > :b_tramo_4 THEN
                    v_puntos_extras := TRUNC(reg_transacciones.monto_transaccion/100000)*varray_puntos(4);    
                END IF;
                
            END IF;
            
            v_tot_puntos := v_puntos_nor + v_puntos_extras;
            
            INSERT INTO detale_puntos_tarjeta_catb 
                VALUES reg_transacciones.numrun,
                    reg_transacciones.dvrun,
                    reg_transacciones.nro_tarjeta,
                    reg_transacciones.nro_transaccion,
                    reg_transacciones.fecha_transaccion,
                    reg_transacciones.nombre_tptran_tarjeta,
                    reg_transacciones.monto_transaccion,
                    v_tot_puntos,
                    
            IF reg_transacciones.nombre_tptran_tarjeta = 101 THEN
                v_monto_tot_com := v_monto_tot_com + reg_transacciones.monto_transaccion;
                v_tot_ptos_com := v_tot_ptos_com + v_tot_puntos;
            ELSIF reg_transacciones.nombre_tptran_tarjeta = 101 THEN
                v_monto_tot_ava := v_monto_tot_ava + reg_transacciones.monto_transaccion;
                v_tot_ptos_ava := v_tot_ptos_ava + v_tot_puntos;
            ELSE reg_transacciones.nombre_tptran_tarjeta = 101 THEN
                v_monto_tot_com := v_monto_tot_com + reg_transacciones.monto_transaccion;
                v_tot_ptos_com := v_tot_ptos_com + v_tot_puntos; 
            
        END LOOP;
        
        INSERT INTO resumen_puntos_tarjeta_catb 
            VALUES (reg_meses_transac.mes_anno,
            v_monto_tot_com,
            v_tot_ptos_com,
            v_monto_tot_ava,
            v_monto_tot_sava,
            v_tot_ptos_sava);
        
    END LOOP;

END;