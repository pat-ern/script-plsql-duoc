-- CASO 1

SET SERVEROUTPUT ON

VAR v_run NUMBER
EXEC :v_run := 11846972

DECLARE
    v_numrun_emp        empleado.numrun_emp%TYPE; 
    v_dvrun_emp         empleado.dvrun_emp%TYPE; 
    v_pnombre_emp       empleado.pnombre_emp%TYPE; 
    v_snombre_emp       empleado.snombre_emp%TYPE;
    v_appaterno_emp     empleado.appaterno_emp%TYPE;
    v_apmaterno_emp     empleado.apmaterno_emp%TYPE;
    v_sueldo_base       empleado.sueldo_base%TYPE;
    v_nombre_comuna     comuna.nombre_comuna%TYPE;
    v_porc_movil_normal  proy_movilizacion.porc_movil_normal%TYPE;
    v_valor_movil_normal proy_movilizacion.valor_movil_normal%TYPE;
    v_valor_movil_extra  proy_movilizacion.valor_movil_extra%TYPE;
    v_valor_total_movil  proy_movilizacion.valor_total_movil%TYPE;

BEGIN
    SELECT numrun_emp, 
        dvrun_emp, 
        pnombre_emp, 
        snombre_emp,
        appaterno_emp,
        apmaterno_emp,
        sueldo_base,
        nombre_comuna
		
        INTO v_numrun_emp, 
            v_dvrun_emp, 
            v_pnombre_emp, 
            v_snombre_emp,
            v_appaterno_emp,
            v_apmaterno_emp,
            v_sueldo_base,
            v_nombre_comuna
            
        FROM empleado NATURAL JOIN comuna
        WHERE numrun_emp = :v_run;
    
    v_porc_movil_normal := TRUNC(v_sueldo_base/100000);
    v_valor_movil_normal := v_sueldo_base * v_porc_movil_normal/100;
    
    IF v_nombre_comuna = 'María Pinto' THEN
        v_valor_movil_extra := 20000;
    END IF;
    
    IF v_nombre_comuna = 'Curacaví' THEN
        v_valor_movil_extra := 25000;
    END IF;
    
    IF v_nombre_comuna = 'Talagante' THEN
        v_valor_movil_extra := 30000;
    END IF;
    
    IF v_nombre_comuna = 'El Monte' THEN
        v_valor_movil_extra := 35000;
    END IF;
    
    IF v_nombre_comuna = 'Buin' THEN
        v_valor_movil_extra := 40000;
    END IF;
    
    v_valor_total_movil := v_valor_movil_normal + v_valor_movil_extra;
    
    INSERT INTO proy_movilizacion
    VALUES (EXTRACT (YEAR FROM SYSDATE), v_numrun_emp, v_dvrun_emp, v_pnombre_emp||' '||v_snombre_emp||' '||v_appaterno_emp||' '||v_apmaterno_emp, v_sueldo_base, v_porc_movil_normal, v_valor_movil_normal, v_valor_movil_extra, v_valor_total_movil);
    COMMIT;
    
END;
    

-- CASO 2

/*
12648200
11649964
12456905
12260812
12642309
*/

DECLARE

v_run empleado.numrun_emp%TYPE := &RUN;

v_mes_anno VARCHAR2(6);
v_numrun_emp NUMBER(8);
v_dvrun_emp CHAR;
v_nombre_empleado VARCHAR2(40);
v_nombre_usuario VARCHAR2(10); 
v_clave_usuario VARCHAR2(20);

BEGIN

	SELECT TO_CHAR(SYSDATE, 'MMYYYY'),
		numrun_emp,
		dvrun_emp,
		pnombre_emp||' '||snombre_emp||' '||appaterno_emp||' '||apmaterno_emp,
		SUBSTR(pnombre_emp, 0, 3)||LENGTH(pnombre_emp)||'*'||SUBSTR(TO_CHAR(sueldo_base, '9999999'), -1, 1)||dvrun_emp||ROUND(MONTHS_BETWEEN(SYSDATE, fecha_contrato)/12)||
		CASE WHEN ROUND(MONTHS_BETWEEN(SYSDATE, fecha_contrato)/12) < 10 THEN 'X'
			ELSE NULL
		END,
		SUBSTR(TO_CHAR(numrun_emp, '99999999'), 4, 1)||(EXTRACT (YEAR FROM fecha_nac))+2||SUBSTR(TO_CHAR(sueldo_base-1, '9999999'), -3, 3)||
		LOWER(CASE id_estado_civil 
			WHEN 10 THEN SUBSTR(appaterno_emp, 0, 2)
			WHEN 60 THEN SUBSTR(appaterno_emp, 0, 2)
			WHEN 20 THEN SUBSTR(appaterno_emp, 0, 1)||SUBSTR(appaterno_emp, -1, 1)
			WHEN 30 THEN SUBSTR(appaterno_emp, 0, 1)||SUBSTR(appaterno_emp, -1, 1)
			WHEN 40 THEN SUBSTR(appaterno_emp, -3, 2)
			WHEN 50 THEN SUBSTR(appaterno_emp, -2, 2)
		END)||
		TO_CHAR(SYSDATE, 'MMYYYY')||SUBSTR(nombre_comuna, 0, 1)
		
		INTO v_mes_anno, 
			v_numrun_emp, 
			v_dvrun_emp, 
			v_nombre_empleado, 
			v_nombre_usuario, 
			v_clave_usuario
		
		FROM empleado NATURAL JOIN comuna
		
		WHERE numrun_emp = v_run;

	INSERT INTO usuario_clave 
		VALUES (v_mes_anno, 
				v_numrun_emp, 
				v_dvrun_emp, 
				v_nombre_empleado, 
				v_nombre_usuario, 
				v_clave_usuario);
	COMMIT;
		
END;

-- CASO 3

/*
AHEW11
ASEZ11
BC1002
BT1002
VR1003
*/

SET SERVEROUTPUT ON

DECLARE

	v_anno_proceso          hist_arriendo_anual_camion.anno_proceso%TYPE := '&&ANNO_PROCESO';
	v_nro_patente           hist_arriendo_anual_camion.nro_patente%TYPE;
	v_valor_arriendo_dia    hist_arriendo_anual_camion.valor_arriendo_dia%TYPE;
	v_valor_garantia_dia    hist_arriendo_anual_camion.valor_garactia_dia%TYPE;
	v_total_veces_arrendado hist_arriendo_anual_camion.total_veces_arrendado%TYPE;

BEGIN

    SELECT nro_patente, 
		valor_arriendo_dia,
		valor_garantia_dia,
		count(nro_patente)
            
        INTO v_nro_patente,
			v_valor_arriendo_dia,
			v_valor_garantia_dia,
			v_total_veces_arrendado
                
        FROM camion NATURAL JOIN arriendo_camion
        
        WHERE nro_patente = '&PATENTE' 
        AND EXTRACT(YEAR FROM fecha_ini_arriendo) = &&ANNO_PROCESO-1
        
        GROUP BY nro_patente, 
                valor_arriendo_dia, 
                valor_garantia_dia; 
    
    INSERT INTO hist_arriendo_anual_camion
        VALUES (v_anno_proceso,
                v_nro_patente, 
                v_valor_arriendo_dia, 
                v_valor_garantia_dia, 
                v_total_veces_arrendado);
        
    IF v_total_veces_arrendado < 5 THEN
        v_valor_arriendo_dia := v_valor_arriendo_dia*0.775;
        v_valor_garantia_dia := v_valor_garantia_dia*0.775;
    END IF;
    
    UPDATE camion
        SET valor_arriendo_dia = v_valor_arriendo_dia,
            valor_garantia_dia = v_valor_garantia_dia
        WHERE nro_patente = v_nro_patente;
                
    COMMIT;            

END;

UNDEFINE ANNO_PROCESO
UNDEFINE PATENTE

-- CASO 4

/*
Pruebas:
AA1001
AHEW11
ASEZ11
BT1002
VR1003
*/

SET SERVEROUTPUT ON

DECLARE

    v_patente               VARCHAR(6) := '&PATENTE';
    v_multa_por_dia         NUMBER(5) := &MULTA_POR_DIA;
    
    v_anno_mes_proceso      multa_arriendo.anno_mes_proceso%TYPE;
    v_nro_patente           multa_arriendo.nro_patente%TYPE;
    v_fecha_ini_arriendo    multa_arriendo.fecha_ini_arriendo%TYPE;
    v_dias_solicitado       multa_arriendo.dias_solicitado%TYPE;
    v_fecha_devolucion      multa_arriendo.fecha_devolucion%TYPE;
    v_dias_atraso           multa_arriendo.dias_atraso%TYPE;
    v_valor_multa           multa_arriendo.valor_multa%TYPE;

BEGIN

    SELECT TO_CHAR(SYSDATE, 'YYYYMM'),
		nro_patente,
		fecha_ini_arriendo,
		dias_solicitados,
		fecha_devolucion
        
        INTO v_anno_mes_proceso,
            v_nro_patente,
            v_fecha_ini_arriendo,
            v_dias_solicitado,
            v_fecha_devolucion
        
        FROM arriendo_camion
        
        WHERE nro_patente = v_patente
        AND TO_CHAR(fecha_devolucion, 'MMYYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MMYYYY')
        AND fecha_ini_arriendo + dias_solicitados < fecha_devolucion;  
        
    v_dias_atraso := v_fecha_devolucion - (v_fecha_ini_arriendo + v_dias_solicitado);
    v_valor_multa := v_dias_atraso * v_multa_por_dia;
    
    INSERT INTO multa_arriendo
        VALUES (v_anno_mes_proceso,
                v_nro_patente,
                v_fecha_ini_arriendo,
                v_dias_solicitado,
                v_fecha_devolucion,
                v_dias_atraso,
                v_valor_multa);
                
    COMMIT;            
    
END;