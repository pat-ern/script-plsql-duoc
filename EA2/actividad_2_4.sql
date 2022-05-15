-- CASO 1 (FALTA ORDENAR EL CURSOR)

SET SERVEROUTPUT ON

DECLARE

CURSOR c_socios IS
    SELECT nro_socio, 
        numrun, dvrun,
        pnombre, snombre, apmaterno, appaterno,
        fecha_nacimiento,
        cod_provincia,
        cod_region
    FROM socio
    ORDER BY nro_socio;
        
    rt_usuario_clave usuario_clave%ROWTYPE;
    
    v_nom_provincia provincia.nombre_provincia%TYPE;
    v_factor NUMBER(10) := 0;
    v_edad NUMBER(3);
    v_mes NUMBER(2) := EXTRACT(MONTH FROM SYSDATE);
    v_total_cuotas NUMBER(2);
    
    v_error_code NUMBER(10);
    v_error_msg VARCHAR2(200);

BEGIN

    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_error';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_error';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE usuario_clave';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE error_proceso';  

    FOR i IN c_socios LOOP

        -- Poblado en registro de valores disponibles
        rt_usuario_clave.nro_socio := i.nro_socio;
        rt_usuario_clave.numrun_socio := i.numrun||'-'||i.dvrun;
        rt_usuario_clave.nombre_socio := i.pnombre||' '||i.snombre||' '||i.appaterno||' '||i.apmaterno;

        -- Obtencion de nombre provincia para elemento en nombre usuario
        SELECT nombre_provincia
        INTO v_nom_provincia
        FROM provincia
        WHERE cod_provincia = i.cod_provincia
        AND cod_region = i.cod_region;

        -- Modificacion de string nombre de provincia segun region
        IF i.cod_region BETWEEN 1 AND 4 THEN
            v_nom_provincia := SUBSTR(v_nom_provincia, 2, 2);
        ELSIF i.cod_region BETWEEN 5 AND 9 THEN
            v_nom_provincia := SUBSTR(v_nom_provincia, -2, 2);
        ELSIF i.cod_region BETWEEN 10 AND 13 THEN
            v_nom_provincia := SUBSTR(v_nom_provincia, 1, 1)||SUBSTR(v_nom_provincia, -1, 1);
        ELSIF i.cod_region BETWEEN 14 AND 16 THEN
            v_nom_provincia := SUBSTR(v_nom_provincia, 1, 2);
        END IF;

        -- Calculo de factor segun edad
        v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, i.fecha_nacimiento)/12);

        IF v_edad >= 60 THEN
        
            BEGIN
                SELECT factor
                INTO v_factor
                FROM tramo_3ra_edad
                WHERE v_edad BETWEEN rango_edad_min AND rango_edad_max;
                v_factor := v_factor * v_mes;
            
            EXCEPTION
                WHEN OTHERS THEN
                    v_error_msg := SQLERRM;
                    v_factor := 0;
                    INSERT INTO error_proceso (correl_error, 
                                            sentencia_error, 
                                            descrip_error)
                        VALUES (seq_error.NEXTVAL,
                            'Error al obtener factor para los 64 años del socio nro: '||i.nro_socio,
                            v_error_msg);
            END;

        ELSE v_factor := SUBSTR(v_edad, 1, 1) * v_mes;
        END IF;

        -- Creacion nombre usuario
        rt_usuario_clave.nombre_usuario :=
        INITCAP(SUBSTR(i.pnombre, 0, 3))||LENGTH(i.appaterno)||'*'||
        SUBSTR(i.numrun, -2, 2)||v_nom_provincia||'.'||v_factor;

        -- Obtencion numero de cuotas para elemento en clave usuario
        BEGIN
            SELECT total_cuotas_credito
                INTO v_total_cuotas
                FROM credito_socio
                WHERE nro_socio = i.nro_socio;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_error_msg := SQLERRM;
                v_total_cuotas := 0;
                INSERT INTO error_proceso (correl_error, 
                                        sentencia_error, 
                                        descrip_error)
                    VALUES (seq_error.NEXTVAL,
                        'Error al obtener total cuotas ultimo credito para el socio nro: '||i.nro_socio,
                        v_error_msg);
        END;
        
        -- Creacion de clave usuario
        rt_usuario_clave.clave_usuario := 
        UPPER(SUBSTR(i.appaterno, -3, 3))||(EXTRACT(YEAR FROM i.fecha_nacimiento)+2)||
        i.nro_socio*3||TO_CHAR(SYSDATE, 'MMYYYY')||'*'||v_total_cuotas/2;

        -- Poblado de tabla usuario_clave
        INSERT INTO usuario_clave VALUES rt_usuario_clave;

    END LOOP;

END;

-- CASO 2

ROLLBACK;

VAR b_cinco_uf NUMBER
VAR b_ipc NUMBER
EXEC :b_cinco_uf := 101299
EXEC :b_ipc := 2.73

DECLARE

    CURSOR c_prod_inv IS
        SELECT nro_solic_prod, 
            nro_socio,
            fecha_solic_prod, 
            ahorro_minimo_mensual, 
            dia_pago_mensual, 
            monto_total_ahorrado, 
            cod_prod_inv
        FROM producto_inversion_socio
        ORDER BY nro_socio, nro_solic_prod;

    v_cant_prod NUMBER(2);
    v_reajuste_base NUMBER(8);
    v_reajuste_adicional NUMBER(8);
    v_reajuste_total NUMBER(8);
    
    TOPE_UF_EXCEDIDO EXCEPTION;

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE error_proceso';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_error';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_error';
    
    FOR i IN c_prod_inv LOOP
    
        SELECT COUNT(nro_solic_prod)
        INTO v_cant_prod
        FROM producto_inversion_socio
        WHERE nro_socio = i.nro_socio;

        -- Calculo reajuste base general segun IPC anual
        v_reajuste_base := ROUND(i.monto_total_ahorrado * :b_ipc/100);
        
        -- Reajuste adicional segun cantidad de productos
        IF v_cant_prod > 1 THEN
            v_reajuste_adicional := ROUND(i.monto_total_ahorrado * v_cant_prod/100);
        ELSIF v_cant_prod = 1 AND i.monto_total_ahorrado > 1000000 THEN
            v_reajuste_adicional := ROUND(i.monto_total_ahorrado * v_cant_prod/100);
        ELSE v_reajuste_adicional := 0;
        END IF;
        
        v_reajuste_total := v_reajuste_base + v_reajuste_adicional;
        
        BEGIN
        
            IF v_reajuste_total > :b_cinco_uf THEN
                RAISE TOPE_UF_EXCEDIDO;
            END IF;
        
        EXCEPTION 
            WHEN TOPE_UF_EXCEDIDO THEN
                INSERT INTO error_proceso 
                    VALUES (seq_error.NEXTVAL, 
                        'Tope reajuste de 5 UF', 
                        'Socio N°: '||i.nro_socio||'. Solicitud producto N°: '||
                        i.nro_solic_prod||'. Valor reajuste calculado: '||v_reajuste_total);
                v_reajuste_total := :b_cinco_uf;
        END;
        
        UPDATE producto_inversion_socio SET 
            nro_solic_prod = i.nro_solic_prod,
            nro_socio = i.nro_socio,
            fecha_solic_prod = i.fecha_solic_prod,
            ahorro_minimo_mensual = i.ahorro_minimo_mensual,
            dia_pago_mensual = i.dia_pago_mensual,
            monto_total_ahorrado = i.monto_total_ahorrado + v_reajuste_total,
            cod_prod_inv = i.cod_prod_inv
            WHERE nro_socio = i.nro_socio AND nro_solic_prod = i.nro_solic_prod;

    END LOOP;

END;

-- CASO 3

SET SERVEROUTPUT ON

DECLARE
    
    CURSOR c_cuota_socio  IS
    SELECT s.nro_socio,
        s.numrun||'-'||s.dvrun run_socio,
        cs.nro_solic_credito,
        c.nombre_credito tipo_credito,
        cs.monto_total_credito,
        cs.total_cuotas_credito nro_total_cuotas,
        ccs.nro_cuota nro_cuota_mes,
        ccs.valor_cuota valor_cuota_mes,
        ccs.fecha_venc_cuota fecha_venc_cuota_mes
    FROM socio s
    JOIN credito_socio cs ON cs.nro_socio = s.nro_socio
    JOIN credito c ON c.cod_credito = cs.cod_credito
    JOIN cuota_credito_socio ccs ON ccs.nro_solic_credito = cs.nro_solic_credito
    WHERE TO_CHAR(ccs.fecha_venc_cuota, 'MMYYYY') = TO_CHAR(SYSDATE, 'MMYYYY')
    ORDER BY ccs.fecha_venc_cuota, s.nro_socio;
    
    rt_pag_mens_cred pago_mensual_credito%ROWTYPE;
    
    v_saldo_mes_ant cuota_credito_socio.saldo_por_pagar%TYPE;
    v_atraso_mes_ant NUMBER(2);
    v_porc_multa multa_mora.porc_multa%TYPE;
    v_edad NUMBER(3);
    v_error_mens VARCHAR2(200);
    v_multa NUMBER(7);
    v_rebaja_trc_edad NUMBER(6);
    
BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE pago_mensual_credito';

    FOR i IN c_cuota_socio LOOP
    
        -- Obtencion de salgo por pagar mes anterior y dias de atraso
        SELECT saldo_por_pagar, 
            fecha_pago_cuota-fecha_venc_cuota
            INTO v_saldo_mes_ant,
                v_atraso_mes_ant
            FROM cuota_credito_socio
            WHERE nro_solic_credito = i.nro_solic_credito
            AND TO_CHAR(fecha_venc_cuota, 'MMYYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MMYYYY');
        
        -- Calculo multa
        IF v_atraso_mes_ant > 0 THEN
            -- Bloque porcentaje multa
            BEGIN
                -- Obtencion de porcentaje de multa
                SELECT porc_multa
                    INTO v_porc_multa
                    FROM multa_mora
                    WHERE v_atraso_mes_ant BETWEEN tramo_dia_min_atraso AND tramo_dia_max_atraso;
                
                v_multa := ROUND(i.monto_total_credito * v_porc_multa/100);
            
            EXCEPTION
                WHEN OTHERS THEN
                v_error_mens := SQLERRM;
                INSERT INTO error_proceso (correl_error, sentencia_error, descrip_error)
                    VALUES (seq_error.NEXTVAL, 'Error al obtener porcentaje de multa. Dias de atraso: '||
                    v_atraso_mes_ant||' Solic de credito nro: '||i.nro_solic_credito, v_error_mens);
                v_multa := 0;
            END;
        ELSIF v_atraso_mes_ant <= 0 THEN
            v_atraso_mes_ant := 0;
            v_multa := 0;
        END IF;
        
        -- Obtencion edad 
        SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12)
        INTO v_edad
        FROM socio
        WHERE nro_socio = i.nro_socio;
        
        -- Calculo rebaja cuota del mes con 65 años o mas
        IF v_edad >= 65 THEN
            v_rebaja_trc_edad := i.valor_cuota_mes*5/100;
        ELSE v_rebaja_trc_edad := 0;
        END IF;
        
        -- Poblado de registro de tabla con valores
        rt_pag_mens_cred.fecha_proceso := TO_CHAR(SYSDATE, 'MMYYYY');
        rt_pag_mens_cred.nro_socio := i.nro_socio;
        rt_pag_mens_cred.run_socio := i.run_socio;
        rt_pag_mens_cred.nro_solic_credito := i.nro_solic_credito;
        rt_pag_mens_cred.tipo_credito := i.tipo_credito;
        rt_pag_mens_cred.monto_total_credito := i.monto_total_credito;
        rt_pag_mens_cred.nro_total_cuotas := i.nro_total_cuotas;
        rt_pag_mens_cred.nro_cuota_mes := i.nro_cuota_mes;
        rt_pag_mens_cred.valor_cuota_mes := i.valor_cuota_mes;
        rt_pag_mens_cred.fecha_venc_cuota_mes := i.fecha_venc_cuota_mes;
        rt_pag_mens_cred.saldo_pago_mes_ant := v_saldo_mes_ant;
        rt_pag_mens_cred.dias_atraso_pago_mes_ant := v_atraso_mes_ant;
        rt_pag_mens_cred.multa_atraso_pago_mes_ant := v_multa;
        rt_pag_mens_cred.valor_rebajar_65_annos := v_rebaja_trc_edad;
        
        --Totalizador
        rt_pag_mens_cred.valor_total_cuota_mes := i.valor_cuota_mes + v_saldo_mes_ant + v_multa - v_rebaja_trc_edad;
        
        -- Insercion de fila
        INSERT INTO pago_mensual_credito VALUES rt_pag_mens_cred;
        
    END LOOP;

END;