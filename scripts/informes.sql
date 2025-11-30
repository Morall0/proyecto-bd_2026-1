/* 
 * AUTOR: Cruz Miranda Yasser Vladimir
 * FECHA: 28/11/2025
 * DESCRIPCION: Procedimientos almacenados de estadisticas
 */

USE EL_BUEN_RETIRO;
GO

--Numero total de clientes activos 
CREATE OR ALTER PROCEDURE pa_NumClientesActivos
AS
BEGIN
    SELECT COUNT(DISTINCT C.cliente_id) AS NumClientesActivos
    FROM CLIENTE.CLIENTE C
    INNER JOIN VENTAS.POLIZA P 
        ON C.cliente_id = P.cliente_id
    WHERE P.fecha_fin >= GETDATE();
END
GO
EXEC pa_NumClientesActivos;
GO


--Numero de polizas activas por tipo de seguro

CREATE OR ALTER PROCEDURE pa_PolizasActivasPorTipo
AS
BEGIN
    SELECT 
        S.tipo_seguro, 
        COUNT(P.num_poliza) AS NumeroPolizasActivas
    FROM VENTAS.POLIZA P
    INNER JOIN SEGURO.SEGURO S ON P.clave_seguro = S.clave_seguro
    WHERE P.fecha_fin >= GETDATE()
    GROUP BY S.tipo_seguro;
END
GO
EXEC pa_PolizasActivasPorTipo;
GO


--Promedio del monto asegurado por tipo de seguro
CREATE OR ALTER PROCEDURE pa_MontoAseguradoPromedio
AS
BEGIN
    SELECT 
        S.tipo_seguro, 
        AVG(S.monto_asegurado_min) AS PromedioMontoAsegurado
    FROM SEGURO.SEGURO S
    GROUP BY S.tipo_seguro;
END
GO
EXEC pa_MontoAseguradoPromedio;
GO


--Total de Ingresos por Primas
CREATE OR ALTER PROCEDURE pa_IngresosPrimasUltimoMes
AS
BEGIN
    SELECT ISNULL(SUM(P.prima_total), 0) AS TotalIngresosPrimas
    FROM VENTAS.POLIZA P;
END
GO
EXEC pa_IngresosPrimasUltimoMes;
GO


--Número de Siniestros por Causa
CREATE OR ALTER PROCEDURE pa_SiniestrosUltimoAnioPorCausa
AS
BEGIN
    SELECT 
        SI.causa,
        COUNT(SI.siniestro_id) AS TotalSiniestros
    FROM SEGURO.SINIESTRO SI
    GROUP BY SI.causa
    ORDER BY TotalSiniestros DESC;
END
GO
EXEC pa_SiniestrosUltimoAnioPorCausa;
GO


--Distribución de Clientes por Ciudad / Estado
CREATE OR ALTER PROCEDURE pa_DistribucionClientesPorCiudadEstado
AS
BEGIN
    SELECT 
        E.nombre_estado AS Estado,
        M.nombre_municipio AS Ciudad,
        COUNT(C.cliente_id) AS TotalClientes
    FROM CLIENTE.CLIENTE C
    INNER JOIN CLIENTE.DIRECCION D       ON C.direccion_id = D.direccion_id
    INNER JOIN CATALOGO.COLONIA CO       ON D.colonia_id = CO.colonia_id
    INNER JOIN CATALOGO.MUNICIPIO M      ON CO.municipio_id = M.municipio_id
    INNER JOIN CATALOGO.ESTADO E         ON M.estado_id = E.estado_id
    GROUP BY E.nombre_estado, M.nombre_municipio
    ORDER BY E.nombre_estado, M.nombre_municipio;
END
GO
EXEC pa_DistribucionClientesPorCiudadEstado;
GO


--Top 5 Corredores por prima total vendida
CREATE OR ALTER PROCEDURE pa_Top5CorredoresPrimaTotal
AS
BEGIN
    SELECT TOP 5
        E.nombre + ' ' + E.apellido_pat AS Corredor,
        SUM(P.prima_total) AS TotalPrimaVendida
    FROM VENTAS.POLIZA P
    INNER JOIN TRABAJADOR.EMPLEADO E 
        ON P.num_empleado = E.num_empleado
    GROUP BY E.nombre, E.apellido_pat
    ORDER BY TotalPrimaVendida DESC;
END
GO
EXEC pa_Top5CorredoresPrimaTotal;
GO

 --Porcentaje de pagos atrasados
CREATE OR ALTER PROCEDURE pa_PorcentajePagosAtrasados
AS
BEGIN
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
END
GO
EXEC pa_PorcentajePagosAtrasados;
GO


--Edad promedio de los Asegurados en Seguros de Vida
CREATE OR ALTER PROCEDURE pa_EdadPromedioAseguradosVida
AS
BEGIN
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
END
GO
EXEC pa_EdadPromedioAseguradosVida;
GO


--Tasa de Renovación de Pólizas
CREATE OR ALTER PROCEDURE pa_TasaRenovacionPolizas
AS
BEGIN
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
END
GO
EXEC pa_TasaRenovacionPolizas;
GO
