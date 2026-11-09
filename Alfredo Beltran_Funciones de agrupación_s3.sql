SET DEFINE ON;
SET VERIFY OFF;

SELECT
    p.id_tipo_propiedad AS TIPO,
    COUNT(*) AS TOTAL_PROPIEDADES,
    TO_CHAR(
        MAX(p.valor_arriendo),
        'FM"$"999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS MAX_ARRIENDO,
    TO_CHAR(
        ROUND(AVG(p.valor_arriendo)),
        'FM"$"999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS PROMEDIO_ARRIENDO,
    TO_CHAR(
        MIN(p.valor_arriendo),
        'FM"$"999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS MIN_ARRIENDO,
    CASE
        WHEN MAX(p.valor_arriendo) > 1000000 THEN 'PREMIUM'
        ELSE 'ESTÁNDAR'
    END AS CLASIFICACION,
    TO_CHAR(
        SUM(NVL(p.valor_gasto_comun, 0)),
        'FM"$"999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS TOTAL_GASTOS_COMUNES
FROM propiedad p
GROUP BY p.id_tipo_propiedad
HAVING SUM(NVL(p.valor_gasto_comun, 0)) > &VALOR_TOTAL_GASTO_COMUN
ORDER BY SUM(NVL(p.valor_gasto_comun, 0)) DESC;

/* ============================================================================
   CASO 2 - ANALISIS DE ANTIGUEDAD DE EMPLEADOS
   ============================================================================ */

SELECT
    UPPER(e.nombre_emp || ' ' || e.appaterno_emp) AS "Nombre Empleado",
    TO_CHAR(
        e.sueldo_emp,
        'FM"$"999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS "Sueldo con Formato",
    CASE
        WHEN e.sueldo_emp > 2000000 THEN 'ALTO'
        ELSE 'MEDIO'
    END AS "Clasificación Sueldo",
    TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12) AS "Años Antigüedad",
    'Corresponde bono ' ||
    CASE
        WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12)
             BETWEEN 5 AND 10 THEN '5%: '
        WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12)
             BETWEEN 11 AND 20 THEN '10%: '
        ELSE '15%: '
    END ||
    TO_CHAR(
        ROUND(
            e.sueldo_emp *
            CASE
                WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12)
                     BETWEEN 5 AND 10 THEN 0.05
                WHEN TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) / 12)
                     BETWEEN 11 AND 20 THEN 0.10
                ELSE 0.15
            END
        ),
        'FM"$"999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS BONO
FROM empleado e
WHERE e.id_categoria_emp = 3
  AND e.id_sucursal <> &CODIGO_SUCURSAL
  AND MONTHS_BETWEEN(TRUNC(SYSDATE), e.fecing_emp) > 60
ORDER BY e.sueldo_emp DESC;

/* ============================================================================
   CASO 3 - LISTA DE CLIENTES
   ============================================================================ */

SELECT
    c.clasificacion_renta AS CLASIFICACION_RENTA,
    COUNT(*) AS CANTIDAD_CLIENTES,
    TO_CHAR(
        ROUND(AVG(c.renta_cli)),
        'FM"$"999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS RENTA_PROMEDIO,
    CASE
        WHEN COUNT(NULLIF(c.celular_cli, 0)) = 0
            THEN 'Clientes sin Teléfono'
        ELSE 'Clientes con Teléfono'
    END AS ESTADO_TELEFONO
FROM (
    SELECT
        cli.renta_cli,
        cli.celular_cli,
        CASE
            WHEN cli.renta_cli >= 1000000 THEN 'PREMIUM'
            WHEN cli.renta_cli >= 600000  THEN 'ALTA'
            WHEN cli.renta_cli >= 300000  THEN 'MEDIA'
            ELSE 'BAJA'
        END AS clasificacion_renta
    FROM cliente cli
) c
GROUP BY c.clasificacion_renta
HAVING AVG(c.renta_cli) > 200000
ORDER BY
    CASE c.clasificacion_renta
        WHEN 'ALTA'    THEN 1
        WHEN 'MEDIA'   THEN 2
        WHEN 'BAJA'    THEN 3
        WHEN 'PREMIUM' THEN 4
    END;
