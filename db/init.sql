SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categorias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE public.categorias OWNER TO postgres;

--
-- Name: detalles_venta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalles_venta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    venta uuid NOT NULL,
    medicamento uuid NOT NULL,
    cantidad integer NOT NULL,
    sub_total money,
    CONSTRAINT detalles_venta_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT detalles_venta_cantidad_check1 CHECK (((cantidad)::numeric >= (0)::numeric))
);


ALTER TABLE public.detalles_venta OWNER TO postgres;

--
-- Name: medicamentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicamentos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(150) NOT NULL,
    cantidad_disponible integer DEFAULT 0 NOT NULL,
    precio_unidad money NOT NULL,
    categoria uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    imagen_data bytea,
    CONSTRAINT medicamentos_cantidad_disponible_check CHECK ((cantidad_disponible >= 0)),
    CONSTRAINT medicamentos_precio_unidad_check CHECK (((precio_unidad)::numeric >= (0)::numeric))
);


ALTER TABLE public.medicamentos OWNER TO postgres;

--
-- Name: ventas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ventas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    total money,
    CONSTRAINT ventas_total_check CHECK (((total)::numeric >= (0)::numeric))
);


ALTER TABLE public.ventas OWNER TO postgres;

--
-- Name: view_medicamentos_categoria; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_medicamentos_categoria AS
 SELECT m.nombre AS medicamento,
    m.cantidad_disponible AS "cantidad disponible",
    m.precio_unidad AS "precio por unidad",
    c.nombre AS "categoría"
   FROM (public.medicamentos m
     LEFT JOIN public.categorias c ON ((m.categoria = c.id)));


ALTER VIEW public.view_medicamentos_categoria OWNER TO postgres;

--
-- Name: view_ventas_detalles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_ventas_detalles AS
SELECT
    NULL::timestamp without time zone AS fecha,
    NULL::character varying(150) AS medicamento,
    NULL::money AS "precio por unidad",
    NULL::integer AS cantidad,
    NULL::money AS subtotal,
    NULL::money AS total;


ALTER VIEW public.view_ventas_detalles OWNER TO postgres;

--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: detalles_venta detalles_venta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalles_venta
    ADD CONSTRAINT detalles_venta_pkey PRIMARY KEY (id);


--
-- Name: medicamentos medicamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicamentos
    ADD CONSTRAINT medicamentos_pkey PRIMARY KEY (id);


--
-- Name: ventas ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_pkey PRIMARY KEY (id);


--
-- Name: view_ventas_detalles _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.view_ventas_detalles AS
 SELECT v.fecha,
    m.nombre AS medicamento,
    m.precio_unidad AS "precio por unidad",
    d.cantidad,
    d.sub_total AS subtotal,
    v.total
   FROM ((public.ventas v
     JOIN public.detalles_venta d ON ((v.id = d.venta)))
     JOIN public.medicamentos m ON ((d.medicamento = m.id)))
  GROUP BY v.id, v.total, d.medicamento, d.cantidad, d.sub_total, m.nombre, m.precio_unidad
  ORDER BY v.fecha DESC;



--
-- Name: fn_farmacia_actualizar_detalle_venta(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_farmacia_actualizar_detalle_venta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
        precio MONEY;
BEGIN
        -- Verificar stock disponible
        IF (SELECT cantidad_disponible FROM medicamentos WHERE id = NEW.medicamento) < NEW.cantidad THEN
                RAISE EXCEPTION 'No hay suficiente cantidad disponible para el medicamento con ID: %', NEW.medicamento;
        END IF;

        UPDATE medicamentos
        SET cantidad_disponible = cantidad_disponible - NEW.cantidad
        WHERE id = NEW.medicamento;
        -- Calcular subtotal
        SELECT precio_unidad INTO precio
        FROM medicamentos m
        WHERE m.id = NEW.medicamento;

        NEW.sub_total := precio * NEW.cantidad;

        RETURN NEW;
END;
$$;

ALTER FUNCTION public.fn_farmacia_actualizar_detalle_venta() OWNER TO postgres;

--
-- Name: fn_farmacia_calcular_total(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_farmacia_calcular_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
        -- Se suma las subtotales de los detalles de cada venta, si aún no hay subtotal es 0.00
        UPDATE ventas
        SET total = (
                SELECT COALESCE(SUM(sub_total), '0.00'::MONEY)
                FROM detalles_venta
                WHERE venta = NEW.venta
        )
        WHERE id = NEW.venta;

        RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_farmacia_calcular_total() OWNER TO postgres;

--
-- Name: fn_farmacia_medicamentos_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_farmacia_medicamentos_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
        NEW.updated_at := CURRENT_TIMESTAMP;
        RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_farmacia_medicamentos_update() OWNER TO postgres;

--
-- Name: detalles_venta tr_actualizar_detalle_venta; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_actualizar_detalle_venta BEFORE INSERT ON public.detalles_venta FOR EACH ROW EXECUTE FUNCTION public.fn_farmacia_actualizar_detalle_venta();


--
-- Name: detalles_venta tr_calcular_total; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_calcular_total AFTER INSERT ON public.detalles_venta FOR EACH ROW EXECUTE FUNCTION public.fn_farmacia_calcular_total();


--
-- Name: medicamentos tr_medicament_actualizado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_medicament_actualizado BEFORE UPDATE ON public.medicamentos FOR EACH ROW EXECUTE FUNCTION public.fn_farmacia_medicamentos_update();


--
-- Name: detalles_venta detalles_venta_medicamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalles_venta
    ADD CONSTRAINT detalles_venta_medicamento_fkey FOREIGN KEY (medicamento) REFERENCES public.medicamentos(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: detalles_venta detalles_venta_venta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalles_venta
    ADD CONSTRAINT detalles_venta_venta_fkey FOREIGN KEY (venta) REFERENCES public.ventas(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: medicamentos medicamentos_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicamentos
    ADD CONSTRAINT medicamentos_categoria_fkey FOREIGN KEY (categoria) REFERENCES public.categorias(id) ON UPDATE CASCADE ON DELETE SET NULL;
