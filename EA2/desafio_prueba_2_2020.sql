SET SERVEROUTPUT ON

VAR b_hora_extra NUMBER
EXEC :b_hora_extra := 3000

VAR b_colacion NUMBER
EXEC :b_colacion := 60000

VAR b_movilizacion NUMBER
EXEC :b_movilizacion := 40000

DECLARE

    TYPE t_varray_desc IS VARRAY(2) OF
        NUMBER(2);
    
    va_desc t_varray_desc := t_varray_desc(12, 7);
    
    CURSOR c_ejecutivos IS 
        (SELECT cod_ejecutivo, 
            EXTRACT (MONTH FROM SYSDATE)||EXTRACT (YEAR FROM SYSDATE) fecha_pago,
            sueldo_base_pactado,
            nota_evaluacion
            FROM ejecutivo);
            
    CURSOR c_horas_ex(p_cod_ej NUMBER) IS
        (SELECT cant_hora, fecha
            FROM hora_extra
            WHERE cod_ejecutivo = p_cod_ej);
            
    v_horas NUMBER(2);
    v_valor_horas NUMBER(5);
    v_bono_hora bono_hora_extra.bono%TYPE;
    
    rt_liq liquidacion%ROWTYPE;
    
    v_bono_evaluacion NUMBER(6);
    
    v_error_msg VARCHAR(200);
    v_error_code VARCHAR(10);
    
BEGIN

    EXECUTE IMMEDIATE 'DROP SEQUENCE SQ_ERROR_GASMAX';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE SQ_ERROR_GASMAX
                         START WITH     1
                         INCREMENT BY   1
                         NOCACHE
                         NOCYCLE';    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE liquidacion';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE registro_error';

    FOR i IN c_ejecutivos LOOP
    
        rt_liq.cod_ejecutivo := i.cod_ejecutivo;
        rt_liq.fecha_pago := i.fecha_pago;
        rt_liq.sueldo_pactado := i.sueldo_base_pactado;
        
        -- HORAS EXTRAS (Cantidad y montos)

        -- Se reestablecen las variables
        v_horas := 0;
        v_valor_horas := 0;
        v_bono_hora := 0;
        v_bono_evaluacion :=0;

        -- Ciclo para calcular cantidad de horas segun dia de la semana
        FOR e IN c_horas_ex(i.cod_ejecutivo) LOOP
           
            IF TO_CHAR(e.fecha, 'D') IN(6, 7) THEN -- Si la hora fue realizada dia 6 o 7 vale x 2
                e.cant_hora := e.cant_hora*2; 
            END IF;
            -- En cada iteracion de este LOOP se incrementa la cantidad de horas
            v_horas := v_horas + e.cant_hora;
            
        END LOOP;
        
        v_valor_horas := :b_hora_extra * v_horas;

        -- Calculo bono x horas extra
        <<blq_cal_hrs>>

        DECLARE
            v_error_bloque VARCHAR(200) := 'Error calculo bono evaluacion para ejecutivo: ';

        BEGIN
            SELECT bono
            INTO v_bono_hora
            FROM bono_hora_extra
            WHERE v_horas BETWEEN cant_min AND cant_max;
        
        EXCEPTION 
            WHEN OTHERS THEN   
                v_error_msg := SQLERRM;
                v_error_code := SQLCODE;
                INSERT INTO registro_error
                    VALUES (sq_error_gasmax.NEXTVAL, 
                        v_error_code, 
                        blq_cal_hrs.v_error_bloque||rt_liq.cod_ejecutivo, 
                        v_error_msg); 
        END;
        
        -- Calculo bono x evaluacion
        <<blq_cal_eva>>
        
        DECLARE
            v_error_bloque VARCHAR(200) := 'Error calculo bono evaluacion para ejecutivo: ';

        BEGIN
            SELECT bono 
            INTO v_bono_evaluacion
            FROM bono_evaluacion
            WHERE i.nota_evaluacion BETWEEN nota_min AND nota_max;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_error_msg := SQLERRM;
                v_error_code := SQLCODE;
                INSERT INTO registro_error
                    VALUES (sq_error_gasmax.NEXTVAL, 
                        v_error_code, 
                        blq_cal_eva.v_error_bloque||rt_liq.cod_ejecutivo, 
                        v_error_msg);   
        END;
        
        --Cantidad horas extras
        rt_liq.cant_hora_extra := v_horas;
        --Valor total horas
        rt_liq.valor_total_hora := v_valor_horas + v_bono_hora;
        --Colacion
        rt_liq.colacion := :b_colacion;
        --Movilizacion
        rt_liq.movilizacion := :b_movilizacion;
        --Total imponible
        rt_liq.total_imponible := rt_liq.sueldo_pactado + rt_liq.valor_total_hora + v_bono_evaluacion;
        --AFP
        rt_liq.afp := ROUND(rt_liq.total_imponible * va_desc(1)/100);
        --Salud
        rt_liq.salud := ROUND(rt_liq.total_imponible * va_desc(2)/100);
        --Descuento
        rt_liq.descuento := rt_liq.afp + rt_liq.salud;
        --Liquido
        rt_liq.liquido := rt_liq.total_imponible + :b_colacion + :b_movilizacion - rt_liq.descuento;
        
        INSERT INTO liquidacion VALUES rt_liq;
    
    END LOOP;

END;
