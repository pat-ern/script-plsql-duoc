SET SERVEROUTPUT ON

TRUNCATE TABLE calculo_pago_mes;

--VARIABLES BIND
VAR b_valor_uf              NUMBER                              
VAR b_monto_colacion        NUMBER
VAR b_monto_movilizacion    NUMBER
EXEC :b_valor_uf            := 28608
EXEC :b_monto_colacion      := 60000
EXEC :b_monto_movilizacion  := 40000

DECLARE

    --OBTENIDAS DE CONSULTAS
    v_idchofer          calculo_pago_mes.idchofer%TYPE;
    v_rut               calculo_pago_mes.rut%TYPE;
    v_nombrecompleto    calculo_pago_mes.nombrecompleto%TYPE;
    v_sueldo_base       chofer.sueldo_base%TYPE;
    v_porc_bono_ant     bono_antiguedad.porc%TYPE;
    v_cant_cargas       NUMBER(2);
    v_cant_viajes_mes   calculo_pago_mes.cant_viajes_mes%TYPE;
    v_porc_uf           salud.uf%TYPE;

    --OBTENIDAS DE CALCULOS
    v_bono_antiguedad   calculo_pago_mes.bono_antiguedad%TYPE;
    v_bono_cargas       calculo_pago_mes.bono_cargas%TYPE;
    v_monto_viajes      calculo_pago_mes.monto_viajes%TYPE;
    v_total_imponible   calculo_pago_mes.total_imponible%TYPE;
    v_total_noimponible calculo_pago_mes.total_noimponible%TYPE;
    v_total_haberes     calculo_pago_mes.total_haberes%TYPE;
    v_salud             calculo_pago_mes.salud%TYPE;
    v_afp               calculo_pago_mes.afp%TYPE;
    v_total_descuentos  calculo_pago_mes.total_descuentos%TYPE;
    v_liquido           calculo_pago_mes.liquido%TYPE;

BEGIN
    
    FOR i IN (SELECT idchofer FROM chofer) LOOP --ITERACION EN SENTENCIA (CURSOR IMPLICITO)
    
        -- IDCHOFER, RUT, NOMBRES, SUELD, PORC_BONO_ANTIGUEDAD, CANT_CARGAS
        SELECT c.idchofer,
                c.rutchofer,
                c.nombre||' '||c.apellido_p||' '||c.apellido_m,
                c.sueldo_base,
                bo.porc,
                COUNT(car.idchofer)
            INTO v_idchofer,
               v_rut,
               v_nombrecompleto,
               v_sueldo_base,
               v_porc_bono_ant,
               v_cant_cargas
            FROM chofer c 
            LEFT JOIN cargas_familiares car ON car.idchofer = c.idchofer 
            LEFT JOIN bus bs ON bs.idchofer = c.idchofer
            JOIN bono_antiguedad bo 
            ON TRUNC(MONTHS_BETWEEN(SYSDATE, c.fecha_contrato)/12) BETWEEN bo.anno_inf AND bo.anno_sup
            WHERE c.idchofer = i.idchofer
            GROUP BY c.idchofer,
                c.rutchofer,
                c.nombre||' '||c.apellido_p||' '||c.apellido_m,
                c.sueldo_base,
                bo.porc;
        
        -- CANT_VIAJES Y UF_SALUD
        SELECT COUNT(v.patente),
            s.uf
            INTO v_cant_viajes_mes,
                v_porc_uf
            FROM chofer c 
            LEFT JOIN bus b ON b.idchofer = c.idchofer
            LEFT JOIN viajes v ON v.patente = b.patente
            LEFT JOIN salud s ON s.idsalud = c.idsalud
            WHERE c.idchofer = i.idchofer
            GROUP BY c.idchofer, s.uf;
        
        -- BONO ANTIGUEDAD
        v_bono_antiguedad := TRUNC(v_sueldo_base * v_porc_bono_ant/100);

        -- BONO CARGAS
        v_bono_cargas := 
            CASE 
                WHEN v_cant_cargas = 1 THEN 20000
                WHEN v_cant_cargas = 2 THEN 30000
                WHEN v_cant_cargas BETWEEN 3 AND 6 THEN 50000
                ELSE 0
            END;
        
        -- MONTO VIAJES
        v_monto_viajes := 
            CASE 
                WHEN v_cant_viajes_mes BETWEEN 1 AND 3 THEN 25000
                WHEN v_cant_viajes_mes BETWEEN 4 AND 6 THEN 30000
                WHEN v_cant_viajes_mes > 6 THEN 60000
                ELSE 0
            END;
        
        -- TOTAL IMPONIBLE
        v_total_imponible := v_sueldo_base + v_bono_antiguedad + v_monto_viajes;

        -- TOTAL NO IMPONIBLE
        v_total_noimponible := :b_monto_movilizacion + :b_monto_colacion + v_bono_cargas;

        -- TOTAL HABERES
        v_total_haberes := v_total_imponible + v_total_noimponible;
        
        -- DESCUENTO SALUD
        IF v_porc_uf = 0 THEN
            v_salud := TRUNC(v_total_imponible*7/100);
        ELSE 
            v_salud := TRUNC(v_porc_uf*:b_valor_uf);
        END IF;
        
        -- DESCUENTO AFP
        v_afp := TRUNC(v_total_imponible*12/100);

        -- TOTAL DESCUENTOS
        v_total_descuentos := v_salud + v_afp;

        -- LIQUIDO
        v_liquido := v_total_haberes - v_total_descuentos;
        
        INSERT INTO calculo_pago_mes
            VALUES (2,
                v_idchofer,
                v_rut,
                v_nombrecompleto,
                :b_monto_movilizacion,
                :b_monto_colacion,
                v_bono_antiguedad,
                v_bono_cargas,
                v_cant_viajes_mes,
                v_monto_viajes,
                v_salud,
                v_afp,
                v_total_imponible,
                v_total_noimponible,
                v_total_haberes,
                v_total_descuentos,
                v_liquido);
                
    END LOOP;

    COMMIT;
    
END;