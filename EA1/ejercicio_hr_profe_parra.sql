TRUNCATE TABLE liquidacion;

DROP TABLE liquidacion CASCADE;

CREATE TABLE liquidacion 
    (id_emp NUMBER NOT NULL, 
    fecha_liquidacion DATE NOT NULL,
    salario_base NUMBER NOT NULL, 
    bono_depto NUMBER NOT NULL, 
    bono_trabajo NUMBER NOT NULL, 
    bono_antiguedad NUMBER NOT NULL, 
    desc_salud NUMBER NOT NULL, 
    desc_afp NUMBER NOT NULL, 
    total_desc NUMBER NOT NULL, 
    total_bonos NUMBER NOT NULL, 
    total_liquido NUMBER NOT NULL, 
    CONSTRAINT liquidacion PRIMARY KEY 
        (id_emp, fecha_liquidacion) ENABLE);

DECLARE 

    v_id_emp                NUMBER;
    v_salario_base          NUMBER;

    v_bono_depto            NUMBER;
    v_bono_trabajo          NUMBER;
    v_bono_antiguedad       NUMBER;

    v_desc_salud            NUMBER;
    v_desc_afp              NUMBER;

    v_total_desc            NUMBER;
    v_total_bonos           NUMBER;
    v_total_liquido         NUMBER;
    
    v_departamento          VARCHAR(40);
    v_trabajo               VARCHAR(40);
    v_antiguedad            NUMBER(10);
 
    v_min_id                NUMBER;    
    v_max_id                NUMBER;

BEGIN

    SELECT MIN(employee_id), MAX(employee_id)
        INTO v_min_id, v_max_id
        FROM employees;
    
    FOR i IN v_min_id .. v_max_id LOOP
        
        SELECT E.employee_id,
            E.SALARY,
            J.JOB_TITLE,
            D.DEPARTMENT_NAME,
            TRUNC(MONTHS_BETWEEN(SYSDATE, E.HIRE_DATE)/12)
            
        INTO v_id_emp,
            v_salario_base,
            v_trabajo,
            v_departamento,
            v_antiguedad
            
        FROM employees E
        JOIN jobs J ON J.job_id = E.job_id
        JOIN departments D ON D.department_id = E.department_id
        WHERE E.employee_id = v_min_id;
        
        v_bono_depto :=
        CASE v_departamento 
            WHEN 'Human Resources' THEN v_salario_base*20/100
            WHEN 'Shipping' THEN v_salario_base*25/100
            WHEN 'IT' THEN v_salario_base*30/100
            WHEN 'Accounting' THEN v_salario_base*30/100
            ELSE 0
        END;
        
        v_bono_trabajo :=
        CASE v_trabajo 
            WHEN 'Finance Manager' THEN v_salario_base*5/100
            WHEN 'Public Accountant' THEN v_salario_base*7/100
            WHEN 'Sales Manager' THEN v_salario_base*10/100
            WHEN 'Shipping Clerk' THEN v_salario_base*15/100
            WHEN 'Programmer' THEN v_salario_base*20/100
            ELSE 0
        END;
        
        /*v_bono_antiguedad*/
        IF v_antiguedad BETWEEN 1 AND 5 THEN 
            v_bono_antiguedad := v_salario_base*10/100;
        ELSIF v_antiguedad BETWEEN 6 AND 15 THEN 
            v_bono_antiguedad := v_salario_base*20/100;
        ELSIF v_antiguedad > 15 THEN
            v_bono_antiguedad := v_salario_base*30/100;
        END IF;
        
        v_desc_salud := v_salario_base*7/100;
        v_desc_afp := v_salario_base*12/100;
        v_total_desc := v_desc_salud + v_desc_afp;
        v_total_bonos := v_bono_depto + v_bono_trabajo + v_bono_antiguedad;
        v_total_liquido := v_salario_base + v_total_bonos - v_total_desc;
        
        INSERT INTO liquidacion
            VALUES(v_id_emp,
                    SYSDATE,
                    v_salario_base,
                    v_bono_depto,
                    v_bono_trabajo,
                    v_bono_antiguedad,
                    v_desc_salud,
                    v_desc_afp,
                    v_total_desc,
                    v_total_bonos,
                    v_total_liquido);
                    
        v_min_id = v_min_id + 1;
    
    END LOOP;
    
END;

/*
1. FECHA_LIQUIDACION es de la fecha actual

2. BONO POR DPTO:
    HUMAN RES 20% DE SUELDO
    SHIPPING 25% DE SUELDO
    IT 30% DE SUELDO
    ACCOUNTING 30% DE SUELDO

3. BONO TRABAJO:
    FINANCE MANAGER 5% DE SUELDO
    PUBLIC ACCOUNTANT 7%
    SALES MANAGER 10%
    SHIPPING CLERK 15%
    PROGRAMMER 20%
    
4. SI EMP TIENE ENTRE 1 A 5 ANNOS 10% DE SALARY
    ENTRE 6-15 20% BONO DE SALARY
    MAS DE 15  30% BONO DE SALARY
    
5. SALUD 7% DEL SUELDO
    AFP 12% DEL SUELDO

7. DESCTOS SALUD+AFP 

8 TOTAL BONOS SUMA DE TODOS LOS BONOS

9 LIQUIDO SUELDO+BONOS - DESCUENTOS
*/