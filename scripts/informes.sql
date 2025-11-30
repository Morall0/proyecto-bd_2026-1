/* 
   Autor: Cruz Miranda Yasser Vladimir
   Fecha: 28/11/2025
   Descripcion:

*/

-- Numero total de Clientes activos 
CREATE OR ALTER PROCEDURE pa_NumClientesActivos
AS
BEGIN
    SELECT COUNT(DISTINCT C.cliente_id) AS NumClientesActivos
    FROM CLIENTE.CLIENTE C
    INNER JOIN VENTAS.POLIZA P ON C.cliente_id = P.cliente_id
    WHERE P.fecha_fin >= GETDATE();   -- criterio de póliza activa
END
GO
  

--Total de Ingresos por Primas del último mes
CREATE OR ALTER PROCEDURE pa_IngresosPrimasUltimoMes
AS
BEGIN
    SELECT SUM(P.prima_total) AS TotalIngresosPrimasUltimoMes
    FROM VENTAS.POLIZA P
    WHERE P.fecha_ini >= DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0)
      AND P.fecha_ini <  DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0);
END
GO

--Numero de Siniestros del último año
CREATE OR ALTER PROCEDURE pa_SiniestrosUltimoAnioPorCausa
AS
BEGIN
    SELECT 
        SI.causa,                       -- ajustar nombre de columna
        COUNT(SI.siniestro_id) AS TotalSiniestros
    FROM SEGURO.SINIESTRO SI
    WHERE SI.fecha_hora >= DATEADD(year, -1, GETDATE())
      AND SI.fecha_hora <  GETDATE()
    GROUP BY SI.causa
    ORDER BY TotalSiniestros DESC;
END
GO

-- Distribución de Clientes por Ciudad / Estado  
CREATE OR ALTER PROCEDURE pa_DistribucionClientesPorCiudadEstado
AS
BEGIN
    SELECT 
        C.estado,
        C.ciudad,
        COUNT(*) AS TotalClientes
    FROM CLIENTE.CLIENTE C
    GROUP BY C.estado, C.ciudad
    ORDER BY C.estado, C.ciudad;
END
GO


--Top 5 de Corredores con mayor Monto Prima Total
CREATE OR ALTER PROCEDURE pa_Top5CorredoresPrimaTotal
AS
BEGIN
    SELECT TOP 5
        E.nombre + ' ' + E.apellido_pat AS Corredor,
        SUM(P.prima_total) AS TotalPrimaVendida
    FROM VENTAS.POLIZA P
    INNER JOIN TRABAJADOR.EMPLEADO E ON P.num_empleado = E.num_empleado
    GROUP BY E.nombre, E.apellido_pat
    ORDER BY TotalPrimaVendida DESC;
END
GO

--Porcentaje de Pagos Atrasados
CREATE OR ALTER PROCEDURE pa_PorcentajePagosAtrasados
AS
BEGIN
    DECLARE @TotalEsperado  DECIMAL(18,2);
    DECLARE @TotalAtrasado  DECIMAL(18,2);

    -- Total de pagos esperados (monto de primas)
    SELECT @TotalEsperado = SUM(P.prima_total)
    FROM VENTAS.POLIZA P;

    -- Total de pagos atrasados (saldo pendiente)
    SELECT @TotalAtrasado = SUM(P.saldo_pend)
    FROM VENTAS.POLIZA P
    WHERE P.saldo_pend > 0;

    SELECT
        ISNULL(@TotalAtrasado, 0) AS TotalPagosAtrasados,
        ISNULL(@TotalEsperado, 0) AS TotalPagosEsperados,
        CASE 
            WHEN ISNULL(@TotalEsperado, 0) > 0 
                THEN (@TotalAtrasado * 100.0) / @TotalEsperado
            ELSE 0.0
        END AS PorcentajePagosAtrasados;
END
GO

--Edad promedio de los Asegurados en Seguros de Vida
CREATE OR ALTER PROCEDURE pa_EdadPromedioAseguradosVida
AS
BEGIN
    ;WITH ClientesVida AS (
        SELECT DISTINCT
            C.cliente_id,
            C.fecha_nacimiento    -- ajustar nombre de columna
        FROM CLIENTE.CLIENTE C
        INNER JOIN VENTAS.POLIZA P ON C.cliente_id = P.cliente_id
        INNER JOIN SEGURO.SEGURO S ON P.clave_seguro = S.clave_seguro
        WHERE S.tipo_seguro = 'V'       -- Vida
          AND P.fecha_fin >= GETDATE()  -- póliza vigente
    )
    SELECT AVG(DATEDIFF(year, fecha_nacimiento, GETDATE())) AS EdadPromedioAseguradosVida
    FROM ClientesVida;
END
GO
