/*
Construir un proceso de remuneraciones

Reglas de negocio:
1. Si el empleado trabaja en toronto le corresponde una asignacion que se llama costo vida de 5000 extras.
2. Si el empleado tiene el trabajo 'AD_PRES' le corresponde una asignacion extra del 30% de su salario.
3. Si el empleado es jefe y posee mas de 3 empleados a su cargo se le paga una asignacion especial que es un porcentaje de su salario.
    Ejemplo:
    Si posee 4 empleados es un 4% de su salario.
    Si posee 5 empleados a su cargo es un 5% de su sueldo.
4. El valor de movilizacion es un 30% de su salario. Para aquellos empleados que trabajan en asia les corresponde adicionalmente un 20% mas de movilizacion.
5. El descuento de salud es fijo y corresponde al 7% de: salario del empleado + asignacion jefe + valor movilizacion NORMAL.
6. Descuento de AFP es un 12% de: salario del empleado + valor asignacion jefe + valor movil normal + valor movil extra
7. Liquido a pagar es: salario+asignacion jefe+movil normal+movil extra-desc salud- descto afp
8. Los resultados se insertan en las tablas HABER_MENSUAL, DESCUENTO_MENSUAL

REQ a nivel de diseno 
1. Los porcentajes de salud y AFP se deben ingresar de forma parametrica al bloque (variables bind)
2. El valor extra de movilizacion tambien debe ingresar en forma parametrica al bloque PLSLQ

*/