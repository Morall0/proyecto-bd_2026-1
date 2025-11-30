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
 * Trigger que asigna el corredor cuando no se especifíca
 */

CREATE OR ALTER TRIGGER VENTAS.tg_asigna_corredor_zona
ON VENTAS.POLIZA
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @v_codigo_postal_cliente varchar(5),
					@v_num_empleado bigint
	
	IF ((SELECT i.num_empleado 
			FROM INSERTED i)
			IS NULL) -- Si no se mandó un num_empleado
	BEGIN 
		-- Se busca el codigo postal del cliente
		SELECT @v_codigo_postal_cliente = col.codigo_postal
		FROM INSERTED i
		INNER JOIN CLIENTE.CLIENTE c
		ON c.cliente_id = i.cliente_id
		INNER JOIN CLIENTE.DIRECCION d
		ON c.direccion_id = d.direccion_id
		INNER JOIN CATALOGO.COLONIA col
		ON col.colonia_id = d.colonia_id
		
		-- Se busca el num_empleado que tiene asignado ese codigo postal
		SELECT @v_num_empleado = cpc.num_empleado
		FROM TRABAJADOR.CODIGO_POSTAL_CORREDOR cpc
		WHERE codigo_postal = @v_codigo_postal_cliente
		
		-- Se realiza la inserción
		INSERT INTO VENTAS.POLIZA (num_poliza, saldo_pend, cliente_id, fecha_ini, fecha_fin, 
												prima_total, num_empleado, matricula, clave_seguro) 
		VALUES 
		SELECT num_poliza, saldo_pend, cliente_id, fecha_ini, fecha_fin, prima_total, @v_num_empleado, matricula, clave_seguro 
		FROM INSERTED
		
	END
	ELSE -- Si no viene null, hace el insert con los datos ya hechos
	BEGIN
		INSERT INTO VENTAS.POLIZA VALUES
		SELECT * FROM INSERTED
	END
	
END

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
	
	-- Se verifica que se trate de un seguro de vida

	IF (EXISTS (SELECT s.tipo_seguro
						FROM INSERTED i
						INNER JOIN SEGURO.SEGURO s
						ON i.clave_seguro = s.clave_seguro
						WHERE s.tipo_seguro = 'V'))
	BEGIN
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
END