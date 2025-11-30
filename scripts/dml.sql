/*
 * AUTOR: 
 * 		ALAN MAURICIO MORALES LÓPEZ
 * 		LUIS ADRIÁN GONZALEZ FALCÓN
 * 		YASSER VLADIMIR CRUZ MIRANDA
 * DESCRIPCION: SCRIPT DDL PARA LA BASE DE DATOS 'EL_BUEN_RETIRO'
 * FECHA: 26/11/2025
 */

USE EL_BUEN_RETIRO
GO

/*
 * Trigger que valida la edad de contratación
 */

CREATE OR ALTER TRIGGER VENTAS.tg_edad_contratacion
ON VENTAS.POLIZA
FOR INSERT
AS
BEGIN
	DECLARE @v_edad_cliente tinyint, 
					@v_edad_max tinyint
	
	-- Se calcula la edad del cliente con base en su fecha de nacimiento
	SELECT @v_edad_cliente = DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) - 
		CASE
			WHEN (MONTH(fecha_nacimiento) > MONTH(GETDATE())) OR
					 (MONTH(fecha_nacimiento) = MONTH(GETDATE()) AND DAY(fecha_nacimiento) > DAY(GETDATE()))
			THEN 1
			ELSE 0
		END
	FROM CLIENTE.CLIENTE c
	INNER JOIN INSERTED i
	ON c.cliente_id = i.cliente_id
	
	-- Selecciona la edad maxima del seguro contratado
	SELECT @v_edad_max = sv.edad_max
	FROM SEGURO.SEGURO_VIDA sv
	INNER JOIN INSERTED i
	ON sv.clave_seguro = i.clave_seguro
	
	-- Se verifica que la edad no sea mayor
	IF (@v_edad_cliente > @v_edad_max )
		BEGIN
			RAISERROR('Edad del cliente mayor que la edad maxima de contratación', 16, 1) -- Se lanza eror
			ROLLBACK TRANSACTION -- se deshace la insercion
		END
END