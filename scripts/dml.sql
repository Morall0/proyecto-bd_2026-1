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

/*
 * VISTAS ================================================================
 */

/*
 * Vista para obtener los datos del CLIENTE
 */
CREATE OR ALTER VIEW CLIENTE.vis_cliente
AS
SELECT c.cliente_id, c.nombre, c.apellido_pat, c.apellido_mat, c.tipo_cliente,
	(CASE
		WHEN c.tipo_cliente = 'N' THEN c.curp
		WHEN c.tipo_cliente = 'M' THEN c.rfc
		END) AS 'identificador_fiscal', 
	DATEDIFF(YEAR, c.fecha_nacimiento, GETDATE()) - 
	(CASE
		WHEN (MONTH(c.fecha_nacimiento) > MONTH(GETDATE())) OR
				 (MONTH(c.fecha_nacimiento) = MONTH(GETDATE()) AND DAY(c.fecha_nacimiento) > DAY(GETDATE()))
		THEN 1
		ELSE 0
		END) AS 'edad', c.fecha_nacimiento,
		d.calle, d.num_ext, ISNULL(CAST(d.num_int AS VARCHAR(20)), 'Sin numero int') AS 'num_int',
		col.nombre_colonia, col.codigo_postal, m.nombre_municipio, e.nombre_estado
FROM CLIENTE c
INNER JOIN CLIENTE.DIRECCION d
ON c.direccion_id = d.direccion_id
INNER JOIN CATALOGO.COLONIA col
ON d.colonia_id = col.colonia_id
INNER JOIN CATALOGO.MUNICIPIO m
ON col.municipio_id = m.municipio_id
INNER JOIN CATALOGO.ESTADO e
ON m.estado_id = e.estado_id;
GO

--SELECT * FROM CLIENTE.vis_cliente

/*
 * Vista para obtener los datos del siniestro
 */
CREATE OR ALTER VIEW SEGURO.vis_siniestro
AS
SELECT s.num_siniestro, s.lugar, s.causa, s.fecha_hora, 
			 (DATEDIFF(DAY, s.fecha_hora, GETDATE())) AS dias_transcurridos,
			 s.monto_indemnizacion, s.num_poliza,
			 e.nombre+' '+e.apellido_pat+' '+ISNULL(e.apellido_mat, '') AS nombre_ajustador
FROM SEGURO.SINIESTRO s
INNER JOIN TRABAJADOR.EMPLEADO e
ON s.num_empleado = e.num_empleado;
GO

--SELECT * FROM SEGURO.vis_siniestro

/*
 * Vista para obtener los beneficiarios y la poliza que los aseguras
 */
CREATE OR ALTER VIEW VENTAS.vis_beneficiarios
AS
SELECT b.beneficiario_id, par.parentesco,
			 b.nombre+' '+b.apellido_pat+' '+ISNULL(b.apellido_mat, '') AS nombre_beneficiario,
			 bp.num_poliza, bp.porcentaje
FROM SEGURO.BENEFICIARIO b
INNER JOIN CATALOGO.PARENTESCO par
ON b.parentesco_id=par.parentesco_id
INNER JOIN VENTAS.BENEFICIARIO_POLIZA bp
ON b.beneficiario_id = bp.beneficiario_id;
GO

-- SELECT * FROM VENTAS.vis_beneficiarios ORDER BY num_poliza

/*
 * Triggers ==============================================================
 */

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
		SELECT num_poliza, saldo_pend, cliente_id, fecha_ini, fecha_fin, prima_total, @v_num_empleado, matricula, clave_seguro 
		FROM INSERTED
		
	END
	ELSE -- Si no viene null, hace el insert con los datos ya hechos
	BEGIN
		INSERT INTO VENTAS.POLIZA(
	    saldo_pend,
	    cliente_id,
	    fecha_ini,
	    fecha_fin,
	    prima_total,
	    num_empleado,
	    matricula,
	    clave_seguro
		)
		SELECT 
	    saldo_pend,
	    cliente_id,
	    fecha_ini,
	    fecha_fin,
	    prima_total,
	    num_empleado,
	    matricula,
	    clave_seguro
		FROM INSERTED;
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
GO

/*
 * Trigger que calcula el saldo pendiente tras insertar o actualizar pago
 */
CREATE OR ALTER TRIGGER VENTAS.tg_saldo_pendiente
ON VENTAS.PAGO
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE 
		@v_num_poliza as int, 
		@v_saldo_pendiente as int,
		@v_saldo_total as int,
		@v_suma_pagos as int
	
	SELECT @v_num_poliza = num_poliza from INSERTED; -- obtener el num_poliza del pago de inserted
	SELECT @v_saldo_total = prima_total from VENTAS.POLIZA WHERE num_poliza = @v_num_poliza; -- obtener el saldo total de poliza 
	SELECT @v_suma_pagos = sum(monto) from VENTAS.PAGO where num_poliza = @v_num_poliza; -- obtener la suma de los pagos de una poliza
	SET @v_saldo_pendiente = @v_saldo_total - @v_suma_pagos; -- obtener el saldo pendiente (total - pagado)

	if(@v_saldo_pendiente<0) -- entra cuando el saldo pendiente es menor a 0
	BEGIN
		RAISERROR('El pago sobrepasa el saldo pendiente de la póliza.', 16,1);
		ROLLBACK TRANSACTION;
		RETURN;
	END
	-- Si llegó aquí, el saldo pendiente es >=0
	UPDATE VENTAS.POLIZA
	set saldo_pend = @v_saldo_pendiente
	WHERE num_poliza = @v_num_poliza;	
END
GO

/*
 * Trigger que registra en la bitacora de estados cuando cambia el estado de una cotización.
 */
CREATE OR ALTER TRIGGER VENTAS.tg_bitacora_estado
ON VENTAS.COTIZACION
FOR UPDATE
AS
BEGIN
	DECLARE 
		@v_clave_estado_antiguo as varchar(1),
		@v_clave_estado_actualizado as varchar(1),
		@v_cotizacion_id as numeric(18,0)
	
	select @v_clave_estado_antiguo = clave_estado from deleted; -- estado antiguo
	select @v_clave_estado_actualizado = clave_estado from inserted; -- estado nuevo
	select @v_cotizacion_id = cotizacion_id from inserted; -- cotizacion id

	--verificar que el estado haya cambiado
	if(@v_clave_estado_actualizado != @v_clave_estado_antiguo)
	begin
		--insertar registro en tabla de bitacora.
		insert into VENTAS.BITACORA_COTIZACION (fecha_cambio, cotizacion_id, clave_estado)
			values (
				GETDATE(),
				@v_cotizacion_id,
				@v_clave_estado_actualizado
			);
	end
END
GO

/*
 * Trigger que valida a los beneficiarios de un seguro de vida
 */
CREATE OR ALTER TRIGGER VENTAS.tg_beneficiarios
ON VENTAS.BENEFICIARIO_POLIZA
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @v_cantidad_beneficiarios tinyint,
					@v_num_poliza bigint,
					@v_porcentaje_total NUMERIC(3,2)
	
	-- Se verifica que el seguro con el que se relaciona sea de tipo 'V'
	IF (EXISTS (SELECT s.clave_seguro
							FROM INSERTED i
							INNER JOIN VENTAS.POLIZA p
							ON p.num_poliza = i.num_poliza
							INNER JOIN SEGURO.SEGURO s
							ON p.clave_seguro = s.clave_seguro
							WHERE	s.tipo_seguro = 'V'))
	BEGIN
		
		-- Encontrando el numero de poliza con el que se quiere asociar al beneficiario
		SELECT @v_num_poliza = num_poliza FROM INSERTED
		
		-- Calculando la cantidad de beneficiarios actual y el porcentaje total
		SELECT @v_cantidad_beneficiarios = COALESCE(count(*),0), @v_porcentaje_total = COALESCE(sum(porcentaje),0)
		FROM VENTAS.BENEFICIARIO_POLIZA bp
		WHERE bp.num_poliza = @v_num_poliza
		
		IF (@v_cantidad_beneficiarios = 5)
		BEGIN
			raiserror('Error, no se pueden asociar más de 5 benefiarios al seguro.',10,1);
			rollback transaction;
		END
		
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) -- Cuando es INSERT
    BEGIN
    	IF (@v_porcentaje_total + (SELECT porcentaje FROM INSERTED) > 1) -- Si la suma de los porcentaje mas el nuevo, es > 1
			BEGIN
				raiserror('Error, no se pueden asociar más de 5 benefiarios al seguro.',10,1);
				rollback transaction;
			END
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) -- Cuando es UPDATE
    BEGIN
    	IF (@v_porcentaje_total + (SELECT porcentaje FROM INSERTED) - (SELECT porcentaje FROM DELETED) > 1)  -- Si la suma de los porcentajes reemplazando el nuevo, es > 1
			BEGIN
				raiserror('Error, el porcentaje dado a los beneficiarios rebasa el 100%.',10,1);
				rollback transaction;
			END
    END
	END
	ELSE
	BEGIN
		raiserror('Error, no se pueden asociar benefiarios a un seguro que no es de vida.',10,1);
		rollback transaction;		
	END	
END
GO