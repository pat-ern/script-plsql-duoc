SET SERVEROUTPUT ON


VAR b_valor_uf              NUMBER                              
VAR b_monto_colacion        NUMBER
VAR b_monto_movilizacion    NUMBER

EXEC :b_valor_uf            := 28608
EXEC :b_monto_colacion      := 60000
EXEC :b_monto_movilizacion  := 40000

DECLARE

    v_idpago            calculo_pago_mes.idpago%TYPE := 2;
    v_idchofer          calculo_pago_mes.idchofer%TYPE;
    v_rut               calculo_pago_mes.rut%TYPE := '11610873-9';
    v_nombrecompleto    calculo_pago_mes.nombrecompleto%TYPE;

    v_bono_antiguedad   calculo_pago_mes.bono_antiguedad%TYPE;
    v_bono_cargas       calculo_pago_mes.bono_cargas%TYPE;
    v_cant_viajes_mes   calculo_pago_mes.cant_viajes_mes%TYPE;
    v_monto_viajes      calculo_pago_mes.monto_viajes%TYPE;
    v_salud             calculo_pago_mes.salud%TYPE;
    v_afp               calculo_pago_mes.afp%TYPE;
    v_total_imponible   calculo_pago_mes.total_imponible%TYPE;
    v_total_noimponible calculo_pago_mes.total_noimponible%TYPE;
    v_total_haberes     calculo_pago_mes.total_haberes%TYPE;
    v_total_descuentos  calculo_pago_mes.total_descuentos%TYPE;
    v_liquido           calculo_pago_mes.liquido%TYPE;

BEGIN

    SELECT cho.idchofer,
            cho.rutchofer,
            cho.nombre||' '||cho.apellido_p||' '||cho.apellido_m,
            TRUNC(MONTHS_BETWEEN(SYSDATE, cho.fecha_contrato)/12) antiguedad,
            COUNT(car.idchofer) cargas
            --COUNT(via.patente)
        FROM chofer cho 
        JOIN cargas_familiares car ON car.idchofer = cho.idchofer 
        JOIN bus bs ON bs.idchofer = cho.idchofer
        --JOIN viajes via ON via.patente = bs.patente
        --WHERE rutchofer = '11610873-9'
        GROUP BY cho.idchofer,
            cho.rutchofer,
            cho.nombre||' '||cho.apellido_p||' '||cho.apellido_m,
            TRUNC(MONTHS_BETWEEN(SYSDATE, cho.fecha_contrato)/12)

    

    INSERT INTO calculo_pago_mes
        VALUES (v_idpago,
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
            v_liquido)

END;