/* 
   seguridad.sql
   AUTOR:
      ALAN MAURICIO MORALES LÓPEZ
      LUIS ADRIÁN GONZALEZ FALCÓN
      YASSER VLADIMIR CRUZ MIRANDA
   Fecha: 29/11/2025
   Descripción: Script de seguridad para la BD Aseguradora
*/

--Crear Roles
CREATE ROLE rol_admin;
CREATE ROLE rol_cotizador;
CREATE ROLE rol_gerente;

--Crear Logins (nivel servidor)
CREATE LOGIN admin_seguro WITH PASSWORD = 'Admin';
CREATE LOGIN cotizador_seguro WITH PASSWORD = 'Cotiza';
CREATE LOGIN gerente_seguro WITH PASSWORD = 'Gerente';

--Crear Usuarios (nivel base de datos)
USE EL_BUEN_RETIRO;
CREATE USER admin_seguro FOR LOGIN admin_seguro;
CREATE USER cotizador_seguro FOR LOGIN cotizador_seguro;
CREATE USER gerente_seguro FOR LOGIN gerente_seguro;

--Asignar Roles a Usuarios
ALTER ROLE rol_admin ADD MEMBER admin_seguro;
ALTER ROLE rol_cotizador ADD MEMBER cotizador_seguro;
ALTER ROLE rol_gerente ADD MEMBER gerente_seguro;

--PERMISOS
--Admin: control total
GRANT CONTROL ON DATABASE::Aseguradora TO rol_admin;

--Cotizador: puede insertar y consultar clientes, polizas y cotizaciones
GRANT SELECT, INSERT, UPDATE ON dbo.Cliente TO rol_cotizador;
GRANT SELECT, INSERT, UPDATE ON dbo.Poliza TO rol_cotizador;
GRANT SELECT, INSERT, UPDATE ON dbo.Cotizacion TO rol_cotizador;

--Gerente: solo lectura de reportes y estadisticas
GRANT SELECT ON dbo.Cliente TO rol_gerente;
GRANT SELECT ON dbo.Poliza TO rol_gerente;
GRANT SELECT ON dbo.Cotizacion TO rol_gerente;
GRANT SELECT ON dbo.Siniestro TO rol_gerente;
GRANT SELECT ON dbo.Pago TO rol_gerente;

--RESTRICCIONES 
--Impedir que el cotizador elimine registros
DENY DELETE ON dbo.Cliente TO rol_cotizador;
DENY DELETE ON dbo.Poliza TO rol_cotizador;
DENY DELETE ON dbo.Cotizacion TO rol_cotizador;


