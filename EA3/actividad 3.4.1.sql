-- TRIGGER

create or replace TRIGGER tr_actualizar_saldo 
AFTER INSERT on transaccion_tarjeta_cliente
FOR EACH ROW
BEGIN
    IF (:NEW.cod_tptran_tarjeta IN(101, 102) ) THEN
        UPDATE tarjeta_cliente
        SET cupo_disp_compra = cupo_disp_compra - :NEW.monto_total_transaccion
        WHERE nro_tarjeta = :NEW.nro_tarjeta;
    ELSIF (:NEW.cod_tptran_tarjeta = 103) THEN
        UPDATE tarjeta_cliente
        SET cupo_disp_sp_avance = cupo_disp_sp_avance - :NEW.monto_total_transaccion
        WHERE nro_tarjeta = :NEW.nro_tarjeta;
    END IF;
END;

-- TRANSACCION 1 (tptran = 101)

INSERT INTO transaccion_tarjeta_cliente 
        (nro_tarjeta, 
        nro_transaccion, 
        fecha_transaccion, 
        monto_transaccion, 
        total_cuotas_transaccion, 
        monto_total_transaccion, 
        cod_tptran_tarjeta)
        
    VALUES 
        (29320393064, 
        1001, 
        '04/05/'||TO_CHAR(SYSDATE, 'YYYY'), 
        800000, 
        24, 
        845000, 
        101);

-- TRANSACCION 2 (tptran = 101)

INSERT INTO transaccion_tarjeta_cliente 
        (nro_tarjeta, 
        nro_transaccion, 
        fecha_transaccion, 
        monto_transaccion, 
        total_cuotas_transaccion, 
        monto_total_transaccion, 
        cod_tptran_tarjeta)
        
    VALUES 
        (29320393064, 
        1002, 
        '25/05/'||TO_CHAR(SYSDATE, 'YYYY'), 
        86500, 
        6, 
        90325, 
        101);
    
-- TRANSACCION 3 (tptran = 103)

INSERT INTO transaccion_tarjeta_cliente 
        (nro_tarjeta, 
        nro_transaccion, 
        fecha_transaccion, 
        monto_transaccion, 
        total_cuotas_transaccion, 
        monto_total_transaccion, 
        cod_tptran_tarjeta)
        
    VALUES 
        (29320393064, 
        1003, 
        '25/05/'||TO_CHAR(SYSDATE, 'YYYY'), 
        485900, 
        12, 
        544490, 
        103);

-- TRANSACCION 4 (tptran = 102)

INSERT INTO transaccion_tarjeta_cliente 
        (nro_tarjeta, 
        nro_transaccion, 
        fecha_transaccion, 
        monto_transaccion, 
        total_cuotas_transaccion, 
        monto_total_transaccion, 
        cod_tptran_tarjeta)
        
    VALUES 
        (28418181488, 
        1002, 
        '15/05/'||TO_CHAR(SYSDATE, 'YYYY'), 
        200000, 
        10, 
        215000, 
        102);

--

ROLLBACK;