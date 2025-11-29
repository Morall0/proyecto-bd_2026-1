/* 
   seguridad.sql
   Autor: Yasser Vladimir Cruz Miranda
   Fecha: 29/11/2025
   Descripción: Script de seguridad para la BD Aseguradora
*/

-- 1. Crear Roles
CREATE ROLE rol_admin;
CREATE ROLE rol_cotizador;
CREATE ROLE rol_gerente;

-- 2. Crear Logins (nivel servidor)
CREATE LOGIN admin_seguro WITH PASSWORD = 'Admin';
CREATE LOGIN cotizador_seguro WITH PASSWORD = 'Cotiza';
CREATE LOGIN gerente_seguro WITH PASSWORD = 'Gerente';

-- 3. Crear Usuarios (nivel base de datos)
USE Aseguradora;
CREATE USER admin_seguro FOR LOGIN admin_seguro;
CREATE USER cotizador_seguro FOR LOGIN cotizador_seguro;
CREATE USER gerente_seguro FOR LOGIN gerente_seguro;

-- 4. Asignar Roles a Usuarios
ALTER ROLE rol_admin ADD MEMBER admin_seguro;
ALTER ROLE rol_cotizador ADD MEMBER cotizador_seguro;
ALTER ROLE rol_gerente ADD MEMBER gerente_seguro;

-- 5. Permisos
-- Administrador: control total
GRANT CONTROL ON DATABASE::Aseguradora TO rol_admin;

-- Cotizador: puede insertar y consultar clientes, pólizas y cotizaciones
GRANT SELECT, INSERT, UPDATE ON dbo.Cliente TO rol_cotizador;
GRANT SELECT, INSERT, UPDATE ON dbo.Poliza TO rol_cotizador;
GRANT SELECT, INSERT, UPDATE ON dbo.Cotizacion TO rol_cotizador;

-- Gerente: solo lectura de reportes y estadísticas
GRANT SELECT ON dbo.Cliente TO rol_gerente;
GRANT SELECT ON dbo.Poliza TO rol_gerente;
GRANT SELECT ON dbo.Cotizacion TO rol_gerente;
GRANT SELECT ON dbo.Siniestro TO rol_gerente;
GRANT SELECT ON dbo.Pago TO rol_gerente;

-- 6. Restricciones adicionales
-- Impedir que el cotizador elimine registros
DENY DELETE ON dbo.Cliente TO rol_cotizador;
DENY DELETE ON dbo.Poliza TO rol_cotizador;
DENY DELETE ON dbo.Cotizacion TO rol_cotizador;
