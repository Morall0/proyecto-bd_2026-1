/*
 * AUTOR: 
 * 		ALAN MAURICIO MORALES LÓPEZ
 * 		LUIS ADRIÁN GONZALEZ FALCÓN
 * 		YASSER VLADIMIR CRUZ MIRANDA
 * DESCRIPCION: SCRIPT PARA VALIDAR TRIGGERS EN 'dml.sql'
 * FECHA: 26/11/2025
 */


 /*
 * Validacion del trigger tg_asigna_corredor_zona
 */
-- ALBERTO RUIS SOLIS (ID 1)
-- Valida que se inserte el empleado si no se asigna en la poliza
BEGIN TRAN
INSERT INTO VENTAS.POLIZA(cliente_id, fecha_ini, fecha_fin, prima_total, matricula, clave_seguro)
VALUES (1, '2025-11-30', '2026-11-30', 25000, 'ABC-101', 4);
SELECT TOP 1 * FROM VENTAS.POLIZA WHERE cliente_id = 1 ORDER BY fecha_fin
ROLLBACK TRAN


/*VERIFICANDO TRIGGER QUE VALIDA EDAD DE CONTRATACION*/
-- Creando un seguro de vida con edad maxima de 35 años 
BEGIN TRANSACTION
	INSERT INTO SEGURO.SEGURO (tipo_seguro, descripcion, nombre, vigencia_min, monto_asegurado_min)
	  VALUES('V', 'Seguro de vida para menores de 35 años', 'Vida muy Joven', 12, 50000);

	INSERT INTO SEGURO.SEGURO_VIDA (clave_seguro, edad_max)
	  VALUES((SELECT clave_seguro FROM SEGURO.SEGURO WHERE nombre = 'Vida muy Joven'), 35);

	-- INSERTANDO UN CLIENTE MAYOR SDE 35 AÑOS PARA QUE SALTE EL TRIGGER
	-- cliente con id=2 tiene 40 años 
	-- INTENtando contratar el seguro de vida para menores de 35 años

	INSERT INTO VENTAS.POLIZA(
	  saldo_pend,
	  cliente_id,
	  fecha_ini,
	  fecha_fin,
	  prima_total,
	  clave_seguro,
	  num_empleado
	)
	VALUES(
	  100000,
	  2,
	  GETDATE(),
	  DATEADD(YEAR, 1, GETDATE()),
	  150000,
	  (SELECT clave_seguro FROM SEGURO.SEGURO WHERE nombre = 'Vida muy Joven'),
	  5
	);
	-- Debe de arrojar error porque el cliente es mayor que la edad maxima
ROLLBACK TRANSACTION;
	/*select * from SEGURO.SEGURO
	select * from SEGURO.SEGURO_VIDA
	select * from VENTAS.POLIZA
	select * from cliente.CLIENTE
	delete from seguro.SEGURO where clave_seguro=12
	delete from VENTAS.POLIZA where num_poliza = 14*/


/*VERIFICANDO TRIGGER QUE REVISA EL SALDO PENDIENTE*/
-- num_poliza = 5 tiene saldo pendiente de 4000, pertenece a cliente 1, de monto total 8000
-- tiene 5 pagos de 800 cada uno 
-- insertando un pago que no supera el saldo pendiente para que el saldo pendiente
-- se recalcule
BEGIN TRANSACTION
	INSERT INTO VENTAS.PAGO(num_pago, fecha_pago, monto, metodo_pago_id, num_poliza)
	VALUES(6, GETDATE(), 3000, 4, 5);
	-- debe de tener el saldo pendeinte de 1000 despues de este pago
	SELECT saldo_pend FROM VENTAS.POLIZA WHERE num_poliza = 5; --debe mostrar 1000
	-- insertando un pago para que supere el saldo pendiente
	INSERT INTO VENTAS.PAGO(num_pago, fecha_pago, monto, metodo_pago_id, num_poliza)
	VALUES(7, GETDATE(), 5000, 4, 5);
	-- Debe arrojar error porque el pago supera el saldo pendiente,
ROLLBACK;
-- select * from VENTAS.PAGO


/*VERIFICANDO TRIGGER QUE REVISA EL REGISTRO EN BITACORA*/
BEGIN TRANSACTION;
	-- se selecciona a la cotizacion_id = 2
	-- estado antiguo: P
	-- estado actual: A
	select * from VENTAS.BITACORA_COTIZACION
	UPDATE VENTAS.COTIZACION SET clave_estado = 'A'	WHERE cotizacion_id = 2;
	
	-- Verificar que se haya hecho la bitacora
	SELECT * FROM VENTAS.BITACORA_COTIZACION;
	
ROLLBACK TRANSACTION;
