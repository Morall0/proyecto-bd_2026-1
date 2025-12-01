/* 
   informes.sql
   AUTOR: Cruz Miranda Yasser Vladimir
   FECHA: 28/11/2025
   DESCRIPCION: Consultas DQL de Estadisticas e Informes (Desencapsuladas)
 */

USE EL_BUEN_RETIRO;
GO

-- ESTADISTICAS

--Numero total de clientes activos 
SELECT COUNT(DISTINCT C.cliente_id) AS NumClientesActivos
FROM CLIENTE.CLIENTE C
INNER JOIN VENTAS.POLIZA P 
    ON C.cliente_id = P.cliente_id
WHERE P.fecha_fin >= GETDATE();
GO

--Numero de polizas activas por tipo de seguro
SELECT 
    S.tipo_seguro, 
    COUNT(P.num_poliza) AS NumeroPolizasActivas
FROM VENTAS.POLIZA P
INNER JOIN SEGURO.SEGURO S ON P.clave_seguro = S.clave_seguro
WHERE P.fecha_fin >= GETDATE()
GROUP BY S.tipo_seguro;
GO

--Promedio del monto asegurado por tipo de seguro
SELECT 
    S.tipo_seguro, 
    AVG(S.monto_asegurado_min) AS PromedioMontoAsegurado
FROM SEGURO.SEGURO S
GROUP BY S.tipo_seguro;
GO

--Total de Ingresos por Primas
SELECT ISNULL(SUM(P.prima_total), 0) AS TotalIngresosPrimas
FROM VENTAS.POLIZA P;
GO

--Número de Siniestros por Causa
SELECT 
    SI.causa,
    COUNT(SI.siniestro_id) AS TotalSiniestros
FROM SEGURO.SINIESTRO SI
GROUP BY SI.causa
ORDER BY TotalSiniestros DESC;
GO

--Distribución de Clientes por Ciudad / Estado
SELECT 
    E.nombre_estado AS Estado,
    M.nombre_municipio AS Ciudad,
    COUNT(C.cliente_id) AS TotalClientes
FROM CLIENTE.CLIENTE C
INNER JOIN CLIENTE.DIRECCION D        ON C.direccion_id = D.direccion_id
INNER JOIN CATALOGO.COLONIA CO        ON D.colonia_id = CO.colonia_id
INNER JOIN CATALOGO.MUNICIPIO M       ON CO.municipio_id = M.municipio_id
INNER JOIN CATALOGO.ESTADO E          ON M.estado_id = E.estado_id
GROUP BY E.nombre_estado, M.nombre_municipio
ORDER BY E.nombre_estado, M.nombre_municipio;
GO

--Top 5 Corredores por prima total vendida
SELECT TOP 5
    E.nombre + ' ' + E.apellido_pat AS Corredor,
    SUM(P.prima_total) AS TotalPrimaVendida
FROM VENTAS.POLIZA P
INNER JOIN TRABAJADOR.EMPLEADO E 
    ON P.num_empleado = E.num_empleado
GROUP BY E.nombre, E.apellido_pat
ORDER BY TotalPrimaVendida DESC;
GO

--Porcentaje de pagos atrasados
DECLARE @TotalEsperado DECIMAL(18,2);
DECLARE @TotalAtrasado DECIMAL(18,2);

SELECT @TotalEsperado = SUM(P.prima_total)
FROM VENTAS.POLIZA P;

SELECT @TotalAtrasado = SUM(P.saldo_pend)
FROM VENTAS.POLIZA P
WHERE P.saldo_pend > 0;

SELECT
    ISNULL(@TotalAtrasado, 0) AS TotalPagosAtrasados,
    ISNULL(@TotalEsperado, 0) AS TotalPagosEsperados,
    CASE 
        WHEN @TotalEsperado > 0 
            THEN (@TotalAtrasado * 100.0) / @TotalEsperado
        ELSE 0 
    END AS PorcentajePagosAtrasados;
GO

--Edad promedio de los Asegurados en Seguros de Vida
;WITH ClientesVida AS (
    SELECT DISTINCT
        C.cliente_id,
        C.fecha_nacimiento
    FROM CLIENTE.CLIENTE C
    INNER JOIN VENTAS.POLIZA P  ON C.cliente_id = P.cliente_id
    INNER JOIN SEGURO.SEGURO S  ON P.clave_seguro = S.clave_seguro
    WHERE S.tipo_seguro = 'V'   -- Vida
)
SELECT AVG(DATEDIFF(YEAR, fecha_nacimiento, GETDATE())) 
        AS EdadPromedioAseguradosVida
FROM ClientesVida;
GO

--Tasa de Renovación de Pólizas
;WITH PolizasOrdenadas AS (
    SELECT 
        P.num_poliza,
        P.cliente_id,
        P.fecha_ini,
        P.fecha_fin,
        LEAD(P.fecha_ini) OVER (
            PARTITION BY P.cliente_id
            ORDER BY P.fecha_ini
        ) AS FechaSiguiente
    FROM VENTAS.POLIZA P
)
SELECT
    SUM(CASE WHEN fecha_fin < GETDATE() THEN 1 ELSE 0 END) AS PolizasFinalizadas,
    SUM(CASE WHEN fecha_fin < GETDATE() 
              AND FechaSiguiente IS NOT NULL
              AND FechaSiguiente >= fecha_fin THEN 1 ELSE 0 END) AS PolizasRenovadas,
    CASE 
        WHEN SUM(CASE WHEN fecha_fin < GETDATE() THEN 1 END) > 0
            THEN (SUM(CASE WHEN fecha_fin < GETDATE()
                              AND FechaSiguiente >= fecha_fin THEN 1 END) * 100.0)
                  / SUM(CASE WHEN fecha_fin < GETDATE() THEN 1 END)
        ELSE 0
    END AS TasaRenovacion
FROM PolizasOrdenadas;
GO

-- INFORMES

--Listado de polizas activas por corredor
SELECT 
    C.nombre + ' ' + C.apellido_pat + ' ' + ISNULL(C.apellido_mat, '') AS NombreCliente,
    P.num_poliza,
    P.fecha_fin AS FechaFinVigencia,
    E.nombre + ' ' + E.apellido_pat AS Corredor
FROM CLIENTE.CLIENTE C
INNER JOIN VENTAS.POLIZA P ON C.cliente_id = P.cliente_id
INNER JOIN TRABAJADOR.EMPLEADO E ON P.num_empleado = E.num_empleado
WHERE P.fecha_fin >= GETDATE() 
ORDER BY E.nombre, P.fecha_fin;
GO

--Monto total de primas vendidas por corredor
SELECT 
    E.nombre + ' ' + E.apellido_pat AS Corredor,
    SUM(P.prima_total) AS TotalPrimaVendida
FROM VENTAS.POLIZA P
INNER JOIN TRABAJADOR.EMPLEADO E ON P.num_empleado = E.num_empleado
GROUP BY E.nombre, E.apellido_pat
ORDER BY TotalPrimaVendida DESC;
GO

--Cotizaciones pendientes
SELECT 
    S.tipo_seguro,
    COUNT(C.num_cotizacion) AS TotalCotizacionesPendientes
FROM SEGURO.SEGURO S
INNER JOIN VENTAS.COTIZACION_SEGURO CS ON S.clave_seguro = CS.clave_seguro
INNER JOIN VENTAS.COTIZACION C ON CS.cotizacion_id = C.cotizacion_id
WHERE C.clave_estado = 'P' 
GROUP BY S.tipo_seguro
ORDER BY TotalCotizacionesPendientes DESC;
GO

--Clientes con seguro de vida y retiro
SELECT 
    C.nombre + ' ' + C.apellido_pat + ' ' + ISNULL(C.apellido_mat, '') AS NombreCliente,
    C.curp,
    S1.tipo_seguro AS SeguroVida,
    S2.tipo_seguro AS SeguroRetiro
FROM CLIENTE.CLIENTE C
INNER JOIN VENTAS.POLIZA P1 ON C.cliente_id = P1.cliente_id
INNER JOIN SEGURO.SEGURO S1 ON P1.clave_seguro = S1.clave_seguro 
    AND S1.tipo_seguro = 'V' --
INNER JOIN VENTAS.POLIZA P2 ON C.cliente_id = P2.cliente_id
INNER JOIN SEGURO.SEGURO S2 ON P2.clave_seguro = S2.clave_seguro 
    AND S2.tipo_seguro = 'R' -- 
WHERE P1.fecha_fin >= GETDATE() AND P2.fecha_fin >= GETDATE();
GO

--Listado de pagos pendientes
SELECT 
    P.num_poliza,
    P.fecha_fin AS FechaVencimiento,
    P.saldo_pend AS SaldoPendiente
FROM VENTAS.POLIZA P
WHERE P.saldo_pend > 0
ORDER BY P.fecha_fin;
GO

--Reporte de siniestros
SELECT 
    S.tipo_seguro,
    AVG(SI.monto_indemnizacion) AS PromedioMontoIndemnizacion
FROM SEGURO.SINIESTRO SI
INNER JOIN VENTAS.POLIZA P ON SI.num_poliza = P.num_poliza
INNER JOIN SEGURO.SEGURO S ON P.clave_seguro = S.clave_seguro
GROUP BY S.tipo_seguro
ORDER BY PromedioMontoIndemnizacion DESC;
GO

--Concentrado de vehiculos asegurados por marca y modelo
SELECT 
    V.marca,
    V.modelo,
    COUNT(V.matricula) AS TotalVehiculosAsegurados
FROM SEGURO.VEHICULO V
INNER JOIN VENTAS.POLIZA P ON V.matricula = P.matricula 
GROUP BY V.marca, V.modelo
ORDER BY TotalVehiculosAsegurados DESC;
GO
