--
-- PostgreSQL database dump
--

\restrict BIjMDmbxjqpHV6o2V2drfcKIKPAKzRlUMiqyyK9KWxzoPPWQu4X2mJZon22GE6t

-- Dumped from database version 15.20 (Debian 15.20-1.pgdg13+1)
-- Dumped by pg_dump version 15.20 (Debian 15.20-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: detalle_traspaso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.detalle_traspaso (
    id_traspaso integer NOT NULL,
    id_prenda integer NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT detalle_traspaso_cantidad_check CHECK ((cantidad > 0))
);


--
-- Name: historial_auditoria_inventario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historial_auditoria_inventario (
    id integer NOT NULL,
    id_inventario integer NOT NULL,
    tipo_movimiento character varying(50) NOT NULL,
    cantidad_anterior integer NOT NULL,
    cantidad_nueva integer NOT NULL,
    id_usuario integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: historial_auditoria_inventario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historial_auditoria_inventario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historial_auditoria_inventario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historial_auditoria_inventario_id_seq OWNED BY public.historial_auditoria_inventario.id;


--
-- Name: inventario_sucursal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventario_sucursal (
    id integer NOT NULL,
    id_prenda integer NOT NULL,
    id_sucursal integer NOT NULL,
    talla character varying(20) NOT NULL,
    color character varying(50) NOT NULL,
    cantidad integer NOT NULL,
    CONSTRAINT chk_cantidad_positiva CHECK ((cantidad >= 0))
);


--
-- Name: inventario_sucursal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventario_sucursal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventario_sucursal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventario_sucursal_id_seq OWNED BY public.inventario_sucursal.id;


--
-- Name: prendas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prendas (
    id integer NOT NULL,
    codigo_barras character varying(100) NOT NULL,
    descripcion text NOT NULL,
    marca character varying(100),
    categoria character varying(100),
    temporada character varying(50),
    foto_url text,
    umbral_alerta integer DEFAULT 2
);


--
-- Name: prendas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prendas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prendas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prendas_id_seq OWNED BY public.prendas.id;


--
-- Name: sucursales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucursales (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    ubicacion text NOT NULL
);


--
-- Name: sucursales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucursales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucursales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucursales_id_seq OWNED BY public.sucursales.id;


--
-- Name: traspasos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.traspasos (
    id integer NOT NULL,
    id_sucursal_origen integer NOT NULL,
    id_sucursal_destino integer NOT NULL,
    usuario_solicita integer NOT NULL,
    usuario_aprueba integer,
    estado character varying(50) DEFAULT 'SOLICITADO'::character varying NOT NULL,
    fecha_solicitud timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: traspasos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.traspasos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: traspasos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.traspasos_id_seq OWNED BY public.traspasos.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(150) NOT NULL,
    id_keycloak character varying(255) NOT NULL,
    rol character varying(50) NOT NULL,
    id_sucursal_asignada integer
);


--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: historial_auditoria_inventario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_auditoria_inventario ALTER COLUMN id SET DEFAULT nextval('public.historial_auditoria_inventario_id_seq'::regclass);


--
-- Name: inventario_sucursal id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_sucursal ALTER COLUMN id SET DEFAULT nextval('public.inventario_sucursal_id_seq'::regclass);


--
-- Name: prendas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prendas ALTER COLUMN id SET DEFAULT nextval('public.prendas_id_seq'::regclass);


--
-- Name: sucursales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucursales ALTER COLUMN id SET DEFAULT nextval('public.sucursales_id_seq'::regclass);


--
-- Name: traspasos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.traspasos ALTER COLUMN id SET DEFAULT nextval('public.traspasos_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: detalle_traspaso detalle_traspaso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_traspaso
    ADD CONSTRAINT detalle_traspaso_pkey PRIMARY KEY (id_traspaso, id_prenda);


--
-- Name: historial_auditoria_inventario historial_auditoria_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_auditoria_inventario
    ADD CONSTRAINT historial_auditoria_inventario_pkey PRIMARY KEY (id);


--
-- Name: inventario_sucursal inventario_sucursal_id_prenda_id_sucursal_talla_color_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_sucursal
    ADD CONSTRAINT inventario_sucursal_id_prenda_id_sucursal_talla_color_key UNIQUE (id_prenda, id_sucursal, talla, color);


--
-- Name: inventario_sucursal inventario_sucursal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_sucursal
    ADD CONSTRAINT inventario_sucursal_pkey PRIMARY KEY (id);


--
-- Name: prendas prendas_codigo_barras_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prendas
    ADD CONSTRAINT prendas_codigo_barras_key UNIQUE (codigo_barras);


--
-- Name: prendas prendas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prendas
    ADD CONSTRAINT prendas_pkey PRIMARY KEY (id);


--
-- Name: sucursales sucursales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucursales
    ADD CONSTRAINT sucursales_pkey PRIMARY KEY (id);


--
-- Name: traspasos traspasos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.traspasos
    ADD CONSTRAINT traspasos_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_id_keycloak_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_keycloak_key UNIQUE (id_keycloak);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: detalle_traspaso detalle_traspaso_id_prenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_traspaso
    ADD CONSTRAINT detalle_traspaso_id_prenda_fkey FOREIGN KEY (id_prenda) REFERENCES public.prendas(id);


--
-- Name: detalle_traspaso detalle_traspaso_id_traspaso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.detalle_traspaso
    ADD CONSTRAINT detalle_traspaso_id_traspaso_fkey FOREIGN KEY (id_traspaso) REFERENCES public.traspasos(id) ON DELETE CASCADE;


--
-- Name: historial_auditoria_inventario historial_auditoria_inventario_id_inventario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_auditoria_inventario
    ADD CONSTRAINT historial_auditoria_inventario_id_inventario_fkey FOREIGN KEY (id_inventario) REFERENCES public.inventario_sucursal(id);


--
-- Name: historial_auditoria_inventario historial_auditoria_inventario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_auditoria_inventario
    ADD CONSTRAINT historial_auditoria_inventario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id);


--
-- Name: inventario_sucursal inventario_sucursal_id_prenda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_sucursal
    ADD CONSTRAINT inventario_sucursal_id_prenda_fkey FOREIGN KEY (id_prenda) REFERENCES public.prendas(id) ON DELETE CASCADE;


--
-- Name: inventario_sucursal inventario_sucursal_id_sucursal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventario_sucursal
    ADD CONSTRAINT inventario_sucursal_id_sucursal_fkey FOREIGN KEY (id_sucursal) REFERENCES public.sucursales(id) ON DELETE CASCADE;


--
-- Name: traspasos traspasos_id_sucursal_destino_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.traspasos
    ADD CONSTRAINT traspasos_id_sucursal_destino_fkey FOREIGN KEY (id_sucursal_destino) REFERENCES public.sucursales(id);


--
-- Name: traspasos traspasos_id_sucursal_origen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.traspasos
    ADD CONSTRAINT traspasos_id_sucursal_origen_fkey FOREIGN KEY (id_sucursal_origen) REFERENCES public.sucursales(id);


--
-- Name: traspasos traspasos_usuario_aprueba_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.traspasos
    ADD CONSTRAINT traspasos_usuario_aprueba_fkey FOREIGN KEY (usuario_aprueba) REFERENCES public.usuarios(id);


--
-- Name: traspasos traspasos_usuario_solicita_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.traspasos
    ADD CONSTRAINT traspasos_usuario_solicita_fkey FOREIGN KEY (usuario_solicita) REFERENCES public.usuarios(id);


--
-- Name: usuarios usuarios_id_sucursal_asignada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_sucursal_asignada_fkey FOREIGN KEY (id_sucursal_asignada) REFERENCES public.sucursales(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict BIjMDmbxjqpHV6o2V2drfcKIKPAKzRlUMiqyyK9KWxzoPPWQu4X2mJZon22GE6t

