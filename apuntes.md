# Apuntes Programacion BD

## Pasos para resolver caso:

1. Identificar la informacion me estan pidiendo (columnas)
2. Entender de donde sacare esa informacion 
 - Que informacion corresponde a sentencias SELECT sin calculos ni cambios
 - Que informacion se obtiene de sentencias SELECT y para efectuar calculos
 - Que informacion se obtiene de calculos en CONDICIONES
 - Que informacion finalmente se obtiene con calculos simples
3. Verificar que las sentencias SELECT devuelvan los datos en todos los IDs consultados
4. Comprobar que se ha obtenido toda la informacion necesaria
5. Generar sentencias DML y probar por cada ID
6. Generar ciclo iterativo mediante loop para realizar DML

Importante:
- No usar IF como expresion para almacenar en variable
- No usar SELECT dentro de una sentencia para almacenar en variable

## Tipos de comandos SQL

1. DDL (Data Definition Language) (Estructura de tablas, campos, etc)

		CREATE
		DROP
		ALTER
		TRUNCATE
		DESCRIBE
		RENAME

2. DML (Data Manipulation Language) (Registros de datos)

		INSERT
		UPDATE
		DELETE

3. DQL (Data Query Language) (Consultas)

		SELECT

4. DCL (Data Control Language) (Permisos)

		GRANT
		REVOKE

5. TCL (Transacciones)
 
		COMMIT
		ROLLBACK
		SAVEPOINT

---

## DDL

1. CREAR TABLAS

		CREATE TABLE table_name (
	    column1 datatype,
	    column2 datatype,
	    column3 datatype);

- Desde otra tabla

		CREATE TABLE new_table AS 
			(SELECT * FROM old_table);

2. Borrar tablas

		DROP TABLE table_name CASCADE CONSTRAINTS;

3. Vaciar tabla

		TRUNCATE TABLE table_name;

---

## DML

1. INSERT

		INSERT INTO tableName (column1, column2, …)
		VALUES (value1, value2, …)

- Desde otra tabla

		INSERT INTO targetTable (column1, column2, …)
		SELECT (column1, column2, …)
		FROM sourceTable;

2. UPDATE

- Ejemplo fila unica

		UPDATE tabla
		SET columna1 = valor1, columna2 = valor2,...
		WHERE columnaFiltro=valorFiltro;

- Ejemplo multiples filas

		UPDATE tabla
		SET columnaModificar = 'A'
		WHERE columnaFiltro = 'B';

3. DELETE

- Ejemplo fila unica

		DELETE FROM tabla
		WHERE  columnaFiltro = valorFiltro;

- Ejemplo multiples filas

		DELETE FROM tabla 
		WHERE fechaContrato < SYSDATE;

---

## DQL

- Sentencia SELECT

		SELECT
		INTO
		FROM
		JOIN
		ON
		WHERE
		GROUP BY
		HAVING
		ORDER BY

---

### FUNCIONES

- De fila unica

		MONTHS_BETWEEN()
		ADD_MONTHS()
		EXTRACT(datetime)
		SYSDATE
		LAST_DAY()

		TO_CHAR()
		TO_NUMBER()
		TO_DATE()

		NVL()

		ROUND()
		TRUNC()
		MOD()

		SUBSTR()
		LENGTH()
		INITCAP()
		LOWER()
		UPPER()

- De multiples filas

		COUNT()
		MIN()
		MAX()
		AVG()
		SUM()

---

### UNIONES DE TABLAS

		NATURAL JOIN
		(INNER) JOIN
		LEFT (OUTER) JOIN
		RIGHT (OUTER) JOIN
		FULL (OUTER) JOIN

---

### OPERADORES SET

		UNION
		UNION ALL
		INTERSECT
		MINUS

---

## PL/SQL

### Variables

- Variables BIND o "de ambiente"

		VAR b_nombre_variable TIPODATO
		EXEC :b_nombre_variable := VALOR

- Variables en bloque PLSQL

		v_nombre_variable TIPODATO(00);
		v_nombre_variable TIPODATO(00) := VALOR;
		v_nombre_variable tabla.columna%TYPE := VALOR;

---

### Sentencias de control 

1. Condicional

- IF, IF-ELSE, IF-ELSIF-ELSE

		IF condicion THEN
			sentencia;
		END IF;

		IF condicion THEN
			sentencia1;
		ELSE
			sentencia2;
		END IF;

		IF condicion THEN
			sentencia1;
		ELSIF
			sentencia2;
		ELSE
			sentencia3:
		END IF;

- CASE

- Como sentencia

		CASE selector 
			WHEN condicion1 THEN expresion1;
			WHEN condicion2 THEN expresion2;
			ELSE expresion3;
		END CASE;

- Como expresion

		v_variable :=
		CASE selector 
			WHEN condicion1 THEN expresion1
			WHEN condicion2 THEN expresion2
			ELSE expresion3
		END;

2. Iteraciones

- LOOP simple

		LOOP
		[EXIT]
		[EXIT WHEN condicion]
		END LOOP:

- WHILE LOOP

		WHILE condicion LOOP
		[EXIT]
		END LOOP;

- FOR LOOP

		FOR i IN valor2 .. valor2 LOOP
		[EXIT]
		END LOOP;

- LOOPs anidados

		LOOP <<bucle1>>
			LOOP <<bucle2>>
			END LOOP bucle2;
		END LOOP bucle1:

---

### DBMS OUTPUT

	SET SERVEROUTPUT ON
	DBMS_OUTPUT.PUT_LINE()

---

### Excepciones

		EXCEPTION WHEN exception_name THEN

- Excepciones pre-definidas (algunas)

		NO_DATA_FOUND
		TOO_MANY_ROWS

---

## OTROS

1. DEFINE

- DEFINE (crear variables de usuario)

		DEF[INE] [variable_name [= text]]
		UNDEFINE var_sustitucion

- DEFINE (examinar variables creadas)

		SQL> DEFINE fiscal_year
		DEFINE FISCAL_YEAR     = "1998" (CHAR)
		SQL> DEFINE my_publisher
		DEFINE MY_PUBLISHER    = "O'Reilly" (CHAR)
		SQL> DEFINE my_editor
		DEFINE MY_EDITOR       = "Debby" (CHAR)

- DEFINE (sin argumentos, lista todas las variables)

		SQL> DEFINE
		DEFINE _SQLPLUS_RELEASE = "800040000" (CHAR)
		DEFINE _EDITOR         = "Notepad" (CHAR)
		DEFINE _O_VERSION      = "Oracle8 Enterprise Edition Release 8.1.3.0.0
		With the Partitioning and Objects options
		PL/SQL Release 8.1.3.0.0 - Beta" (CHAR)
		DEFINE _O_RELEASE      = "801030000" (CHAR)
		DEFINE FISCAL_YEAR     = "1998" (CHAR)
		DEFINE MY_PUBLISHER    = "O'Reilly" (CHAR)
		DEFINE MY_EDITOR       = "Debby" (CHAR)
		SQL>

- Ejemplo

		SQL> DEFINE fiscal_year = 1998
		SQL> DEFINE my_publisher = "O'Reilly"
		SQL> DEFINE my_editor = Debby Russell

2. UNDEFINE (elimina las variables definidas)

		UNDEF[INE] variable_name [ variable_name...]

- Ejemplo

		SQL> UNDEFINE fiscal_year
		SQL> UNDEFINE my_publisher my_editor
		SQL> DEFINE my_publisher
		symbol my_publisher is UNDEFINED
		SQL> DEFINE my_editor
		symbol my_editor is UNDEFINED
		SQL> DEFINE fiscal_year
		symbol fiscal_year is UNDEFINED