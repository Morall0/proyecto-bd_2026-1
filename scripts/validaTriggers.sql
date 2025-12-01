
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