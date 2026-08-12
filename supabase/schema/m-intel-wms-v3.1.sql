-- ================================================================
-- M-INTEL WMS Pro — BASE DE DATOS COMPLETA v3.1 DEFINITIVO
-- Arquitectura: ① DROP vistas → ② CREATE/REPAIR tablas →
--               ③ Limpiar datos → ④ Permisos → ⑤ Vistas →
--               ⑥ Índices → ⑦ Datos semilla
-- Validado: 0 referencias fuera de orden, 28 tablas, 3 vistas
-- ================================================================

-- ① DROP VISTAS
DROP VIEW IF EXISTS v_pendientes_aprobacion CASCADE;
DROP VIEW IF EXISTS v_ubicaciones_detalle   CASCADE;
DROP VIEW IF EXISTS v_stock                 CASCADE;

-- ② EXTENSIÓN Y FUNCIÓN updated_at
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE OR REPLACE FUNCTION fn_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

-- ================================================================
-- CENTROS
-- ================================================================
CREATE TABLE IF NOT EXISTS centros (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo      TEXT        NOT NULL,
  nombre      TEXT        NOT NULL,
  ciudad      TEXT,
  pais        TEXT        DEFAULT 'Panamá',
  responsable TEXT,
  telefono    TEXT,
  email       TEXT,
  activo      BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE centros ADD COLUMN IF NOT EXISTS ciudad      TEXT;
ALTER TABLE centros ADD COLUMN IF NOT EXISTS pais        TEXT DEFAULT 'Panamá';
ALTER TABLE centros ADD COLUMN IF NOT EXISTS responsable TEXT;
ALTER TABLE centros ADD COLUMN IF NOT EXISTS telefono    TEXT;
ALTER TABLE centros ADD COLUMN IF NOT EXISTS email       TEXT;
ALTER TABLE centros DROP CONSTRAINT IF EXISTS centros_codigo_key;
ALTER TABLE centros ADD  CONSTRAINT centros_codigo_key UNIQUE (codigo);

-- ================================================================
-- ALMACENES
-- ================================================================
CREATE TABLE IF NOT EXISTS almacenes (
  id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo       TEXT          NOT NULL,
  nombre       TEXT          NOT NULL,
  descripcion  TEXT,
  tipo         TEXT          DEFAULT 'General',
  centro_id    UUID,
  responsable  TEXT,
  telefono     TEXT,
  email        TEXT,
  direccion    TEXT,
  ciudad       TEXT          DEFAULT 'Ciudad de Panamá',
  capacidad_m2 NUMERIC(10,2),
  activo       BOOLEAN       NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS descripcion  TEXT;
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS tipo         TEXT          DEFAULT 'General';
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS centro_id    UUID;
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS responsable  TEXT;
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS telefono     TEXT;
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS email        TEXT;
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS direccion    TEXT;
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS ciudad       TEXT          DEFAULT 'Ciudad de Panamá';
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS capacidad_m2 NUMERIC(10,2);
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS activo       BOOLEAN       NOT NULL DEFAULT true;
ALTER TABLE almacenes ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now();
ALTER TABLE almacenes DROP CONSTRAINT IF EXISTS almacenes_codigo_key;
ALTER TABLE almacenes ADD  CONSTRAINT almacenes_codigo_key UNIQUE (codigo);
DROP   TRIGGER IF EXISTS trg_almacenes_updated ON almacenes;
CREATE TRIGGER trg_almacenes_updated BEFORE UPDATE ON almacenes
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- ================================================================
-- MARCAS
-- ================================================================
CREATE TABLE IF NOT EXISTS marcas (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre     TEXT        NOT NULL,
  activo     BOOLEAN     NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE marcas ADD COLUMN IF NOT EXISTS activo     BOOLEAN     NOT NULL DEFAULT true;
ALTER TABLE marcas ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE marcas DROP CONSTRAINT IF EXISTS marcas_nombre_key;
ALTER TABLE marcas ADD  CONSTRAINT marcas_nombre_key UNIQUE (nombre);

-- ================================================================
-- GRUPOS
-- ================================================================
CREATE TABLE IF NOT EXISTS grupos (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      TEXT        NOT NULL,
  descripcion TEXT,
  activo      BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE grupos ADD COLUMN IF NOT EXISTS descripcion TEXT;
ALTER TABLE grupos ADD COLUMN IF NOT EXISTS activo      BOOLEAN     NOT NULL DEFAULT true;
ALTER TABLE grupos DROP CONSTRAINT IF EXISTS grupos_nombre_key;
ALTER TABLE grupos ADD  CONSTRAINT grupos_nombre_key UNIQUE (nombre);

-- ================================================================
-- ARTÍCULOS (incluye columnas logísticas)
-- ================================================================
CREATE TABLE IF NOT EXISTS articulos (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo              TEXT          NOT NULL,
  descripcion         TEXT          NOT NULL,
  codigo_barras       TEXT,
  marca_id            UUID,
  grupo_id            UUID,
  unidad              TEXT          NOT NULL DEFAULT 'UND',
  precio_costo        NUMERIC(14,4) NOT NULL DEFAULT 0,
  precio_venta        NUMERIC(14,4),
  stock_min           NUMERIC(14,2) NOT NULL DEFAULT 0,
  stock_max           NUMERIC(14,2) NOT NULL DEFAULT 0,
  peso_kg             NUMERIC(10,3),
  volumen_m3          NUMERIC(10,4),
  requiere_lote       BOOLEAN       NOT NULL DEFAULT false,
  metodo_rotacion     TEXT          NOT NULL DEFAULT 'FEFO',
  abc_clase           TEXT          DEFAULT 'C',
  activo              BOOLEAN       NOT NULL DEFAULT true,
  und_por_caja        INTEGER       DEFAULT 1,
  cajas_por_palet     INTEGER       DEFAULT 1,
  peso_palet_kg       NUMERIC(10,3),
  alto_palet_cm       NUMERIC(8,2),
  tipo_palet          TEXT          DEFAULT 'Europalet',
  zona_entrada_id     UUID,
  zona_entrada_codigo TEXT,
  apilable            BOOLEAN       NOT NULL DEFAULT true,
  max_apilamiento     INTEGER       DEFAULT 1,
  codigo_palet        TEXT,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS codigo_barras       TEXT;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS marca_id            UUID;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS grupo_id            UUID;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS precio_venta        NUMERIC(14,4);
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS peso_kg             NUMERIC(10,3);
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS volumen_m3          NUMERIC(10,4);
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS requiere_lote       BOOLEAN       NOT NULL DEFAULT false;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS metodo_rotacion     TEXT          NOT NULL DEFAULT 'FEFO';
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS abc_clase           TEXT          DEFAULT 'C';
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS und_por_caja        INTEGER       DEFAULT 1;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS cajas_por_palet     INTEGER       DEFAULT 1;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS peso_palet_kg       NUMERIC(10,3);
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS alto_palet_cm       NUMERIC(8,2);
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS tipo_palet          TEXT          DEFAULT 'Europalet';
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS zona_entrada_id     UUID;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS zona_entrada_codigo TEXT;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS apilable            BOOLEAN       NOT NULL DEFAULT true;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS max_apilamiento     INTEGER       DEFAULT 1;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS codigo_palet        TEXT;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS activo              BOOLEAN       NOT NULL DEFAULT true;
ALTER TABLE articulos ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now();
ALTER TABLE articulos DROP CONSTRAINT IF EXISTS articulos_codigo_key;
ALTER TABLE articulos ADD  CONSTRAINT articulos_codigo_key UNIQUE (codigo);
DROP   TRIGGER IF EXISTS trg_articulos_updated ON articulos;
CREATE TRIGGER trg_articulos_updated BEFORE UPDATE ON articulos
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- ================================================================
-- PROVEEDORES
-- ================================================================
CREATE TABLE IF NOT EXISTS proveedores (
  id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo         TEXT          NOT NULL,
  nombre         TEXT          NOT NULL,
  ruc            TEXT,
  tipo           TEXT          DEFAULT 'Nacional',
  contacto       TEXT,
  telefono       TEXT,
  email          TEXT,
  direccion      TEXT,
  ciudad         TEXT,
  pais           TEXT          DEFAULT 'Panama',
  condicion_pago TEXT          DEFAULT '30 dias',
  dias_entrega   INTEGER       DEFAULT 7,
  calificacion   INTEGER       DEFAULT 5,
  activo         BOOLEAN       NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS ruc            TEXT;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS tipo           TEXT    DEFAULT 'Nacional';
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS contacto       TEXT;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS telefono       TEXT;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS email          TEXT;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS direccion      TEXT;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS ciudad         TEXT;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS pais           TEXT    DEFAULT 'Panama';
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS condicion_pago TEXT    DEFAULT '30 dias';
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS dias_entrega   INTEGER DEFAULT 7;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS calificacion   INTEGER DEFAULT 5;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS activo         BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE proveedores DROP CONSTRAINT IF EXISTS proveedores_codigo_key;
ALTER TABLE proveedores ADD  CONSTRAINT proveedores_codigo_key UNIQUE (codigo);
CREATE SEQUENCE IF NOT EXISTS seq_proveedores START 1;
CREATE OR REPLACE FUNCTION fn_codigo_proveedor() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
    NEW.codigo := 'PROV-' || LPAD(nextval('seq_proveedores')::text,4,'0');
  END IF; RETURN NEW;
END; $$;
DROP   TRIGGER IF EXISTS trg_prov_codigo ON proveedores;
CREATE TRIGGER trg_prov_codigo BEFORE INSERT ON proveedores
  FOR EACH ROW EXECUTE FUNCTION fn_codigo_proveedor();
DROP   TRIGGER IF EXISTS trg_proveedores_updated ON proveedores;
CREATE TRIGGER trg_proveedores_updated BEFORE UPDATE ON proveedores
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- ================================================================
-- CLIENTES
-- ================================================================
CREATE TABLE IF NOT EXISTS clientes (
  id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo         TEXT          NOT NULL,
  nombre         TEXT          NOT NULL,
  ruc            TEXT,
  tipo           TEXT          DEFAULT 'Empresa',
  segmento       TEXT          DEFAULT 'Regular',
  contacto       TEXT,
  telefono       TEXT,
  email          TEXT,
  direccion      TEXT,
  ciudad         TEXT,
  pais           TEXT          DEFAULT 'Panama',
  zona_entrega   TEXT,
  condicion_pago TEXT          DEFAULT 'Contado',
  limite_credito NUMERIC(14,2) DEFAULT 0,
  activo         BOOLEAN       NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS ruc            TEXT;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS tipo           TEXT    DEFAULT 'Empresa';
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS segmento       TEXT    DEFAULT 'Regular';
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS contacto       TEXT;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS telefono       TEXT;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS email          TEXT;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS direccion      TEXT;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS ciudad         TEXT;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS pais           TEXT    DEFAULT 'Panama';
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS zona_entrega   TEXT;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS condicion_pago TEXT    DEFAULT 'Contado';
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS limite_credito NUMERIC(14,2) DEFAULT 0;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS activo         BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE clientes DROP CONSTRAINT IF EXISTS clientes_codigo_key;
ALTER TABLE clientes ADD  CONSTRAINT clientes_codigo_key UNIQUE (codigo);
CREATE SEQUENCE IF NOT EXISTS seq_clientes START 1;
CREATE OR REPLACE FUNCTION fn_codigo_cliente() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
    NEW.codigo := 'CLI-' || LPAD(nextval('seq_clientes')::text,4,'0');
  END IF; RETURN NEW;
END; $$;
DROP   TRIGGER IF EXISTS trg_cli_codigo ON clientes;
CREATE TRIGGER trg_cli_codigo BEFORE INSERT ON clientes
  FOR EACH ROW EXECUTE FUNCTION fn_codigo_cliente();
DROP   TRIGGER IF EXISTS trg_clientes_updated ON clientes;
CREATE TRIGGER trg_clientes_updated BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- ================================================================
-- ZONAS
-- ================================================================
CREATE TABLE IF NOT EXISTS zonas (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  almacen_id  UUID        NOT NULL,
  codigo      TEXT        NOT NULL,
  nombre      TEXT        NOT NULL,
  descripcion TEXT,
  tipo        TEXT        DEFAULT 'General',
  activo      BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE zonas ADD COLUMN IF NOT EXISTS descripcion TEXT;
ALTER TABLE zonas ADD COLUMN IF NOT EXISTS tipo        TEXT    DEFAULT 'General';
ALTER TABLE zonas ADD COLUMN IF NOT EXISTS activo      BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE zonas DROP CONSTRAINT IF EXISTS zonas_almacen_id_codigo_key;
ALTER TABLE zonas ADD  CONSTRAINT zonas_almacen_id_codigo_key UNIQUE (almacen_id, codigo);

-- ================================================================
-- UBICACIONES  (zona_id siempre nullable — se llena via subquery)
-- ================================================================
CREATE TABLE IF NOT EXISTS ubicaciones (
  id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo       TEXT          NOT NULL,
  wh_id        TEXT,
  zona         TEXT,
  zona_id      UUID,
  pasillo      TEXT,
  nivel        TEXT,
  posicion     TEXT,
  tipo         TEXT          DEFAULT 'Rack',
  capacidad    INTEGER       DEFAULT 500,
  capacidad_kg NUMERIC(10,2) DEFAULT 1000,
  estado       TEXT          DEFAULT 'free',
  ocupada      BOOLEAN       NOT NULL DEFAULT false,
  activo       BOOLEAN       NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS wh_id        TEXT;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS zona         TEXT;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS zona_id      UUID;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS pasillo      TEXT;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS nivel        TEXT;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS posicion     TEXT;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS tipo         TEXT          DEFAULT 'Rack';
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS capacidad    INTEGER       DEFAULT 500;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS capacidad_kg NUMERIC(10,2) DEFAULT 1000;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS estado       TEXT          DEFAULT 'free';
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS ocupada      BOOLEAN       NOT NULL DEFAULT false;
ALTER TABLE ubicaciones ADD COLUMN IF NOT EXISTS activo       BOOLEAN       NOT NULL DEFAULT true;
ALTER TABLE ubicaciones DROP CONSTRAINT IF EXISTS ubicaciones_codigo_key;
ALTER TABLE ubicaciones ADD  CONSTRAINT ubicaciones_codigo_key UNIQUE (codigo);
ALTER TABLE ubicaciones ALTER COLUMN zona_id DROP NOT NULL;
ALTER TABLE ubicaciones ALTER COLUMN zona    DROP NOT NULL;
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN SELECT constraint_name FROM information_schema.table_constraints
           WHERE table_name='ubicaciones' AND table_schema='public'
             AND constraint_type='FOREIGN KEY'
  LOOP
    EXECUTE 'ALTER TABLE ubicaciones DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
  END LOOP;
END $$;

-- ================================================================
-- STOCK CENTRO
-- ================================================================
CREATE TABLE IF NOT EXISTS stock_centro (
  id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  centro_id    UUID          NOT NULL,
  articulo_id  UUID          NOT NULL,
  stock_actual NUMERIC(14,2) NOT NULL DEFAULT 0,
  updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE stock_centro ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE stock_centro DROP CONSTRAINT IF EXISTS sc_uq;
ALTER TABLE stock_centro ADD  CONSTRAINT sc_uq UNIQUE (centro_id, articulo_id);

-- ================================================================
-- CONFIGURACION ZONAS DE ENTRADA
-- ================================================================
CREATE TABLE IF NOT EXISTS configuracion_zonas_entrada (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  zona_id             UUID        NOT NULL,
  zona_codigo         TEXT        NOT NULL,
  almacen_id          UUID        NOT NULL,
  almacen_codigo      TEXT        NOT NULL,
  nombre_config       TEXT        NOT NULL,
  descripcion         TEXT,
  tipo_producto       TEXT        DEFAULT 'General',
  temperatura_min     NUMERIC(5,1),
  temperatura_max     NUMERIC(5,1),
  requiere_cuarentena BOOLEAN     NOT NULL DEFAULT false,
  activo              BOOLEAN     NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE configuracion_zonas_entrada ADD COLUMN IF NOT EXISTS descripcion         TEXT;
ALTER TABLE configuracion_zonas_entrada ADD COLUMN IF NOT EXISTS tipo_producto       TEXT    DEFAULT 'General';
ALTER TABLE configuracion_zonas_entrada ADD COLUMN IF NOT EXISTS temperatura_min     NUMERIC(5,1);
ALTER TABLE configuracion_zonas_entrada ADD COLUMN IF NOT EXISTS temperatura_max     NUMERIC(5,1);
ALTER TABLE configuracion_zonas_entrada ADD COLUMN IF NOT EXISTS requiere_cuarentena BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE configuracion_zonas_entrada ADD COLUMN IF NOT EXISTS activo              BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE configuracion_zonas_entrada DROP CONSTRAINT IF EXISTS cze_zona_alm_key;
ALTER TABLE configuracion_zonas_entrada ADD  CONSTRAINT cze_zona_alm_key UNIQUE (zona_id, tipo_producto);

-- ================================================================
-- STOCK
-- ================================================================
CREATE TABLE IF NOT EXISTS stock (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  sku         TEXT          NOT NULL,
  descripcion TEXT,
  categoria   TEXT,
  wh_id       TEXT          NOT NULL,
  disponible  NUMERIC(14,2) NOT NULL DEFAULT 0,
  reservado   NUMERIC(14,2) NOT NULL DEFAULT 0,
  ubicacion   TEXT,
  lote        TEXT,
  vencimiento DATE,
  stock_min   NUMERIC(14,2) DEFAULT 0,
  created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE stock ADD COLUMN IF NOT EXISTS descripcion TEXT;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS categoria   TEXT;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS ubicacion   TEXT;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS lote        TEXT;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS vencimiento DATE;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS stock_min   NUMERIC(14,2) DEFAULT 0;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS reservado   NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now();
ALTER TABLE stock DROP CONSTRAINT IF EXISTS stock_sku_wh_key;
ALTER TABLE stock ADD  CONSTRAINT stock_sku_wh_key UNIQUE (sku, wh_id);

-- ================================================================
-- ASN + ASN_LINEAS
-- ================================================================
CREATE TABLE IF NOT EXISTS asn (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  numero      TEXT        NOT NULL,
  wh_id       TEXT        NOT NULL,
  proveedor   TEXT,
  po_ref      TEXT,
  batch       TEXT,
  eta         TIMESTAMPTZ,
  carrier     TEXT,
  estado      TEXT        NOT NULL DEFAULT 'En transito',
  observacion TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE asn ADD COLUMN IF NOT EXISTS po_ref      TEXT;
ALTER TABLE asn ADD COLUMN IF NOT EXISTS batch       TEXT;
ALTER TABLE asn ADD COLUMN IF NOT EXISTS carrier     TEXT;
ALTER TABLE asn ADD COLUMN IF NOT EXISTS observacion TEXT;
ALTER TABLE asn ADD COLUMN IF NOT EXISTS updated_at  TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE asn DROP CONSTRAINT IF EXISTS asn_numero_key;
ALTER TABLE asn ADD  CONSTRAINT asn_numero_key UNIQUE (numero);

CREATE TABLE IF NOT EXISTS asn_lineas (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  asn_id      UUID          NOT NULL,
  sku         TEXT          NOT NULL,
  descripcion TEXT,
  cantidad    NUMERIC(14,2) DEFAULT 0,
  recibido    NUMERIC(14,2) DEFAULT 0,
  lote        TEXT,
  vencimiento DATE,
  created_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE asn_lineas ADD COLUMN IF NOT EXISTS descripcion TEXT;
ALTER TABLE asn_lineas ADD COLUMN IF NOT EXISTS recibido    NUMERIC(14,2) DEFAULT 0;
ALTER TABLE asn_lineas ADD COLUMN IF NOT EXISTS lote        TEXT;
ALTER TABLE asn_lineas ADD COLUMN IF NOT EXISTS vencimiento DATE;

-- ================================================================
-- PEDIDOS DE ENTRADA
-- ================================================================
CREATE TABLE IF NOT EXISTS pedidos_entrada (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  numero              TEXT        NOT NULL,
  wh_id               TEXT        NOT NULL DEFAULT '',
  proveedor_id        UUID,
  proveedor           TEXT,
  tipo                TEXT        DEFAULT 'Compra',
  po_ref              TEXT,
  fecha_esperada      DATE,
  carrier             TEXT,
  prioridad           TEXT        DEFAULT 'Normal',
  notas               TEXT,
  estado              TEXT        NOT NULL DEFAULT 'Pendiente Aprobacion',
  liberado            BOOLEAN     NOT NULL DEFAULT false,
  liberado_por        TEXT,
  liberado_at         TIMESTAMPTZ,
  rechazado_por       TEXT,
  rechazado_at        TIMESTAMPTZ,
  motivo_rechazo      TEXT,
  creado_por          TEXT,
  requiere_aprobacion BOOLEAN     NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS wh_id               TEXT        NOT NULL DEFAULT '';
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS proveedor_id        UUID;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS proveedor           TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS tipo                TEXT        DEFAULT 'Compra';
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS po_ref              TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS fecha_esperada      DATE;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS carrier             TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS prioridad           TEXT        DEFAULT 'Normal';
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS notas               TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS estado              TEXT        NOT NULL DEFAULT 'Pendiente Aprobacion';
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS liberado            BOOLEAN     NOT NULL DEFAULT false;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS liberado_por        TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS liberado_at         TIMESTAMPTZ;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS rechazado_por       TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS rechazado_at        TIMESTAMPTZ;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS motivo_rechazo      TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS creado_por          TEXT;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS requiere_aprobacion BOOLEAN     NOT NULL DEFAULT true;
ALTER TABLE pedidos_entrada ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ NOT NULL DEFAULT now();
DO $$ BEGIN ALTER TABLE pedidos_entrada ALTER COLUMN proveedor DROP NOT NULL;
EXCEPTION WHEN OTHERS THEN NULL; END $$;
UPDATE pedidos_entrada SET wh_id='' WHERE wh_id IS NULL;
ALTER TABLE pedidos_entrada DROP CONSTRAINT IF EXISTS pedidos_entrada_numero_key;
ALTER TABLE pedidos_entrada ADD  CONSTRAINT pedidos_entrada_numero_key UNIQUE (numero);
ALTER TABLE pedidos_entrada DROP CONSTRAINT IF EXISTS pedidos_entrada_estado_check;
ALTER TABLE pedidos_entrada ADD  CONSTRAINT pedidos_entrada_estado_check
  CHECK (estado IN ('Borrador','Pendiente Aprobacion','Liberado','En proceso','Parcial','Completado','Rechazado','Cancelado'));
DROP   TRIGGER IF EXISTS trg_pe_updated ON pedidos_entrada;
CREATE TRIGGER trg_pe_updated BEFORE UPDATE ON pedidos_entrada
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- ================================================================
-- PE_LINEAS
-- ================================================================
CREATE TABLE IF NOT EXISTS pe_lineas (
  id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id    UUID          NOT NULL,
  sku          TEXT          NOT NULL,
  descripcion  TEXT,
  cantidad_ped NUMERIC(14,2) NOT NULL DEFAULT 0,
  cantidad_rec NUMERIC(14,2) NOT NULL DEFAULT 0,
  lote         TEXT,
  vencimiento  DATE,
  precio_costo NUMERIC(14,4),
  estado       TEXT          NOT NULL DEFAULT 'Pendiente',
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE pe_lineas ADD COLUMN IF NOT EXISTS descripcion  TEXT;
ALTER TABLE pe_lineas ADD COLUMN IF NOT EXISTS cantidad_rec NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE pe_lineas ADD COLUMN IF NOT EXISTS lote         TEXT;
ALTER TABLE pe_lineas ADD COLUMN IF NOT EXISTS vencimiento  DATE;
ALTER TABLE pe_lineas ADD COLUMN IF NOT EXISTS precio_costo NUMERIC(14,4);
ALTER TABLE pe_lineas ADD COLUMN IF NOT EXISTS estado       TEXT NOT NULL DEFAULT 'Pendiente';
ALTER TABLE pe_lineas DROP CONSTRAINT IF EXISTS pe_lineas_estado_check;
ALTER TABLE pe_lineas ADD  CONSTRAINT pe_lineas_estado_check
  CHECK (estado IN ('Pendiente','Parcial','Completado'));

-- ================================================================
-- PEDIDOS DE SALIDA
-- ================================================================
CREATE TABLE IF NOT EXISTS pedidos_salida (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  numero              TEXT        NOT NULL,
  wh_id               TEXT        NOT NULL DEFAULT '',
  cliente_id          UUID,
  cliente             TEXT,
  tipo                TEXT        DEFAULT 'Venta',
  direccion_entrega   TEXT,
  fecha_prometida     DATE,
  prioridad           TEXT        DEFAULT 'Normal',
  carrier             TEXT,
  tracking            TEXT,
  notas               TEXT,
  estado              TEXT        NOT NULL DEFAULT 'Pendiente Aprobacion',
  liberado            BOOLEAN     NOT NULL DEFAULT false,
  liberado_por        TEXT,
  liberado_at         TIMESTAMPTZ,
  rechazado_por       TEXT,
  rechazado_at        TIMESTAMPTZ,
  motivo_rechazo      TEXT,
  creado_por          TEXT,
  requiere_aprobacion BOOLEAN     NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS wh_id               TEXT        NOT NULL DEFAULT '';
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS cliente_id          UUID;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS cliente             TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS tipo                TEXT        DEFAULT 'Venta';
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS direccion_entrega   TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS fecha_prometida     DATE;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS prioridad           TEXT        DEFAULT 'Normal';
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS carrier             TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS tracking            TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS notas               TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS estado              TEXT        NOT NULL DEFAULT 'Pendiente Aprobacion';
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS liberado            BOOLEAN     NOT NULL DEFAULT false;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS liberado_por        TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS liberado_at         TIMESTAMPTZ;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS rechazado_por       TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS rechazado_at        TIMESTAMPTZ;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS motivo_rechazo      TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS creado_por          TEXT;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS requiere_aprobacion BOOLEAN     NOT NULL DEFAULT true;
ALTER TABLE pedidos_salida ADD COLUMN IF NOT EXISTS updated_at          TIMESTAMPTZ NOT NULL DEFAULT now();
DO $$ BEGIN ALTER TABLE pedidos_salida ALTER COLUMN cliente DROP NOT NULL;
EXCEPTION WHEN OTHERS THEN NULL; END $$;
UPDATE pedidos_salida SET wh_id='' WHERE wh_id IS NULL;
ALTER TABLE pedidos_salida DROP CONSTRAINT IF EXISTS pedidos_salida_numero_key;
ALTER TABLE pedidos_salida ADD  CONSTRAINT pedidos_salida_numero_key UNIQUE (numero);
ALTER TABLE pedidos_salida DROP CONSTRAINT IF EXISTS pedidos_salida_estado_check;
ALTER TABLE pedidos_salida ADD  CONSTRAINT pedidos_salida_estado_check
  CHECK (estado IN ('Borrador','Pendiente Aprobacion','Liberado','En preparacion','Picking','Listo','Despachado','Rechazado','Cancelado'));
DROP   TRIGGER IF EXISTS trg_ps_updated ON pedidos_salida;
CREATE TRIGGER trg_ps_updated BEFORE UPDATE ON pedidos_salida
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- ================================================================
-- PS_LINEAS
-- ================================================================
CREATE TABLE IF NOT EXISTS ps_lineas (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id     UUID          NOT NULL,
  sku           TEXT          NOT NULL,
  descripcion   TEXT,
  cantidad_ped  NUMERIC(14,2) NOT NULL DEFAULT 0,
  cantidad_prep NUMERIC(14,2) NOT NULL DEFAULT 0,
  lote          TEXT,
  ubicacion     TEXT,
  precio_venta  NUMERIC(14,4),
  estado        TEXT          NOT NULL DEFAULT 'Pendiente',
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE ps_lineas ADD COLUMN IF NOT EXISTS descripcion   TEXT;
ALTER TABLE ps_lineas ADD COLUMN IF NOT EXISTS cantidad_prep NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE ps_lineas ADD COLUMN IF NOT EXISTS lote          TEXT;
ALTER TABLE ps_lineas ADD COLUMN IF NOT EXISTS ubicacion     TEXT;
ALTER TABLE ps_lineas ADD COLUMN IF NOT EXISTS precio_venta  NUMERIC(14,4);
ALTER TABLE ps_lineas ADD COLUMN IF NOT EXISTS estado        TEXT NOT NULL DEFAULT 'Pendiente';
ALTER TABLE ps_lineas DROP CONSTRAINT IF EXISTS ps_lineas_estado_check;
ALTER TABLE ps_lineas ADD  CONSTRAINT ps_lineas_estado_check
  CHECK (estado IN ('Pendiente','En picking','Listo'));

-- ================================================================
-- CARROS DE ENTRADA + CARRO_LINEAS
-- ================================================================
CREATE TABLE IF NOT EXISTS carros_entrada (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  numero     TEXT        NOT NULL,
  tipo       TEXT        NOT NULL DEFAULT 'UNICO',
  wh_id      TEXT        NOT NULL,
  asn_id     UUID,
  operador   TEXT,
  estado     TEXT        NOT NULL DEFAULT 'ABIERTO',
  notas      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE carros_entrada ADD COLUMN IF NOT EXISTS asn_id     UUID;
ALTER TABLE carros_entrada ADD COLUMN IF NOT EXISTS operador   TEXT;
ALTER TABLE carros_entrada ADD COLUMN IF NOT EXISTS notas      TEXT;
ALTER TABLE carros_entrada ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE carros_entrada DROP CONSTRAINT IF EXISTS carros_entrada_numero_key;
ALTER TABLE carros_entrada ADD  CONSTRAINT carros_entrada_numero_key UNIQUE (numero);
ALTER TABLE carros_entrada DROP CONSTRAINT IF EXISTS carros_entrada_tipo_check;
ALTER TABLE carros_entrada ADD  CONSTRAINT carros_entrada_tipo_check
  CHECK (tipo IN ('UNICO','MULTIPLE'));
ALTER TABLE carros_entrada DROP CONSTRAINT IF EXISTS carros_entrada_estado_check;
ALTER TABLE carros_entrada ADD  CONSTRAINT carros_entrada_estado_check
  CHECK (estado IN ('ABIERTO','EN_USO','UBICADO','CERRADO'));
DROP   TRIGGER IF EXISTS trg_carro_updated ON carros_entrada;
CREATE TRIGGER trg_carro_updated BEFORE UPDATE ON carros_entrada
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

CREATE TABLE IF NOT EXISTS carro_lineas (
  id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  carro_id          UUID          NOT NULL,
  sku               TEXT          NOT NULL,
  descripcion       TEXT,
  cantidad          NUMERIC(14,2) NOT NULL DEFAULT 0,
  lote              TEXT,
  vencimiento       DATE,
  ubicacion_destino TEXT,
  zona_entrada      TEXT,
  ubicado           BOOLEAN       NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE carro_lineas ADD COLUMN IF NOT EXISTS descripcion       TEXT;
ALTER TABLE carro_lineas ADD COLUMN IF NOT EXISTS lote              TEXT;
ALTER TABLE carro_lineas ADD COLUMN IF NOT EXISTS vencimiento       DATE;
ALTER TABLE carro_lineas ADD COLUMN IF NOT EXISTS ubicacion_destino TEXT;
ALTER TABLE carro_lineas ADD COLUMN IF NOT EXISTS zona_entrada      TEXT;
ALTER TABLE carro_lineas ADD COLUMN IF NOT EXISTS ubicado           BOOLEAN NOT NULL DEFAULT false;

-- ================================================================
-- WAVES
-- ================================================================
CREATE TABLE IF NOT EXISTS waves (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  numero      TEXT        NOT NULL,
  wh_id       TEXT        NOT NULL,
  tipo        TEXT,
  estrategia  TEXT,
  operador    TEXT,
  prioridad   TEXT        DEFAULT 'Normal',
  ordenes     INTEGER     DEFAULT 0,
  lineas      INTEGER     DEFAULT 0,
  completadas INTEGER     DEFAULT 0,
  estado      TEXT        NOT NULL DEFAULT 'En cola',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE waves ADD COLUMN IF NOT EXISTS tipo        TEXT;
ALTER TABLE waves ADD COLUMN IF NOT EXISTS estrategia  TEXT;
ALTER TABLE waves ADD COLUMN IF NOT EXISTS operador    TEXT;
ALTER TABLE waves ADD COLUMN IF NOT EXISTS prioridad   TEXT    DEFAULT 'Normal';
ALTER TABLE waves ADD COLUMN IF NOT EXISTS ordenes     INTEGER DEFAULT 0;
ALTER TABLE waves ADD COLUMN IF NOT EXISTS lineas      INTEGER DEFAULT 0;
ALTER TABLE waves ADD COLUMN IF NOT EXISTS completadas INTEGER DEFAULT 0;
ALTER TABLE waves ADD COLUMN IF NOT EXISTS updated_at  TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE waves DROP CONSTRAINT IF EXISTS waves_numero_key;
ALTER TABLE waves ADD  CONSTRAINT waves_numero_key UNIQUE (numero);

-- ================================================================
-- RF_TASKS
-- ================================================================
CREATE TABLE IF NOT EXISTS rf_tasks (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  wave_id     UUID,
  operador    TEXT,
  wh_id       TEXT,
  sku         TEXT          NOT NULL,
  descripcion TEXT,
  ubicacion   TEXT,
  cantidad    NUMERIC(14,2) DEFAULT 0,
  completada  NUMERIC(14,2) DEFAULT 0,
  estado      TEXT          DEFAULT 'pendiente',
  created_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE rf_tasks ADD COLUMN IF NOT EXISTS wave_id    UUID;
ALTER TABLE rf_tasks ADD COLUMN IF NOT EXISTS operador   TEXT;
ALTER TABLE rf_tasks ADD COLUMN IF NOT EXISTS wh_id      TEXT;
ALTER TABLE rf_tasks ADD COLUMN IF NOT EXISTS descripcion TEXT;
ALTER TABLE rf_tasks ADD COLUMN IF NOT EXISTS ubicacion  TEXT;
ALTER TABLE rf_tasks ADD COLUMN IF NOT EXISTS completada NUMERIC(14,2) DEFAULT 0;
ALTER TABLE rf_tasks DROP CONSTRAINT IF EXISTS rf_tasks_estado_check;
ALTER TABLE rf_tasks ADD  CONSTRAINT rf_tasks_estado_check
  CHECK (estado IN ('pendiente','en_proceso','completado','omitido'));

-- ================================================================
-- SHIPMENTS
-- ================================================================
CREATE TABLE IF NOT EXISTS shipments (
  id         UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  numero     TEXT          NOT NULL,
  wh_id      TEXT          NOT NULL,
  cliente    TEXT,
  carrier    TEXT,
  tracking   TEXT,
  bultos     INTEGER       DEFAULT 0,
  peso_kg    NUMERIC(10,2) DEFAULT 0,
  estado     TEXT          NOT NULL DEFAULT 'Staging',
  created_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS cliente    TEXT;
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS carrier    TEXT;
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS tracking   TEXT;
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS bultos     INTEGER       DEFAULT 0;
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS peso_kg    NUMERIC(10,2) DEFAULT 0;
ALTER TABLE shipments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ   NOT NULL DEFAULT now();
ALTER TABLE shipments DROP CONSTRAINT IF EXISTS shipments_numero_key;
ALTER TABLE shipments ADD  CONSTRAINT shipments_numero_key UNIQUE (numero);

-- ================================================================
-- TRANSFERENCIAS
-- ================================================================
CREATE TABLE IF NOT EXISTS transferencias (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  numero        TEXT          NOT NULL,
  wh_origen     TEXT          NOT NULL,
  wh_destino    TEXT          NOT NULL,
  sku           TEXT,
  cantidad      NUMERIC(14,2) DEFAULT 0,
  transportista TEXT,
  eta           TIMESTAMPTZ,
  motivo        TEXT,
  estado        TEXT          NOT NULL DEFAULT 'En transito',
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE transferencias ADD COLUMN IF NOT EXISTS transportista TEXT;
ALTER TABLE transferencias ADD COLUMN IF NOT EXISTS eta           TIMESTAMPTZ;
ALTER TABLE transferencias ADD COLUMN IF NOT EXISTS motivo        TEXT;
ALTER TABLE transferencias ADD COLUMN IF NOT EXISTS updated_at    TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE transferencias DROP CONSTRAINT IF EXISTS transferencias_numero_key;
ALTER TABLE transferencias ADD  CONSTRAINT transferencias_numero_key UNIQUE (numero);

-- ================================================================
-- MOVIMIENTOS
-- ================================================================
CREATE TABLE IF NOT EXISTS movimientos (
  id         UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo       TEXT          NOT NULL,
  referencia TEXT,
  wh_id      TEXT,
  sku        TEXT,
  cantidad   NUMERIC(14,2) DEFAULT 0,
  ubicacion  TEXT,
  notas      TEXT,
  usuario    TEXT,
  created_at TIMESTAMPTZ   NOT NULL DEFAULT now()
);
ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS referencia TEXT;
ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS wh_id      TEXT;
ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS sku        TEXT;
ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS cantidad   NUMERIC(14,2) DEFAULT 0;
ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS ubicacion  TEXT;
ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS notas      TEXT;
ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS usuario    TEXT;

-- ================================================================
-- OPERADORES
-- ================================================================
CREATE TABLE IF NOT EXISTS operadores (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre     TEXT        NOT NULL,
  iniciales  TEXT,
  wh_id      TEXT,
  modulo     TEXT,
  activo     BOOLEAN     NOT NULL DEFAULT true,
  color      TEXT        DEFAULT 'var(--a)',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE operadores ADD COLUMN IF NOT EXISTS iniciales  TEXT;
ALTER TABLE operadores ADD COLUMN IF NOT EXISTS wh_id      TEXT;
ALTER TABLE operadores ADD COLUMN IF NOT EXISTS modulo     TEXT;
ALTER TABLE operadores ADD COLUMN IF NOT EXISTS activo     BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE operadores ADD COLUMN IF NOT EXISTS color      TEXT    DEFAULT 'var(--a)';

-- ================================================================
-- LOG_APROBACIONES
-- ================================================================
CREATE TABLE IF NOT EXISTS log_aprobaciones (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo_pedido     TEXT        NOT NULL,
  pedido_id       UUID        NOT NULL,
  pedido_numero   TEXT        NOT NULL,
  accion          TEXT        NOT NULL,
  usuario         TEXT        NOT NULL,
  rol_usuario     TEXT        NOT NULL,
  motivo          TEXT,
  estado_anterior TEXT,
  estado_nuevo    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE log_aprobaciones DROP CONSTRAINT IF EXISTS log_aprobaciones_tipo_check;
ALTER TABLE log_aprobaciones ADD  CONSTRAINT log_aprobaciones_tipo_check
  CHECK (tipo_pedido IN ('entrada','salida'));
ALTER TABLE log_aprobaciones DROP CONSTRAINT IF EXISTS log_aprobaciones_accion_check;
ALTER TABLE log_aprobaciones ADD  CONSTRAINT log_aprobaciones_accion_check
  CHECK (accion IN ('creado','liberado','rechazado','cancelado','reabierto'));

-- ================================================================
-- IMPORTACIONES_MASIVAS
-- ================================================================
CREATE TABLE IF NOT EXISTS importaciones_masivas (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo        TEXT        NOT NULL,
  total_filas INTEGER     DEFAULT 0,
  exitosas    INTEGER     DEFAULT 0,
  errores     INTEGER     DEFAULT 0,
  detalle     JSONB,
  usuario     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE importaciones_masivas DROP CONSTRAINT IF EXISTS importaciones_masivas_tipo_check;
ALTER TABLE importaciones_masivas ADD  CONSTRAINT importaciones_masivas_tipo_check
  CHECK (tipo IN ('ubicaciones','logistica_articulos','articulos'));


-- ─── LIMPIEZA UNIVERSAL: Eliminar NOT NULL de TODAS las columnas
-- desconocidas en ubicaciones que puedan venir de versiones anteriores
-- Mantiene NOT NULL solo en: id, ocupada, activo, created_at
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'ubicaciones'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','ocupada','activo','created_at')
  LOOP
    EXECUTE 'ALTER TABLE ubicaciones ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'ubicaciones: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: Mismo patrón para pedidos_entrada
-- Mantiene NOT NULL solo en columnas que nosotros definimos así
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'pedidos_entrada'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','liberado','requiere_aprobacion','estado','created_at','updated_at')
  LOOP
    EXECUTE 'ALTER TABLE pedidos_entrada ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'pedidos_entrada: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: Mismo patrón para pedidos_salida
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'pedidos_salida'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','liberado','requiere_aprobacion','estado','created_at','updated_at')
  LOOP
    EXECUTE 'ALTER TABLE pedidos_salida ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'pedidos_salida: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: carros_entrada
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'carros_entrada'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','tipo','estado','created_at','updated_at')
  LOOP
    EXECUTE 'ALTER TABLE carros_entrada ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'carros_entrada: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: carro_lineas
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'carro_lineas'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','ubicado','created_at')
  LOOP
    EXECUTE 'ALTER TABLE carro_lineas ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'carro_lineas: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: zonas
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'zonas'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','almacen_id','codigo','nombre','activo','created_at')
  LOOP
    EXECUTE 'ALTER TABLE zonas ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'zonas: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: stock
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'stock'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','sku','wh_id','disponible','reservado','created_at','updated_at')
  LOOP
    EXECUTE 'ALTER TABLE stock ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'stock: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: pe_lineas
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'pe_lineas'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','pedido_id','sku','cantidad_ped','cantidad_rec','estado','created_at')
  LOOP
    EXECUTE 'ALTER TABLE pe_lineas ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'pe_lineas: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL: ps_lineas
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'ps_lineas'
      AND is_nullable  = 'NO'
      AND column_name NOT IN ('id','pedido_id','sku','cantidad_ped','cantidad_prep','estado','created_at')
  LOOP
    EXECUTE 'ALTER TABLE ps_lineas ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
    RAISE NOTICE 'ps_lineas: Dropped NOT NULL from %', r.column_name;
  END LOOP;
END $$;

-- ─── LIMPIEZA UNIVERSAL MAXIMA: cualquier tabla con NOT NULL heredado desconocido
-- Recorre TODAS las tablas del sistema y elimina NOT NULL de columnas
-- que no sean PKs ni columnas boolean de control
DO $$ DECLARE r RECORD; BEGIN
  FOR r IN
    SELECT c.table_name, c.column_name
    FROM information_schema.columns c
    JOIN information_schema.tables t ON t.table_name=c.table_name AND t.table_schema=c.table_schema
    WHERE c.table_schema = 'public'
      AND t.table_type   = 'BASE TABLE'
      AND c.is_nullable  = 'NO'
      AND c.column_name NOT IN (
        'id','activo','ocupada','liberado','requiere_aprobacion','apilable',
        'created_at','updated_at','liberado_at','rechazado_at',
        'tipo','estado','wh_id','sku','numero','codigo','nombre'
      )
      AND c.table_name IN (
        'ubicaciones','carros_entrada','carro_lineas','zonas',
        'pe_lineas','ps_lineas','asn_lineas','rf_tasks',
        'movimientos','operadores','waves','shipments','transferencias'
      )
  LOOP
    BEGIN
      EXECUTE 'ALTER TABLE ' || quote_ident(r.table_name) ||
              ' ALTER COLUMN ' || quote_ident(r.column_name) || ' DROP NOT NULL';
      RAISE NOTICE 'Cleared NOT NULL: %.%', r.table_name, r.column_name;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Skip %.%: %', r.table_name, r.column_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- ================================================================
-- ③ LIMPIAR SEMILLA ANTERIOR (evitar UNIQUE conflicts)
-- ================================================================
DELETE FROM ubicaciones  WHERE true;
DELETE FROM zonas        WHERE true;
DELETE FROM stock_centro WHERE true;
DELETE FROM almacenes    WHERE true;
DELETE FROM centros      WHERE true;

-- ================================================================
-- ④ PERMISOS
-- ================================================================
ALTER TABLE centros                     DISABLE ROW LEVEL SECURITY;
ALTER TABLE almacenes                   DISABLE ROW LEVEL SECURITY;
ALTER TABLE marcas                      DISABLE ROW LEVEL SECURITY;
ALTER TABLE grupos                      DISABLE ROW LEVEL SECURITY;
ALTER TABLE articulos                   DISABLE ROW LEVEL SECURITY;
ALTER TABLE proveedores                 DISABLE ROW LEVEL SECURITY;
ALTER TABLE clientes                    DISABLE ROW LEVEL SECURITY;
ALTER TABLE zonas                       DISABLE ROW LEVEL SECURITY;
ALTER TABLE ubicaciones                 DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock_centro                DISABLE ROW LEVEL SECURITY;
ALTER TABLE configuracion_zonas_entrada DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock                       DISABLE ROW LEVEL SECURITY;
ALTER TABLE asn                         DISABLE ROW LEVEL SECURITY;
ALTER TABLE asn_lineas                  DISABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_entrada             DISABLE ROW LEVEL SECURITY;
ALTER TABLE pe_lineas                   DISABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_salida              DISABLE ROW LEVEL SECURITY;
ALTER TABLE ps_lineas                   DISABLE ROW LEVEL SECURITY;
ALTER TABLE carros_entrada              DISABLE ROW LEVEL SECURITY;
ALTER TABLE carro_lineas                DISABLE ROW LEVEL SECURITY;
ALTER TABLE waves                       DISABLE ROW LEVEL SECURITY;
ALTER TABLE rf_tasks                    DISABLE ROW LEVEL SECURITY;
ALTER TABLE shipments                   DISABLE ROW LEVEL SECURITY;
ALTER TABLE transferencias              DISABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos                 DISABLE ROW LEVEL SECURITY;
ALTER TABLE operadores                  DISABLE ROW LEVEL SECURITY;
ALTER TABLE log_aprobaciones            DISABLE ROW LEVEL SECURITY;
ALTER TABLE importaciones_masivas       DISABLE ROW LEVEL SECURITY;

GRANT SELECT,INSERT,UPDATE,DELETE ON centros                     TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON almacenes                   TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON marcas                      TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON grupos                      TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON articulos                   TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON proveedores                 TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON clientes                    TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON zonas                       TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON ubicaciones                 TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON stock_centro                TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON configuracion_zonas_entrada TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON stock                       TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON asn                         TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON asn_lineas                  TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON pedidos_entrada             TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON pe_lineas                   TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON pedidos_salida              TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON ps_lineas                   TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON carros_entrada              TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON carro_lineas                TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON waves                       TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON rf_tasks                    TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON shipments                   TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON transferencias              TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON movimientos                 TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON operadores                  TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON log_aprobaciones            TO anon, authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON importaciones_masivas       TO anon, authenticated;
GRANT USAGE,SELECT ON SEQUENCE seq_proveedores TO anon, authenticated;
GRANT USAGE,SELECT ON SEQUENCE seq_clientes    TO anon, authenticated;

-- ================================================================
-- ⑤ VISTAS (todas las columnas ya existen)
-- ================================================================
CREATE OR REPLACE VIEW v_stock AS
SELECT
  a.id AS articulo_id, a.codigo, a.descripcion, a.codigo_barras, a.unidad,
  a.precio_costo, a.precio_venta, a.stock_min, a.stock_max,
  a.peso_kg, a.volumen_m3, a.requiere_lote, a.metodo_rotacion, a.abc_clase, a.activo,
  a.marca_id, m.nombre AS nombre_marca,
  a.grupo_id, g.nombre AS nombre_grupo,
  a.und_por_caja, a.cajas_por_palet,
  COALESCE(a.und_por_caja,1)*COALESCE(a.cajas_por_palet,1) AS und_por_palet,
  a.zona_entrada_codigo, a.tipo_palet,
  sc.centro_id, COALESCE(sc.stock_actual,0) AS stock_actual,
  CASE
    WHEN COALESCE(sc.stock_actual,0)<=0                                       THEN 'SIN STOCK'
    WHEN COALESCE(sc.stock_actual,0)<=a.stock_min                             THEN 'BAJO'
    WHEN a.stock_max>0 AND COALESCE(sc.stock_actual,0)>=a.stock_max*0.9      THEN 'ALTO'
    ELSE 'NORMAL'
  END AS estado_stock
FROM articulos a
LEFT JOIN marcas       m  ON m.id=a.marca_id
LEFT JOIN grupos       g  ON g.id=a.grupo_id
LEFT JOIN stock_centro sc ON sc.articulo_id=a.id
WHERE a.activo=true;

CREATE OR REPLACE VIEW v_ubicaciones_detalle AS
SELECT u.id, u.codigo, u.pasillo, u.nivel, u.posicion,
  u.capacidad, u.capacidad_kg, u.estado, u.ocupada, u.activo, u.wh_id, u.zona,
  z.id AS zona_id, z.codigo AS zona_codigo, z.nombre AS zona_nombre, z.tipo AS zona_tipo,
  a.id AS almacen_id, a.codigo AS almacen_codigo, a.nombre AS almacen_nombre,
  c.id AS centro_id, c.nombre AS centro_nombre
FROM ubicaciones u
LEFT JOIN zonas     z ON z.id=u.zona_id
LEFT JOIN almacenes a ON a.id=z.almacen_id
LEFT JOIN centros   c ON c.id=a.centro_id;

CREATE OR REPLACE VIEW v_pendientes_aprobacion AS
SELECT 'entrada'::text AS tipo_pedido, id, numero, wh_id,
  proveedor AS contraparte, tipo, prioridad, estado,
  creado_por, liberado_por, fecha_esperada AS fecha_clave,
  created_at, updated_at, liberado, liberado_at, notas, requiere_aprobacion
FROM pedidos_entrada
WHERE estado='Pendiente Aprobacion' AND requiere_aprobacion=true
UNION ALL
SELECT 'salida'::text, id, numero, wh_id,
  cliente AS contraparte, tipo, prioridad, estado,
  creado_por, liberado_por, fecha_prometida,
  created_at, updated_at, liberado, liberado_at, notas, requiere_aprobacion
FROM pedidos_salida
WHERE estado='Pendiente Aprobacion' AND requiere_aprobacion=true
ORDER BY created_at DESC;

GRANT SELECT ON v_stock                 TO anon, authenticated;
GRANT SELECT ON v_ubicaciones_detalle   TO anon, authenticated;
GRANT SELECT ON v_pendientes_aprobacion TO anon, authenticated;

-- ================================================================
-- ⑥ INDICES
-- ================================================================
CREATE INDEX IF NOT EXISTS idx_art_codigo    ON articulos(codigo);
CREATE INDEX IF NOT EXISTS idx_art_activo    ON articulos(activo);
CREATE INDEX IF NOT EXISTS idx_art_marca     ON articulos(marca_id);
CREATE INDEX IF NOT EXISTS idx_art_grupo     ON articulos(grupo_id);
CREATE INDEX IF NOT EXISTS idx_prov_activo   ON proveedores(activo);
CREATE INDEX IF NOT EXISTS idx_cli_activo    ON clientes(activo);
CREATE INDEX IF NOT EXISTS idx_alm_activo    ON almacenes(activo);
CREATE INDEX IF NOT EXISTS idx_alm_centro    ON almacenes(centro_id);
CREATE INDEX IF NOT EXISTS idx_zon_alm       ON zonas(almacen_id);
CREATE INDEX IF NOT EXISTS idx_ubi_wh        ON ubicaciones(wh_id);
CREATE INDEX IF NOT EXISTS idx_ubi_zona      ON ubicaciones(zona);
CREATE INDEX IF NOT EXISTS idx_ubi_zona_id   ON ubicaciones(zona_id);
CREATE INDEX IF NOT EXISTS idx_stk_sku       ON stock(sku);
CREATE INDEX IF NOT EXISTS idx_stk_wh        ON stock(wh_id);
CREATE INDEX IF NOT EXISTS idx_stk_ubic      ON stock(ubicacion);
CREATE INDEX IF NOT EXISTS idx_asn_estado    ON asn(estado);
CREATE INDEX IF NOT EXISTS idx_asn_wh        ON asn(wh_id);
CREATE INDEX IF NOT EXISTS idx_pe_estado     ON pedidos_entrada(estado);
CREATE INDEX IF NOT EXISTS idx_pe_wh         ON pedidos_entrada(wh_id);
CREATE INDEX IF NOT EXISTS idx_pe_liberado   ON pedidos_entrada(liberado);
CREATE INDEX IF NOT EXISTS idx_pel_ped       ON pe_lineas(pedido_id);
CREATE INDEX IF NOT EXISTS idx_ps_estado     ON pedidos_salida(estado);
CREATE INDEX IF NOT EXISTS idx_ps_wh         ON pedidos_salida(wh_id);
CREATE INDEX IF NOT EXISTS idx_ps_liberado   ON pedidos_salida(liberado);
CREATE INDEX IF NOT EXISTS idx_psl_ped       ON ps_lineas(pedido_id);
CREATE INDEX IF NOT EXISTS idx_carr_wh       ON carros_entrada(wh_id);
CREATE INDEX IF NOT EXISTS idx_carr_estado   ON carros_entrada(estado);
CREATE INDEX IF NOT EXISTS idx_cl_carro      ON carro_lineas(carro_id);
CREATE INDEX IF NOT EXISTS idx_wave_estado   ON waves(estado);
CREATE INDEX IF NOT EXISTS idx_rft_estado    ON rf_tasks(estado);
CREATE INDEX IF NOT EXISTS idx_rft_wave      ON rf_tasks(wave_id);
CREATE INDEX IF NOT EXISTS idx_ship_estado   ON shipments(estado);
CREATE INDEX IF NOT EXISTS idx_trf_estado    ON transferencias(estado);
CREATE INDEX IF NOT EXISTS idx_mov_tipo      ON movimientos(tipo);
CREATE INDEX IF NOT EXISTS idx_mov_sku       ON movimientos(sku);
CREATE INDEX IF NOT EXISTS idx_mov_wh        ON movimientos(wh_id);
CREATE INDEX IF NOT EXISTS idx_mov_created   ON movimientos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_log_pedido    ON log_aprobaciones(pedido_id);
CREATE INDEX IF NOT EXISTS idx_log_accion    ON log_aprobaciones(accion);
CREATE INDEX IF NOT EXISTS idx_log_created   ON log_aprobaciones(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sc_centro     ON stock_centro(centro_id);
CREATE INDEX IF NOT EXISTS idx_sc_art        ON stock_centro(articulo_id);
CREATE INDEX IF NOT EXISTS idx_cze_zona      ON configuracion_zonas_entrada(zona_id);
CREATE INDEX IF NOT EXISTS idx_cze_alm       ON configuracion_zonas_entrada(almacen_id);

-- ================================================================
-- ⑦ DATOS SEMILLA
-- ================================================================

-- CENTROS
INSERT INTO centros (codigo,nombre,ciudad,pais,activo) VALUES
  ('CDMX-01','Panama Norte','Ciudad de Panama','Panama',true),
  ('CDMX-02','Panama Sur',  'Ciudad de Panama','Panama',true),
  ('CDMX-03','Colon',       'Colon',           'Panama',true)
ON CONFLICT (codigo) DO NOTHING;

-- ALMACENES (SELECT con todos los valores sin subexpresiones complejas)
INSERT INTO almacenes (codigo,nombre,tipo,ciudad,capacidad_m2,centro_id,activo)
SELECT 'PAN-001','Panama Centro',    'General',     'Ciudad de Panama',2500,(SELECT id FROM centros WHERE codigo='CDMX-01' LIMIT 1),true
WHERE NOT EXISTS (SELECT 1 FROM almacenes WHERE codigo='PAN-001');
INSERT INTO almacenes (codigo,nombre,tipo,ciudad,capacidad_m2,centro_id,activo)
SELECT 'PAN-002','Tocumen Logistico','Distribucion','Tocumen',         4000,(SELECT id FROM centros WHERE codigo='CDMX-01' LIMIT 1),true
WHERE NOT EXISTS (SELECT 1 FROM almacenes WHERE codigo='PAN-002');
INSERT INTO almacenes (codigo,nombre,tipo,ciudad,capacidad_m2,centro_id,activo)
SELECT 'CHI-001','Chiriqui Norte',   'General',     'David',           1800,(SELECT id FROM centros WHERE codigo='CDMX-02' LIMIT 1),true
WHERE NOT EXISTS (SELECT 1 FROM almacenes WHERE codigo='CHI-001');
INSERT INTO almacenes (codigo,nombre,tipo,ciudad,capacidad_m2,centro_id,activo)
SELECT 'COD-001','Colon Free Zone',  'Distribucion','Colon',           5000,(SELECT id FROM centros WHERE codigo='CDMX-03' LIMIT 1),true
WHERE NOT EXISTS (SELECT 1 FROM almacenes WHERE codigo='COD-001');

-- MARCAS
INSERT INTO marcas (nombre,activo) VALUES
  ('Generica',true),('Reprograf',true),('Anker',true),('Stanley',true),
  ('Bayer',true),('Agrozulia',true),('3M',true),('Samsung',true)
ON CONFLICT (nombre) DO NOTHING;

-- GRUPOS
INSERT INTO grupos (nombre,descripcion,activo) VALUES
  ('Papel y Suministros', 'Papel, carton, materiales de oficina',true),
  ('Electronica',         'Cables, adaptadores, componentes',    true),
  ('Herramientas',        'Herramientas manuales y electricas',  true),
  ('Farmaceuticos',       'Medicamentos y suplementos',          true),
  ('Alimentos',           'Productos alimenticios secos',        true),
  ('Limpieza',            'Articulos de limpieza e higiene',     true),
  ('Seguridad Industrial','EPP y seguridad industrial',          true),
  ('Refrigerados',        'Productos con cadena de frio',        true)
ON CONFLICT (nombre) DO NOTHING;

-- ARTICULOS
INSERT INTO articulos (codigo,descripcion,unidad,precio_costo,precio_venta,
  stock_min,stock_max,metodo_rotacion,und_por_caja,cajas_por_palet,activo)
VALUES
  ('ALP-100','Papel Bond A4 75g Resma', 'RES', 3.50, 5.25,100,1000,'FIFO',10,20,true),
  ('USB-C1M','Cable USB-C a USB-C 1m',  'UND', 8.00,14.99, 50, 500,'FIFO',50,40,true),
  ('LLV-SET','Set Llave Allen 9 piezas','SET',12.00,19.99, 20, 200,'FIFO',12,24,true),
  ('INS-VIT','Vitamina C 500mg x100',   'FCO', 6.80,11.50,200,2000,'FEFO',12,30,true),
  ('ALM-SOY','Almendra de Soya 25kg',   'SAC',22.00,28.00,500,5000,'FEFO', 1,10,true)
ON CONFLICT (codigo) DO NOTHING;

-- PROVEEDORES
INSERT INTO proveedores (codigo,nombre,tipo,telefono,email,pais,condicion_pago,dias_entrega,calificacion,activo)
VALUES
  ('PROV-0001','Distribuidora ABC S.A.','Nacional',     '+507 6100-1234','ventas@abc.com',  'Panama','30 dias', 7,5,true),
  ('PROV-0002','Tech Imports Corp',     'Internacional','+1 305 555-0123','orders@tech.com','EEUU', '60 dias',21,4,true),
  ('PROV-0003','Herramientas del Istmo','Nacional',     '+507 6200-5678','info@istmo.com',  'Panama','Contado', 3,5,true)
ON CONFLICT (codigo) DO NOTHING;

-- CLIENTES
INSERT INTO clientes (codigo,nombre,tipo,segmento,telefono,email,pais,condicion_pago,limite_credito,activo)
VALUES
  ('CLI-0001','Supermercados Rey S.A.','Empresa','VIP',    '+507 6300-0001','compras@rey.com',      'Panama','30 dias',50000,true),
  ('CLI-0002','Ferreteria El Clavo',   'Empresa','Premium','+507 7400-0002','pedidos@clavo.com',    'Panama','15 dias',15000,true),
  ('CLI-0003','Farmacia Arrocha',      'Empresa','Regular','+507 6500-0003','logistica@arrocha.com','Panama','Contado', 5000,true)
ON CONFLICT (codigo) DO NOTHING;

-- STOCK
INSERT INTO stock (sku,descripcion,wh_id,disponible,reservado,stock_min)
VALUES
  ('ALP-100','Papel Bond A4 75g', 'PAN-001',250, 0,100),
  ('USB-C1M','Cable USB-C 1m',    'PAN-001',342,50, 50),
  ('LLV-SET','Llave Allen 9pz',   'PAN-001', 87,20, 20),
  ('INS-VIT','Vitamina C 500mg',  'PAN-002',180, 0,200),
  ('ALM-SOY','Almendra Soya 25kg','PAN-002', 60, 0,500)
ON CONFLICT (sku,wh_id) DO NOTHING;

-- ZONAS — INSERT SELECT puros, sin variables PL/pgSQL
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='PAN-001' LIMIT 1),'REC','Recepcion','Recepcion',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='REC');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='PAN-001' LIMIT 1),'A','Zona A Racks','General',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='A');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='PAN-001' LIMIT 1),'B','Zona B Piso','General',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='B');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='PAN-001' LIMIT 1),'DSP','Despacho','Despacho',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='DSP');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='PAN-002' LIMIT 1),'REC','Recepcion','Recepcion',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-002' AND z.codigo='REC');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='PAN-002' LIMIT 1),'A','Zona A Racks','General',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-002' AND z.codigo='A');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='PAN-002' LIMIT 1),'DSP','Despacho','Despacho',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-002' AND z.codigo='DSP');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='CHI-001' LIMIT 1),'REC','Recepcion','Recepcion',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='CHI-001' AND z.codigo='REC');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='CHI-001' LIMIT 1),'A','Zona A','General',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='CHI-001' AND z.codigo='A');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='COD-001' LIMIT 1),'REC','Recepcion','Recepcion',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='COD-001' AND z.codigo='REC');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='COD-001' LIMIT 1),'A','Zona A Racks','General',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='COD-001' AND z.codigo='A');
INSERT INTO zonas (almacen_id,codigo,nombre,tipo,activo)
SELECT (SELECT id FROM almacenes WHERE codigo='COD-001' LIMIT 1),'DSP','Despacho','Despacho',true
WHERE NOT EXISTS (SELECT 1 FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='COD-001' AND z.codigo='DSP');

-- UBICACIONES — INSERT SELECT puros con subqueries directas, sin variables PL/pgSQL
INSERT INTO ubicaciones (codigo,wh_id,zona,zona_id,pasillo,nivel,posicion,tipo,capacidad_kg,estado,ocupada,activo)
SELECT 'REC-01-A','PAN-001','REC',
  (SELECT z.id FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='REC' LIMIT 1),
  '01','01','A','Recepcion',5000,'free',false,true
WHERE NOT EXISTS (SELECT 1 FROM ubicaciones WHERE codigo='REC-01-A');

INSERT INTO ubicaciones (codigo,wh_id,zona,zona_id,pasillo,nivel,posicion,tipo,capacidad_kg,estado,ocupada,activo)
SELECT 'A-01-01-A','PAN-001','A',
  (SELECT z.id FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='A' LIMIT 1),
  '01','01','A','Rack estandar',1000,'free',false,true
WHERE NOT EXISTS (SELECT 1 FROM ubicaciones WHERE codigo='A-01-01-A');

INSERT INTO ubicaciones (codigo,wh_id,zona,zona_id,pasillo,nivel,posicion,tipo,capacidad_kg,estado,ocupada,activo)
SELECT 'A-01-01-B','PAN-001','A',
  (SELECT z.id FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='A' LIMIT 1),
  '01','01','B','Rack estandar',1000,'free',false,true
WHERE NOT EXISTS (SELECT 1 FROM ubicaciones WHERE codigo='A-01-01-B');

INSERT INTO ubicaciones (codigo,wh_id,zona,zona_id,pasillo,nivel,posicion,tipo,capacidad_kg,estado,ocupada,activo)
SELECT 'A-02-01-A','PAN-001','A',
  (SELECT z.id FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='A' LIMIT 1),
  '02','01','A','Rack estandar',1000,'free',false,true
WHERE NOT EXISTS (SELECT 1 FROM ubicaciones WHERE codigo='A-02-01-A');

INSERT INTO ubicaciones (codigo,wh_id,zona,zona_id,pasillo,nivel,posicion,tipo,capacidad_kg,estado,ocupada,activo)
SELECT 'A-03-02-A','PAN-001','A',
  (SELECT z.id FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='A' LIMIT 1),
  '03','02','A','Rack estandar',800,'busy',true,true
WHERE NOT EXISTS (SELECT 1 FROM ubicaciones WHERE codigo='A-03-02-A');

INSERT INTO ubicaciones (codigo,wh_id,zona,zona_id,pasillo,nivel,posicion,tipo,capacidad_kg,estado,ocupada,activo)
SELECT 'B-01-01-A','PAN-001','B',
  (SELECT z.id FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='B' LIMIT 1),
  '01','01','A','Piso Bulk',5000,'free',false,true
WHERE NOT EXISTS (SELECT 1 FROM ubicaciones WHERE codigo='B-01-01-A');

INSERT INTO ubicaciones (codigo,wh_id,zona,zona_id,pasillo,nivel,posicion,tipo,capacidad_kg,estado,ocupada,activo)
SELECT 'DSP-01-A','PAN-001','DSP',
  (SELECT z.id FROM zonas z JOIN almacenes a ON a.id=z.almacen_id WHERE a.codigo='PAN-001' AND z.codigo='DSP' LIMIT 1),
  '01','01','A','Staging',3000,'free',false,true
WHERE NOT EXISTS (SELECT 1 FROM ubicaciones WHERE codigo='DSP-01-A');

-- OPERADORES
INSERT INTO operadores (nombre,iniciales,wh_id,modulo,activo) VALUES
  ('Administrador','AD','',       'Administrador',true),
  ('Supervisor',   'SV','PAN-001','Supervisor',   true),
  ('Juan Rodriguez','JR','PAN-001','Operador',    true),
  ('Maria Morales', 'MM','PAN-002','Operador',    true),
  ('Ana Lopez',     'AL','COD-001','Operador',    true)
ON CONFLICT DO NOTHING;

-- ================================================================
-- ⑧ VERIFICACION FINAL
-- ================================================================
SELECT table_name AS tabla, COUNT(*) AS columnas
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name IN (
    'centros','almacenes','marcas','grupos','articulos','proveedores','clientes',
    'zonas','ubicaciones','stock_centro','configuracion_zonas_entrada',
    'stock','asn','asn_lineas','pedidos_entrada','pe_lineas',
    'pedidos_salida','ps_lineas','carros_entrada','carro_lineas',
    'waves','rf_tasks','shipments','transferencias','movimientos','operadores',
    'log_aprobaciones','importaciones_masivas')
GROUP BY table_name ORDER BY table_name;

SELECT 'centros'       AS tabla, COUNT(*) AS filas FROM centros
UNION ALL SELECT 'almacenes',   COUNT(*) FROM almacenes
UNION ALL SELECT 'zonas',       COUNT(*) FROM zonas
UNION ALL SELECT 'ubicaciones', COUNT(*) FROM ubicaciones
UNION ALL SELECT 'marcas',      COUNT(*) FROM marcas
UNION ALL SELECT 'grupos',      COUNT(*) FROM grupos
UNION ALL SELECT 'articulos',   COUNT(*) FROM articulos
UNION ALL SELECT 'proveedores', COUNT(*) FROM proveedores
UNION ALL SELECT 'clientes',    COUNT(*) FROM clientes
UNION ALL SELECT 'stock',       COUNT(*) FROM stock
UNION ALL SELECT 'operadores',  COUNT(*) FROM operadores
ORDER BY tabla;