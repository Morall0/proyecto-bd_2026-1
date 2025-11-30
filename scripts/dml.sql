/*
 * AUTOR: 
 * 		ALAN MAURICIO MORALES LÓPEZ
 * 		LUIS ADRIÁN GONZALEZ FALCÓN
 * 		YASSER VLADIMIR CRUZ MIRANDA
 * DESCRIPCION: SCRIPT DDL PARA LA BASE DE DATOS 'EL_BUEN_RETIRO'
 * FECHA: 26/11/2025
 */

USE [EL_BUEN_RETIRO]
GO

-- TRIGGER 3
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
GO


-- TRIGGER 5
CREATE OR ALTER TRIGGER VENTAS.tg_pago_saldo
ON VENTAS.PAGO
FOR insert, update
as
begin
	declare 
		@v_monto_pago as tinyint,		
		@v_saldo_pendiente as int,
		@v_saldo_pendiente_actualizado as int,
		@v_num_poliza as int

	select @v_monto_pago=monto, @v_num_poliza = num_poliza from inserted; --se obtiene el monto e id_pago de un pago
	select @v_saldo_pendiente = saldo_pend from VENTAS.poliza p where p.num_poliza = @v_num_poliza; -- se obtiene el saldo pendiente para comparar y actualizar

	--actualizando
	--checar que el monto depositado no sea mayor al saldo pendiente
	if(@v_monto_pago <= @v_saldo_pendiente)
	begin
		set @v_saldo_pendiente_actualizado = @v_saldo_pendiente - @v_monto_pago --cantidad mayor o igual a 0 por el condicional
		update VENTAS.poliza
		set saldo_pend = @v_saldo_pendiente_actualizado
		where num_poliza = @v_num_poliza;
	end
	else
	begin
		-- mensaje de que se insertó un monto mayor al pendiente
		raiserror('Error al intentar insertar un monto mayor al saldo pendiente',10,1);
		rollback transaction;
	end
end
go
