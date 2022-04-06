DECLARE 

    V_ID_EMP                NUMBER;
    --V_FECHA_LIQUIDACION     DATE;
    V_SALARIO_BASE          NUMBER;
    V_BONO_DEPTO            NUMBER;
    V_BONO_TRABAJO          NUMBER;
    V_BONO_ANTIGUEDAD       NUMBER;
    V_DESC_SALUD            NUMBER;
    V_DESC_AFP              NUMBER;
    V_TOTAL_DESC            NUMBER;
    V_TOTAL_BONOS           NUMBER;
    V_TOTAL_LIQUIDO         NUMBER;
    
    V_DEPARTAMENTO          VARCHAR(40);
    V_TRABAJO               VARCHAR(40);
    V_ANTIGUEDAD            NUMBER(10);
    
    V_TOTAL_EMP             NUMBER;
    V_MIN_EMP               NUMBER;
    
BEGIN

    SELECT COUNT(EMPLOYEE_ID), MIN(EMPLOYEE_ID)
        INTO V_TOTAL_EMP, V_MIN_EMP
        FROM EMPLOYEES;
    
    FOR i IN 1 .. V_TOTAL_EMP LOOP
        
        SELECT E.EMPLOYEE_ID,
            E.SALARY,
            J.JOB_TITLE,
            D.DEPARTMENT_NAME,
            TRUNC(MONTHS_BETWEEN(SYSDATE, E.HIRE_DATE)/12)
            
        INTO V_ID_EMP,
            V_SALARIO_BASE,
            V_TRABAJO,
            V_DEPARTAMENTO,
            V_ANTIGUEDAD
            
        FROM EMPLOYEES E
        JOIN JOBS J ON J.JOB_ID = E.JOB_ID
        JOIN DEPARTMENTS D ON D.DEPARTMENT_ID = E.DEPARTMENT_ID
        WHERE E.EMPLOYEE_ID = V_MIN_EMP;
        
        --V_BONO_DEPTO
        CASE V_DEPARTAMENTO 
            WHEN 'Human Resources' THEN V_BONO_DEPTO := V_SALARIO_BASE*20/100;
            WHEN 'Shipping' THEN V_BONO_DEPTO := V_SALARIO_BASE*25/100;
            WHEN 'IT' THEN V_BONO_DEPTO := V_SALARIO_BASE*30/100;
            WHEN 'Accounting' THEN V_BONO_DEPTO := V_SALARIO_BASE*30/100;
            ELSE V_BONO_DEPTO := 0;
        END CASE;
        
        --V_BONO_TRABAJO
        CASE V_TRABAJO 
            WHEN 'Finance Manager' THEN V_BONO_TRABAJO := V_SALARIO_BASE*5/100;
            WHEN 'Public Accountant' THEN V_BONO_TRABAJO := V_SALARIO_BASE*7/100;
            WHEN 'Sales Manager' THEN V_BONO_TRABAJO := V_SALARIO_BASE*10/100;
            WHEN 'Shipping Clerk' THEN V_BONO_TRABAJO := V_SALARIO_BASE*15/100;
            WHEN 'Programmer' THEN V_BONO_TRABAJO := V_SALARIO_BASE*20/100;
            ELSE V_BONO_TRABAJO := 0;
        END CASE;
        
        --V_BONO_ANTIGUEDAD
        IF V_ANTIGUEDAD BETWEEN 1 AND 5 THEN 
            V_BONO_ANTIGUEDAD := V_SALARIO_BASE*10/100;
        ELSIF V_ANTIGUEDAD BETWEEN 6 AND 15 THEN 
            V_BONO_ANTIGUEDAD := V_SALARIO_BASE*20/100;
        ELSIF V_ANTIGUEDAD > 15 THEN
            V_BONO_ANTIGUEDAD := V_SALARIO_BASE*30/100;
        END IF;
        
        V_DESC_SALUD := V_SALARIO_BASE*7/100;
        V_DESC_AFP := V_SALARIO_BASE*12/100;
        V_TOTAL_DESC := V_DESC_SALUD + V_DESC_AFP;
        V_TOTAL_BONOS := V_BONO_DEPTO + V_BONO_TRABAJO + V_BONO_ANTIGUEDAD;
        V_TOTAL_LIQUIDO := V_SALARIO_BASE + V_TOTAL_BONOS - V_TOTAL_DESC;
        
        INSERT INTO LIQUIDACION
            VALUES(V_ID_EMP,
                    SYSDATE,
                    V_SALARIO_BASE,
                    V_BONO_DEPTO,
                    V_BONO_TRABAJO,
                    V_BONO_ANTIGUEDAD,
                    V_DESC_SALUD,
                    V_DESC_AFP,
                    V_TOTAL_DESC,
                    V_TOTAL_BONOS,
                    V_TOTAL_LIQUIDO);
                    
        V_MIN_ID = V_MIN_ID + 1;
    
    END LOOP;
    
END;

/*

tabla

id_emp NUMBER(PK)
fecha_liquidacion DATE(PK)
salario_base NUMBER
bono_depto NUMBER
bono_trabajo NUMBER
bono_antiguedad NUMBER
desc_salud NUMBER
desc_afp NUMBER
total_desc NUMBER
total_bonos NUMBER
total_liquido NUMBER

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