/*
 * AUTOR:
 * 		ALAN MAURICIO MORALES LÓPEZ
 * 		LUIS ADRÍAN GONZALEZ FALCÓN
 * DESCRIPCION: SCRIPT DDL PARA LA BASE DE DATOS 'EL_BUEN_RETIRO'
 * FECHA: 26/11/2025
 */

/* 
 * CREACIÓN DE LA BASE DE DATOS
 */

CREATE DATABASE EL_BUEN_RETIRO;
go

USE EL_BUEN_RETIRO;

/* 
 * CREACIÓN DE LOS ESQUEMAS
 */

CREATE SCHEMA CATALOGO
go

CREATE SCHEMA CLIENTE
go

CREATE SCHEMA VENTAS
go

CREATE SCHEMA SEGURO
go

CREATE SCHEMA TRABAJADOR
go

/* 
 * TABLA ESTADO 
 */

CREATE TABLE CATALOGO.ESTADO(
    estado_id        tinyint			    IDENTITY(1,1) NOT NULL,
    nombre_estado    varchar(40)      NOT NULL,
    CONSTRAINT estado_estado_id_pk PRIMARY KEY (estado_id)
)
go

/* 
 * TABLA MUNICIPIO 
 */

CREATE TABLE CATALOGO.MUNICIPIO(
    municipio_id        smallint    		IDENTITY(1,1) NOT NULL,
    nombre_municipio    varchar(100)     NOT NULL,
    estado_id        		tinyint    			NOT NULL,
    CONSTRAINT municipio_municipio_id_pk PRIMARY KEY (municipio_id),
    CONSTRAINT municipio_estado_id_fk FOREIGN KEY (estado_id) 
    	REFERENCES CATALOGO.ESTADO(estado_id)
)
go

/* 
 * TABLA COLONIA 
 */

CREATE TABLE CATALOGO.COLONIA(
    colonia_id          int    					IDENTITY(1,1) NOT NULL,
    nombre_colonia    	varchar(100)     NOT NULL,
    codigo_postal       varchar(5)      NOT NULL,
    municipio_id        smallint		    NOT NULL,
    CONSTRAINT colonia_colonia_id_pk PRIMARY KEY CLUSTERED (colonia_id),
    CONSTRAINT colonia_municipio_id_fk FOREIGN KEY (municipio_id)
    	REFERENCES CATALOGO.MUNICIPIO(municipio_id),
    CONSTRAINT colonia_codigo_postal_chk CHECK (LEN(codigo_postal)=5)
)
GO

/* 
 * TABLA DIRECCION 
 */

CREATE TABLE CLIENTE.DIRECCION(
    direccion_id    bigint    			 IDENTITY(1,1) NOT NULL,
    num_ext         numeric(3,0)     NOT NULL,
    num_int         numeric(3,0)     NULL,
    calle           varchar(40)      NOT NULL,
    colonia_id      int					     NOT NULL,
    CONSTRAINT direccion_direccion_id_pk PRIMARY KEY CLUSTERED (direccion_id),
    CONSTRAINT direccion_colonia_id_fk FOREIGN KEY (colonia_id)
    	REFERENCES CATALOGO.COLONIA(colonia_id)
)
go

/* 
 * TABLA CLIENTE 
 */

CREATE TABLE CLIENTE.CLIENTE(
    cliente_id            bigint     				IDENTITY(1,1) NOT NULL,
--  edad                  numeric(3,0)      NOT NULL, AGREGAR EN LA VISTA O EN LAS CONSULTAS 
    nombre                varchar(100)      NOT NULL,
    apellido_pat          varchar(50)       NOT NULL,
    apellido_mat          varchar(50)       NULL,
    tipo_cliente          varchar(1)        NOT NULL,
    rfc                   varchar(13)       NULL,
    curp                  varchar(18)       NULL,
    fecha_nacimiento      date              NOT NULL,
    direccion_id          bigint			      NOT NULL,
    CONSTRAINT cliente_cliente_id_pk PRIMARY KEY CLUSTERED (cliente_id),
    CONSTRAINT cliente_direccion_id_fk FOREIGN KEY (direccion_id)
    	REFERENCES CLIENTE.DIRECCION(direccion_id),
    CONSTRAINT cliente_tipo_cliente_chk CHECK (tipo_cliente IN ('M', 'N')),
    CONSTRAINT cliente_rfc_chk CHECK (LEN(rfc)=13),
    CONSTRAINT cliente_curp_chk CHECK (LEN(curp)=18),
    CONSTRAINT cliente_rfc_curp_chk CHECK ( -- AGREGAR LA CS1 EN TRIGGER
    	(tipo_cliente = 'N' AND curp IS NOT NULL AND rfc IS NULL) OR
    	(tipo_cliente = 'M' AND curp IS NULL AND rfc IS NOT NULL)
    )
)
go

/* 
 * TABLA CORREO_CLIENTE 
 */

CREATE TABLE CLIENTE.CORREO_CLIENTE(
    correo_cliente_id    bigint				    IDENTITY(1,1) NOT NULL,
    correo               varchar(320)     NOT NULL,
    cliente_id           bigint				    NOT NULL,
    CONSTRAINT correo_cliente_correo_cliente_id_pk PRIMARY KEY CLUSTERED (correo_cliente_id),
    CONSTRAINT correo_cliente_cliente_id_fk FOREIGN KEY (cliente_id)
    	REFERENCES CLIENTE.CLIENTE(cliente_id)
)
go

/* 
 * TABLA TELEFONO_CLIENTE 
 */

CREATE TABLE CLIENTE.TELEFONO_CLIENTE(
    telefono_cliente_id  bigint				    IDENTITY(1,1) NOT NULL,
    telefono             numeric(10,0)    NOT NULL,
    cliente_id           bigint				    NOT NULL,
    CONSTRAINT telefono_cliente_telefono_cliente_id_pk PRIMARY KEY CLUSTERED (telefono_cliente_id),
    CONSTRAINT telefono_cliente_cliente_id_fk FOREIGN KEY (cliente_id)
    	REFERENCES CLIENTE.CLIENTE(cliente_id)
)
go

/* 
 * TABLA ESTADO_COTIZACION 
 */

CREATE TABLE CATALOGO.ESTADO_COTIZACION(
		clave_estado 	varchar(1) 		NOT NULL,
	 	estado 				varchar(10) 	NOT NULL,
	 	CONSTRAINT estado_cotizacion_clave_estado_pk
	 		PRIMARY KEY (clave_estado),
		CONSTRAINT estado_cotizacion_clave_estado_chk CHECK (
			clave_estado IN ('P', 'A', 'R')
			)	
)
go

/* 
 * TABLA COTIZACION 
 */

CREATE TABLE VENTAS.COTIZACION(
    cotizacion_id               bigint    			 IDENTITY(1,1) NOT NULL,
    num_cotizacion              numeric(3,0)     NOT NULL,
    recordatorio                date             NULL,
    cliente_id                  bigint				   NOT NULL,
    fecha_cotizacion            date             NOT NULL,
    fecha_vencimiento_oferta    date             NOT NULL,
    clave_estado                varchar(1)       NOT NULL,
    prima_estimada              numeric(10, 2)   NOT NULL,
    CONSTRAINT cotizacion_cotizacion_id_pk PRIMARY KEY CLUSTERED (cotizacion_id),
    CONSTRAINT cotizacion_cliente_id_fk  FOREIGN KEY (cliente_id)
    	REFERENCES CLIENTE.CLIENTE(cliente_id),
    CONSTRAINT cotizacion_cliente_id_num_cotizacion_uk
    	UNIQUE (cliente_id, num_cotizacion),
    CONSTRAINT cotizacion_clave_estado_fk FOREIGN KEY (clave_estado)
    	REFERENCES CATALOGO.ESTADO_COTIZACION(clave_estado)
)
go

/* 
 * TABLA BITACORA_COTIZACION 
 */

CREATE TABLE VENTAS.BITACORA_COTIZACION(
		bitacora_cotizacion_id		bigint				IDENTITY(1,1) NOT NULL,
		fecha_cambio							DATE					NOT NULL,
		cotizacion_id							bigint 				NOT NULL,
		clave_estado							varchar(1)		NOT NULL,	
	 	CONSTRAINT bitacora_cotizacion_bitacora_cotizacion_id_pk
	 		PRIMARY KEY (bitacora_cotizacion_id),
	 	CONSTRAINT bitacora_cotizacion_cotizacion_id_fk FOREIGN KEY (cotizacion_id)
	 		REFERENCES VENTAS.COTIZACION(cotizacion_id),
	 	CONSTRAINT bitacora_cotizacion_clave_estado_fk FOREIGN KEY (clave_estado)
	 		REFERENCES CATALOGO.ESTADO_COTIZACION(clave_estado)
)
go

/* 
 * TABLA SEGURO 
 */

CREATE TABLE SEGURO.SEGURO(
    clave_seguro           bigint						IDENTITY(1,1) NOT NULL,
    tipo_seguro            varchar(1)       NOT NULL,
    descripcion            varchar(255)     NOT NULL,
    nombre                 varchar(50)      NOT NULL,
    vigencia_min           numeric(3,0)     NOT NULL,
    monto_asegurado_min    numeric(10,2)    NOT NULL,
    CONSTRAINT seguro_clave_seguro_pk PRIMARY KEY CLUSTERED (clave_seguro),
    CONSTRAINT seguro_tipo_seguro_chk CHECK (tipo_seguro IN ('A', 'R', 'V'))
)
GO

/* 
 * TABLA COTIZACION_SEGURO 
 */

CREATE TABLE VENTAS.COTIZACION_SEGURO(
		cotizacion_seguro_id		bigint			IDENTITY(1,1) NOT NULL,    
		clave_seguro           	bigint			NOT NULL,
    cotizacion_id          	bigint	    NOT NULL,
    CONSTRAINT cotizacion_seguro_cotizacion_seguro_id_pk 
    	PRIMARY KEY CLUSTERED (cotizacion_seguro_id),
    CONSTRAINT cotizacion_seguro_cotizacion_id_fk FOREIGN KEY (cotizacion_id)
    	REFERENCES VENTAS.COTIZACION(cotizacion_id),
    CONSTRAINT cotizacion_seguro_clave_seguro_fk FOREIGN KEY (clave_seguro)
    	REFERENCES SEGURO.SEGURO(clave_seguro),
    CONSTRAINT cotizacion_seguro_clave_seguro_cotizacion_id_uk 
    	UNIQUE (clave_seguro, cotizacion_id)
)
go

/* 
 * TABLA SEGURO_AUTO 
 */

CREATE TABLE SEGURO.SEGURO_AUTO(
    clave_seguro     bigint				    NOT NULL,
    cobert_basica    varchar(100)     NULL,
    CONSTRAINT seguro_auto_clave_seguro_pk PRIMARY KEY (clave_seguro),
    CONSTRAINT seguro_auto_clave_seguro_fk FOREIGN KEY (clave_seguro)
    	REFERENCES SEGURO.SEGURO(clave_seguro)
)
go

/* 
 * TABLA SEGURO_RETIRO 
 */

CREATE TABLE SEGURO.SEGURO_RETIRO(
    clave_seguro              bigint			     NOT NULL,
    edad_retiro               numeric(2,0)     NOT NULL,
    aportacion_mensual_min    numeric(10,2)    NOT NULL,
    CONSTRAINT seguro_retiro_clave_seguro_pk PRIMARY KEY (clave_seguro),
    CONSTRAINT seguro_retiro_clave_seguro_fk FOREIGN KEY (clave_seguro)
    	REFERENCES SEGURO.SEGURO(clave_seguro)
)
go

/* 
 * TABLA SEGURO_VIDA 
 */

CREATE TABLE SEGURO.SEGURO_VIDA(
    clave_seguro       bigint				    NOT NULL,
    edad_max           numeric(2,0)     NOT NULL,
    CONSTRAINT seguro_vida_clave_seguro_pk PRIMARY KEY (clave_seguro),
    CONSTRAINT seguro_vida_clave_seguro_fk FOREIGN KEY (clave_seguro)
    	REFERENCES SEGURO.SEGURO(clave_seguro)
)
go

/* 
 * TABLA PARENTESCO 
 */

CREATE TABLE CATALOGO.PARENTESCO(
    parentesco_id    tinyint    		 IDENTITY(1,1) NOT NULL,
    parentesco       varchar(20)     NOT NULL,
    CONSTRAINT parentesco_parantesco_id_pk PRIMARY KEY CLUSTERED (parentesco_id)
)
go

/* 
 * TABLA BENEFICIARIO 
 */

CREATE TABLE SEGURO.BENEFICIARIO(
    beneficiario_id    bigint						IDENTITY(1,1) NOT NULL,
    apellido_pat       varchar(50)      NOT NULL,
    apellido_mat       varchar(50)      NULL,
    nombre             varchar(100)     NOT NULL,
    parentesco_id      tinyint		     	NOT NULL,
    CONSTRAINT beneficiario_beneficiario_id_pk PRIMARY KEY CLUSTERED (beneficiario_id),
    CONSTRAINT beneficiario_parentesco_id_fk FOREIGN KEY (parentesco_id)
    	REFERENCES CATALOGO.PARENTESCO(parentesco_id)
)
go

/* 
 * TABLA EMPLEADO 
 */

CREATE TABLE TRABAJADOR.EMPLEADO(
    num_empleado       bigint    				IDENTITY(1,1) NOT NULL,
    tipo_empleado      varchar(1)       NOT NULL,
    nombre				     varchar(100)     NOT NULL,
    apellido_pat       varchar(50)      NOT NULL,
    apellido_mat       varchar(50)      NULL,
    CONSTRAINT empleado_num_empleado_pk PRIMARY KEY CLUSTERED (num_empleado),
    CONSTRAINT empleado_tipo_empleado_chk CHECK (tipo_empleado IN ('A', 'C'))
)
go

/* 
 * TABLA CORREDOR 
 */

CREATE TABLE TRABAJADOR.CORREDOR(
		num_empleado          bigint			     NOT NULL,
    cedula                numeric(8,0)     NOT NULL,
    comision					    numeric(2,2)     NOT NULL,
    fecha_contratacion    date             NOT NULL,
    num_supervisor        bigint			     NULL,
    CONSTRAINT corredor_num_empleado_pk PRIMARY KEY (num_empleado),
    CONSTRAINT corredor_num_empleado_fk FOREIGN KEY (num_empleado)
    	REFERENCES TRABAJADOR.EMPLEADO(num_empleado),
    CONSTRAINT corredor_cedula_uk UNIQUE (cedula),
    CONSTRAINT corredor_num_supervisor_fk FOREIGN KEY (num_supervisor)
    	REFERENCES TRABAJADOR.EMPLEADO(num_empleado),
    CONSTRAINT corredor_comision_chk CHECK (comision > 0 AND comision < 1)
)
GO

/* 
 * TABLA CODIGO_POSTAL_CORREDOR 
 */

CREATE TABLE TRABAJADOR.CODIGO_POSTAL_CORREDOR(
		codigo_postal_corredor_id 		bigint 			IDENTITY(1,1) NOT NULL,
		num_empleado          				bigint   		NOT NULL,
    codigo_postal         				varchar(5)	NOT NULL,
    CONSTRAINT codigo_postal_corredor_codigo_postal_corredor_id_pk
    	PRIMARY KEY CLUSTERED (codigo_postal_corredor_id),
    CONSTRAINT codigo_postal_corredor_num_empleado_fk 
    	FOREIGN KEY (num_empleado) REFERENCES TRABAJADOR.CORREDOR(num_empleado),
    CONSTRAINT corredor_codigo_postal_chk CHECK (LEN(codigo_postal) = 5)
)
go

/* 
 * TABLA AJUSTADOR 
 */

CREATE TABLE TRABAJADOR.AJUSTADOR(
    num_empleado    bigint    NOT NULL,
    CONSTRAINT ajustador_num_empleado_pk PRIMARY KEY (num_empleado),
    CONSTRAINT ajustador_num_empleado_fk FOREIGN KEY (num_empleado)
    	REFERENCES TRABAJADOR.EMPLEADO(num_empleado)
)
go

/* 
 * TABLA VEHICULO 
 */

CREATE TABLE SEGURO.VEHICULO(
    matricula          varchar(8)       NOT NULL,
    num_serie          varchar(17)      NOT NULL,
    modelo             varchar(50)      NOT NULL,
    marca              varchar(50)      NOT NULL,
    anio               numeric(4,0)     NOT NULL,
    valor_comercial    numeric(8,0)     NOT NULL,
    CONSTRAINT vehiculo_matricula_pk PRIMARY KEY CLUSTERED (matricula)
)
go

/* 
 * TABLA POLIZA 
 */

CREATE TABLE VENTAS.POLIZA(
    num_poliza          bigint    			 IDENTITY(1,1) NOT NULL,
    saldo_pend          decimal(15,2)    DEFAULT 0 NOT NULL,
    cliente_id          bigint			     NOT NULL,
    fecha_ini           date             NOT NULL,
    fecha_fin           date             NOT NULL,
    prima_total         decimal(10,2)    NOT NULL,
    num_empleado        bigint			     NULL,
    matricula           varchar(8)       NULL,
    clave_seguro        bigint			     NOT NULL,
    CONSTRAINT poliza_num_poliza_pk PRIMARY KEY CLUSTERED (num_poliza),
    CONSTRAINT poliza_cliente_id_fk FOREIGN KEY (cliente_id)
    	REFERENCES CLIENTE.CLIENTE(cliente_id),
    CONSTRAINT poliza_num_empleado_fk FOREIGN KEY (num_empleado)
    	REFERENCES TRABAJADOR.CORREDOR(num_empleado),
    CONSTRAINT poliza_matricula_fk FOREIGN KEY (matricula)
    	REFERENCES SEGURO.VEHICULO(matricula),
    CONSTRAINT poliza_clave_seguro_fk FOREIGN KEY (clave_seguro)
    	REFERENCES SEGURO.SEGURO(clave_seguro),
    CONSTRAINT poliza_fecha_ini_fecha_fin_chk CHECK (fecha_fin > fecha_ini),
    CONSTRAINT poliza_prima_total_chk CHECK (prima_total > 0)
)
go

/*
 * TABLA BENEFICIARIO_POLIZA
 */

CREATE TABLE VENTAS.BENEFICIARIO_POLIZA(
		beneficiario_poliza_id 	bigint 					 IDENTITY(1,1) NOT NULL,
		porcentaje         			numeric(3,2)     NOT NULL,
		beneficiario_id					bigint					 NOT NULL,
		num_poliza							bigint					 NOT NULL,
		CONSTRAINT beneficiario_poliza_beneficiario_poliza_id_pk 
			PRIMARY KEY CLUSTERED (beneficiario_poliza_id),
		CONSTRAINT beneficiario_poliza_beneficiario_id_fk
			FOREIGN KEY (beneficiario_id) REFERENCES SEGURO.BENEFICIARIO(beneficiario_id),
		CONSTRAINT beneficiario_poliza_num_poliza_fk
			FOREIGN KEY (num_poliza) REFERENCES VENTAS.POLIZA(num_poliza),
		CONSTRAINT beneficiario_poliza_beneficiario_id_num_poliza_uk
			UNIQUE (beneficiario_id, num_poliza),
		CONSTRAINT beneficiario_porcentaje_chk CHECK (porcentaje > 0 AND porcentaje <= 1)
)

/* 
 * TABLA SINIESTRO 
 */

CREATE TABLE SEGURO.SINIESTRO(
    siniestro_id           bigint			      IDENTITY(1,1) NOT NULL,
    num_siniestro          numeric(3,0)     NOT NULL,
--    dias_transcurridos     numeric(3,0)     NOT NULL, CREAR EN LA VISTA O EN LAS CONSULTAS
    lugar                  varchar(100)     NOT NULL,
    causa                  varchar(100)     NOT NULL,
    fecha_hora             datetime         NOT NULL,
    monto_indemnizacion    numeric(15,2)    NOT NULL,
    num_poliza             bigint				    NOT NULL,
    num_empleado           bigint				    NOT NULL,
    CONSTRAINT siniestro_siniestro_id_pk PRIMARY KEY CLUSTERED (siniestro_id),
    CONSTRAINT siniestro_num_poliza_fk FOREIGN KEY (num_poliza)
    	REFERENCES VENTAS.POLIZA(num_poliza),
    CONSTRAINT siniestro_num_empleado_fk FOREIGN KEY (num_empleado)
    	REFERENCES TRABAJADOR.AJUSTADOR(num_empleado),
    CONSTRAINT siniestro_num_siniestro_num_poliza_uk
    	UNIQUE (num_siniestro, num_poliza)
)
go

/* 
 * TABLA METODO_PAGO 
 */

CREATE TABLE CATALOGO.METODO_PAGO(
    metodo_pago_id    tinyint				IDENTITY(1,1) NOT NULL,
    metodo            varchar(20)   NOT NULL,
    CONSTRAINT metodo_pago_id_pk PRIMARY KEY (metodo_pago_id)
)
go

/* 
 * TABLA PAGO 
 */

CREATE TABLE VENTAS.PAGO(
    pago_id           bigint			     IDENTITY(1,1) NOT NULL,
    num_pago          numeric(5,0)     NOT NULL,
    num_poliza        bigint			     NOT NULL,
    fecha_pago        date             NOT NULL,
    monto             decimal(10,2)    NOT NULL,
    metodo_pago_id    tinyint			     NOT NULL,
    CONSTRAINT pago_pago_id_pk PRIMARY KEY CLUSTERED (pago_id),
    CONSTRAINT pago_num_poliza_fk FOREIGN KEY (num_poliza)
    	REFERENCES VENTAS.POLIZA(num_poliza),
    CONSTRAINT pago_num_pago_num_poliza_uk
    	UNIQUE (num_pago, num_poliza),
    CONSTRAINT pago_metodo_pago_id_fk FOREIGN KEY (metodo_pago_id)
    	REFERENCES CATALOGO.METODO_PAGO(metodo_pago_id)
)
go