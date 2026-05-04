--
-- PostgreSQL database dump
--

\restrict keeHsguyvGiAK6ORsPQ0eXLtRkPnjasUekSMayaV6VdNLYYmu9jGHclESz5GwFt

-- Dumped from database version 18.2
-- Dumped by pg_dump version 18.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cancel_order(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.cancel_order(IN p_order_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE orders
    SET status = 'cancelled'
    WHERE order_id = p_order_id;
END;
$$;


ALTER PROCEDURE public.cancel_order(IN p_order_id integer) OWNER TO postgres;

--
-- Name: get_customer_spending(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_customer_spending() RETURNS TABLE(customer_id integer, customer_name text, total_spent numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        (c.fname || ' ' || c.lname)::TEXT,
        SUM(o.price)::NUMERIC
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.fname, c.lname
    ORDER BY SUM(o.price) DESC;
END;
$$;


ALTER FUNCTION public.get_customer_spending() OWNER TO postgres;

--
-- Name: get_order_breakdown(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_order_breakdown() RETURNS TABLE(order_id integer, customer_name text, order_date date, status text, product_name text, quantity integer, service_name text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.order_id,
        (c.fname || ' ' || c.lname)::TEXT,
        o.order_date,
        o.status::TEXT,
        p.product_name::TEXT,
        oi.quantity,
        s.service_name::TEXT
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN order_services os ON o.order_id = os.order_id
    LEFT JOIN services s ON os.service_id = s.service_id
    ORDER BY o.order_id;
END;
$$;


ALTER FUNCTION public.get_order_breakdown() OWNER TO postgres;

--
-- Name: get_top_customers_cte(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_top_customers_cte() RETURNS TABLE(customer_id integer, customer_name text, total_orders integer, total_spent numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH customer_totals AS (
        SELECT 
            c.customer_id,
            CONCAT(c.fname, ' ', c.lname) AS customer_name,
            CAST(COUNT(o.order_id) AS INT) AS total_orders,
            SUM(o.price) AS total_spent
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id, c.fname, c.lname
    )
    SELECT 
        ct.customer_id,
        ct.customer_name,
        ct.total_orders,
        ct.total_spent
    FROM customer_totals ct
    ORDER BY ct.total_spent DESC;
END;
$$;


ALTER FUNCTION public.get_top_customers_cte() OWNER TO postgres;

--
-- Name: get_top_services(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_top_services() RETURNS TABLE(service_name text, times_used integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT sub.service_name, sub.times_used
    FROM (
        SELECT 
            CAST(s.service_name AS TEXT) AS service_name,
            CAST(COUNT(os.order_id) AS INT) AS times_used
        FROM services s
        JOIN order_services os ON s.service_id = os.service_id
        GROUP BY s.service_name
    ) sub
    ORDER BY sub.times_used DESC, sub.service_name ASC;
END;
$$;


ALTER FUNCTION public.get_top_services() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.addresses (
    address_id integer NOT NULL,
    customer_id integer,
    address1 character varying(100),
    address2 character varying(50),
    city character varying(50),
    state character varying(2),
    zip character varying(10)
);


ALTER TABLE public.addresses OWNER TO postgres;

--
-- Name: addresses_address_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.addresses_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.addresses_address_id_seq OWNER TO postgres;

--
-- Name: addresses_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.addresses_address_id_seq OWNED BY public.addresses.address_id;


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    appointment_id integer NOT NULL,
    customer_id integer,
    appointment_date timestamp without time zone,
    type character varying(50),
    notes text
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- Name: appointments_appointment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointments_appointment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.appointments_appointment_id_seq OWNER TO postgres;

--
-- Name: appointments_appointment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointments_appointment_id_seq OWNED BY public.appointments.appointment_id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    fname character varying(50) NOT NULL,
    lname character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    phone character varying(15) NOT NULL
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_customer_id_seq OWNER TO postgres;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_customer_id_seq OWNED BY public.customers.customer_id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    item_id integer NOT NULL,
    order_id integer,
    product_id integer,
    quantity integer
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: order_items_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_item_id_seq OWNER TO postgres;

--
-- Name: order_items_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_item_id_seq OWNED BY public.order_items.item_id;


--
-- Name: order_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_services (
    order_id integer NOT NULL,
    service_id integer NOT NULL
);


ALTER TABLE public.order_services OWNER TO postgres;

--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    order_id integer NOT NULL,
    order_date date,
    price numeric(10,2),
    customer_id integer,
    payment_method character varying(50),
    status character varying(50)
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_order_id_seq OWNER TO postgres;

--
-- Name: orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_order_id_seq OWNED BY public.orders.order_id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    product_id integer NOT NULL,
    product_name character varying(100),
    price numeric(10,2)
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_product_id_seq OWNER TO postgres;

--
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.services (
    service_id integer NOT NULL,
    service_name character varying(50) NOT NULL,
    price numeric(10,2)
);


ALTER TABLE public.services OWNER TO postgres;

--
-- Name: services_service_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.services_service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.services_service_id_seq OWNER TO postgres;

--
-- Name: services_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.services_service_id_seq OWNED BY public.services.service_id;


--
-- Name: addresses address_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addresses ALTER COLUMN address_id SET DEFAULT nextval('public.addresses_address_id_seq'::regclass);


--
-- Name: appointments appointment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments ALTER COLUMN appointment_id SET DEFAULT nextval('public.appointments_appointment_id_seq'::regclass);


--
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customers_customer_id_seq'::regclass);


--
-- Name: order_items item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN item_id SET DEFAULT nextval('public.order_items_item_id_seq'::regclass);


--
-- Name: orders order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN order_id SET DEFAULT nextval('public.orders_order_id_seq'::regclass);


--
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- Name: services service_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services ALTER COLUMN service_id SET DEFAULT nextval('public.services_service_id_seq'::regclass);


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.addresses (address_id, customer_id, address1, address2, city, state, zip) FROM stdin;
1	1	111 Example St	\N	Example	DE	11111
2	2	222 Example Rd	\N	Example	NJ	22222
3	3	742 Maple St	\N	Phoenixville	PA	19460
4	4	118 Oak Ave	Apt 2B	Collegeville	PA	19426
5	5	905 Pine Rd	\N	Norristown	PA	19401
6	6	67 Cedar Ln	\N	King of Prussia	PA	19406
7	7	384 Birch Dr	\N	Pottstown	PA	19464
8	8	1299 Walnut St	Apt 3A	West Chester	PA	19380
9	9	56 Chestnut Ave	\N	Lansdale	PA	19446
10	10	888 Spruce St	\N	Exton	PA	19341
11	11	431 Elm St	\N	Downingtown	PA	19335
12	12	72 Ash Dr	\N	Royersford	PA	19468
13	13	1602 Market St	\N	Philadelphia	PA	19103
14	14	245 Walnut St	Apt 5C	Philadelphia	PA	19106
15	15	778 Hamilton St	\N	Allentown	PA	18101
16	16	91 Broad St	\N	Bethlehem	PA	18018
17	17	520 Penn St	\N	Reading	PA	19601
18	18	140 State St	Apt 2A	Harrisburg	PA	17101
19	19	301 Queen St	\N	Lancaster	PA	17603
20	20	88 Market St	\N	York	PA	17401
21	21	512 Lackawanna Ave	\N	Scranton	PA	18503
22	22	73 Public Sq	\N	Wilkes-Barre	PA	18701
23	23	44 Kings Hwy	\N	Cherry Hill	NJ	08002
24	24	315 Federal St	Apt 1D	Camden	NJ	08103
25	25	120 Landis Ave	\N	Vineland	NJ	08360
26	26	88 High St	\N	Glassboro	NJ	08028
27	27	600 Fellowship Rd	\N	Mount Laurel	NJ	08054
28	28	205 White Horse Rd	Apt 3B	Voorhees	NJ	08043
29	29	777 Deptford Center Rd	\N	Deptford	NJ	08096
30	30	490 Hurffville Rd	\N	Washington Township	NJ	08080
31	31	11 Oak Tree Rd	\N	Edison	NJ	08820
32	32	150 State St	\N	Trenton	NJ	08608
33	33	908 Market St	\N	Wilmington	DE	19801
34	34	23 Loockerman St	Apt 2B	Dover	DE	19901
35	35	456 Main St	\N	Newark	DE	19711
36	36	789 Middletown Rd	\N	Middletown	DE	19709
37	37	62 Smyrna Ave	\N	Smyrna	DE	19977
38	38	300 Stein Hwy	Apt 4C	Seaford	DE	19973
39	39	18 Bedford St	\N	Georgetown	DE	19947
40	40	255 Walnut St	\N	Milford	DE	19963
41	41	701 Savannah Rd	\N	Lewes	DE	19958
42	42	12 Rehoboth Ave	\N	Rehoboth Beach	DE	19971
43	43	812 Maple St	\N	Phoenixville	PA	19460
44	44	99 Oak Ave	Apt 6C	Collegeville	PA	19426
45	45	602 Pine Rd	\N	Norristown	PA	19401
46	46	71 Cedar Ln	\N	King of Prussia	PA	19406
47	47	455 Birch Dr	\N	Pottstown	PA	19464
48	48	132 Walnut St	Apt 1B	West Chester	PA	19380
49	49	920 Chestnut Ave	\N	Lansdale	PA	19446
50	50	63 Spruce St	\N	Exton	PA	19341
51	51	510 Elm St	\N	Downingtown	PA	19335
52	52	84 Ash Dr	\N	Royersford	PA	19468
53	53	420 Liberty Ave	\N	Pittsburgh	PA	15222
54	54	118 State St	\N	Erie	PA	16501
55	55	77 11th Ave	\N	Altoona	PA	16601
56	56	512 College Ave	\N	State College	PA	16801
57	57	900 Main St	\N	Johnstown	PA	15901
58	58	215 Pittsburgh St	Apt 2D	Greensburg	PA	15601
59	59	63 Main St	\N	Butler	PA	16001
60	60	345 Beau St	\N	Washington	PA	15301
61	61	80 Main St	\N	Uniontown	PA	15401
62	62	701 Wilmington Rd	\N	New Castle	PA	16101
63	63	12 Kings Hwy	\N	Cherry Hill	NJ	08002
64	64	201 Federal St	Apt 3A	Camden	NJ	08103
65	65	455 Landis Ave	\N	Vineland	NJ	08360
66	66	73 High St	\N	Glassboro	NJ	08028
67	67	812 Fellowship Rd	\N	Mount Laurel	NJ	08054
68	68	144 White Horse Rd	Apt 1C	Voorhees	NJ	08043
69	69	620 Deptford Center Rd	\N	Deptford	NJ	08096
70	70	299 Hurffville Rd	\N	Washington Township	NJ	08080
71	71	42 Oak Tree Rd	\N	Edison	NJ	08820
72	72	311 State St	\N	Trenton	NJ	08608
73	73	500 Market St	\N	Wilmington	DE	19801
74	74	67 Loockerman St	Apt 5A	Dover	DE	19901
75	75	210 Main St	\N	Newark	DE	19711
76	76	640 Middletown Rd	\N	Middletown	DE	19709
77	77	88 Smyrna Ave	\N	Smyrna	DE	19977
78	78	121 Stein Hwy	Apt 2B	Seaford	DE	19973
79	79	52 Bedford St	\N	Georgetown	DE	19947
80	80	319 Walnut St	\N	Milford	DE	19963
81	81	811 Savannah Rd	\N	Lewes	DE	19958
82	82	25 Rehoboth Ave	\N	Rehoboth Beach	DE	19971
83	83	455 Hamilton St	\N	Allentown	PA	18101
84	84	200 Broad St	Apt 4D	Bethlehem	PA	18018
85	85	901 Penn St	\N	Reading	PA	19601
86	86	67 State St	\N	Harrisburg	PA	17101
87	87	311 Queen St	\N	Lancaster	PA	17603
88	88	150 Market St	Apt 2A	York	PA	17401
89	89	702 Lackawanna Ave	\N	Scranton	PA	18503
90	90	91 Public Sq	\N	Wilkes-Barre	PA	18701
91	91	415 Northampton St	\N	Easton	PA	18042
92	92	700 Broad St	\N	Hazleton	PA	18201
93	93	333 Maple St	\N	Phoenixville	PA	19460
94	94	812 Oak Ave	Apt 7C	Collegeville	PA	19426
95	95	77 Pine Rd	\N	Norristown	PA	19401
96	96	615 Cedar Ln	\N	King of Prussia	PA	19406
97	97	902 Birch Dr	\N	Pottstown	PA	19464
98	98	48 Walnut St	Apt 8A	West Chester	PA	19380
99	99	711 Chestnut Ave	\N	Lansdale	PA	19446
100	100	222 Spruce St	\N	Exton	PA	19341
101	101	534 Delp Rd	\N	Souderton	PA	18964
\.


--
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointments (appointment_id, customer_id, appointment_date, type, notes) FROM stdin;
1	1	2025-04-20 10:00:00	Installation	On-site full simulator build, including wheel, pedals, triple monitor setup, PC installation, and software configuration.
2	2	2026-04-22 13:00:00	Software Installation	Installed and configured racing simulator software, drivers, and control calibration settings.
104	3	2024-01-05 14:00:00	Consultation	Initial consultation
105	4	2024-01-06 10:30:00	Consultation	Discussed budget and space
106	5	2024-01-07 16:00:00	Consultation	High-end simulator interest
107	6	2024-01-08 09:00:00	Consultation	Reviewed wheelbase options
108	7	2024-01-09 13:00:00	Consultation	Prefers compact rig
109	8	2024-01-10 11:00:00	Consultation	VR vs triple monitor discussion
110	9	2024-01-11 15:30:00	Consultation	Pedal recommendations
111	10	2024-01-12 12:00:00	Consultation	General Q&A
112	11	2024-01-13 09:30:00	Consultation	Motion platform interest
113	12	2024-01-14 14:30:00	Consultation	Shipping options review
114	13	2024-01-20 10:00:00	Build	On-site build scheduled
115	14	2024-01-21 13:00:00	Build	Customer provided all parts
116	15	2024-01-22 09:00:00	Build	Full rig assembly
117	16	2024-01-23 11:00:00	Build	Wheelbase and pedal installation
118	17	2024-01-24 15:00:00	Build	Monitor mount installation
119	18	2024-01-25 10:30:00	Build	Cable management and finishing
120	19	2024-01-26 14:00:00	Build	Custom seat rail request
121	20	2024-01-27 16:00:00	Build	Delivered pre-assembled rig
122	21	2024-01-28 09:00:00	Build	Added accessories
123	22	2024-01-29 13:30:00	Build	Installation completed
124	23	2024-02-02 10:00:00	Installation	Software installation
125	24	2024-02-03 11:30:00	Installation	Hardware verification
126	25	2024-02-04 14:00:00	Installation	Pedal setup
127	26	2024-02-05 16:00:00	Installation	Triple monitor alignment
128	27	2024-02-06 09:00:00	Installation	VR setup
129	28	2024-02-07 12:00:00	Installation	Advanced configuration
130	29	2024-02-08 15:00:00	Installation	Firmware updates
131	30	2024-02-09 10:30:00	Installation	Steering lock setup
132	31	2024-02-10 13:00:00	Installation	Telemetry configuration
133	32	2024-02-11 11:00:00	Installation	Final installation checks
134	33	2024-02-15 09:00:00	Calibration	Force feedback tuning
135	34	2024-02-16 10:30:00	Calibration	Beginner calibration session
136	35	2024-02-17 14:00:00	Calibration	Intermediate calibration
137	36	2024-02-18 16:00:00	Calibration	Track-specific calibration
138	37	2024-02-19 11:00:00	Calibration	Brake and throttle curves
139	38	2024-02-20 13:00:00	Calibration	Cornering calibration
140	39	2024-02-21 15:00:00	Calibration	Advanced calibration
141	40	2024-02-22 09:30:00	Calibration	Telemetry-based calibration
142	41	2024-02-23 12:00:00	Calibration	Hotlap calibration
143	42	2024-02-24 14:30:00	Calibration	Final calibration session
144	43	2024-03-01 10:00:00	Consultation	Follow-up consultation
145	44	2024-03-02 11:30:00	Consultation	Upgrade discussion
146	45	2024-03-03 14:00:00	Consultation	Pedal upgrade interest
147	46	2024-03-04 16:00:00	Consultation	Cockpit options review
148	47	2024-03-05 09:00:00	Consultation	Monitor size discussion
149	48	2024-03-06 12:00:00	Consultation	Compact rig planning
150	49	2024-03-07 15:00:00	Consultation	VR performance review
151	50	2024-03-08 10:30:00	Consultation	Shipping timeline
152	51	2024-03-09 13:00:00	Consultation	Motion platform interest
153	52	2024-03-10 11:00:00	Consultation	Accessory recommendations
154	53	2024-03-12 09:00:00	Build	On-site build scheduled
155	54	2024-03-13 13:00:00	Build	Parts verified
156	55	2024-03-14 15:00:00	Build	Full rig assembly
157	56	2024-03-15 10:30:00	Build	Wheelbase installation
158	57	2024-03-16 14:00:00	Build	Monitor mount installation
159	58	2024-03-17 16:00:00	Build	Cable management
160	59	2024-03-18 09:00:00	Build	Seat rail customization
161	60	2024-03-19 12:00:00	Build	Pre-assembled rig delivery
162	61	2024-03-20 15:30:00	Build	Accessory installation
163	62	2024-03-21 11:00:00	Build	Installation completed
164	63	2024-03-25 10:00:00	Installation	Software installation
165	64	2024-03-26 11:30:00	Installation	Force feedback setup
166	65	2024-03-27 14:00:00	Installation	Pedal curve setup
167	66	2024-03-28 16:00:00	Installation	Monitor alignment
168	67	2024-03-29 09:00:00	Installation	VR optimization
169	68	2024-03-30 12:00:00	Installation	Advanced settings
170	69	2024-03-31 15:00:00	Installation	Firmware updates
171	70	2024-04-01 10:30:00	Installation	Steering lock setup
172	71	2024-04-02 13:00:00	Installation	Telemetry setup
173	72	2024-04-03 11:00:00	Installation	Final installation checks
174	73	2024-04-05 09:00:00	Coaching	Intro to controls
175	74	2024-04-06 10:30:00	Coaching	Beginner driving
176	75	2024-04-07 14:00:00	Coaching	Intermediate driving
177	76	2024-04-08 16:00:00	Coaching	Track map review
178	77	2024-04-09 11:00:00	Coaching	Braking and throttle
179	78	2024-04-10 13:00:00	Coaching	Cornering fundamentals
180	79	2024-04-11 15:00:00	Coaching	Advanced racecraft
181	80	2024-04-12 09:30:00	Coaching	Telemetry analysis
182	81	2024-04-13 12:00:00	Coaching	Hotlap practice
183	82	2024-04-14 14:30:00	Coaching	Final coaching session
184	83	2024-04-16 10:00:00	Consultation	Follow-up consultation
185	84	2024-04-17 11:30:00	Consultation	Upgrade discussion
186	85	2024-04-18 14:00:00	Consultation	Pedal upgrade interest
187	86	2024-04-19 16:00:00	Consultation	Cockpit options review
188	87	2024-04-20 09:00:00	Consultation	Monitor size discussion
189	88	2024-04-21 12:00:00	Consultation	Compact rig planning
190	89	2024-04-22 15:00:00	Consultation	VR performance review
191	90	2024-04-23 10:30:00	Consultation	Shipping timeline
192	91	2024-04-24 13:00:00	Consultation	Motion platform interest
193	92	2024-04-25 11:00:00	Consultation	Accessory recommendations
194	93	2024-04-27 09:00:00	Build	On-site build scheduled
195	94	2024-04-28 13:00:00	Build	Parts verified
196	95	2024-04-29 15:00:00	Build	Full rig assembly
197	96	2024-04-30 10:30:00	Build	Wheelbase installation
198	97	2024-05-01 14:00:00	Build	Monitor mount installation
199	98	2024-05-02 16:00:00	Build	Cable management
200	99	2024-05-03 09:00:00	Build	Seat rail customization
201	100	2024-05-04 12:00:00	Build	Pre-assembled rig delivery
202	101	2024-05-05 15:30:00	Build	Accessory installation
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (customer_id, fname, lname, email, phone) FROM stdin;
1	Chris	Capehart	ccapehart@example.com	111-111-1111
2	Chris	Griffith	cgriffith@example.com	222-222-2222
3	Liam	Anderson	landerson@example.com	4845551001
4	Noah	Martinez	nmartinez@example.com	6105551002
5	Oliver	Thompson	othompson@example.com	2155551003
6	Elijah	White	ewhite@example.com	3025551004
7	James	Harris	jharris@example.com	2675551005
8	William	Clark	wclark@example.com	7175551006
9	Benjamin	Lewis	blewis@example.com	5705551007
10	Lucas	Robinson	lrobinson@example.com	8565551008
11	Henry	Walker	hwalker@example.com	9085551009
12	Alexander	Young	ayoung@example.com	6095551010
13	Mason	Allen	mallen@example.com	4845551011
14	Michael	King	mking@example.com	6105551012
15	Ethan	Wright	ewright@example.com	2155551013
16	Daniel	Scott	dscott@example.com	3025551014
17	Jacob	Green	jgreen@example.com	2675551015
18	Logan	Baker	lbaker@example.com	7175551016
19	Jackson	Adams	jadams@example.com	5705551017
20	Levi	Nelson	lnelson@example.com	8565551018
21	Sebastian	Carter	scarter@example.com	9085551019
22	Mateo	Mitchell	mmitchell@example.com	6095551020
23	Jack	Perez	jperez@example.com	4845551021
24	Owen	Roberts	oroberts@example.com	6105551022
25	Theodore	Turner	tturner@example.com	2155551023
26	Aiden	Phillips	aphillips@example.com	3025551024
27	Samuel	Campbell	scampbell@example.com	2675551025
28	Joseph	Parker	jparker@example.com	7175551026
29	John	Evans	jevans@example.com	5705551027
30	David	Edwards	dedwards@example.com	8565551028
31	Wyatt	Collins	wcollins@example.com	9085551029
32	Matthew	Stewart	mstewart@example.com	6095551030
33	Luke	Sanchez	lsanchez@example.com	4845551031
34	Asher	Morris	amorris@example.com	6105551032
35	Carter	Rogers	crogers@example.com	2155551033
36	Julian	Reed	jreed@example.com	3025551034
37	Grayson	Cook	gcook@example.com	2675551035
38	Leo	Morgan	lmorgan@example.com	7175551036
39	Jayden	Bell	jbell@example.com	5705551037
40	Gabriel	Murphy	gmurphy@example.com	8565551038
41	Isaac	Bailey	ibailey@example.com	9085551039
42	Lincoln	Rivera	lrivera@example.com	6095551040
43	Anthony	Cooper	acooper@example.com	4845551041
44	Hudson	Richardson	hrichardson@example.com	6105551042
45	Dylan	Cox	dcox@example.com	2155551043
46	Ezra	Howard	ehoward@example.com	3025551044
47	Thomas	Ward	tward@example.com	2675551045
48	Charles	Torres	ctorres@example.com	7175551046
49	Christopher	Peterson	cpeterson@example.com	5705551047
50	Jaxon	Gray	jgray@example.com	8565551048
51	Maverick	Ramirez	mramirez@example.com	9085551049
52	Josiah	James	jjames@example.com	6095551050
53	Elias	Watson	ewatson@example.com	4845551051
54	Adrian	Brooks	abrooks@example.com	6105551052
55	Colton	Kelly	ckelly@example.com	2155551053
56	Landon	Sanders	lsanders@example.com	3025551054
57	Hunter	Price	hprice@example.com	2675551055
58	Jonathan	Bennett	jbennett@example.com	7175551056
59	Santiago	Wood	swood@example.com	5705551057
60	Axel	Barnes	abarnes@example.com	8565551058
61	Easton	Ross	eross@example.com	9085551059
62	Cooper	Henderson	chenderson@example.com	6095551060
63	Nathan	Coleman	ncoleman@example.com	4845551061
64	Aaron	Jenkins	ajenkins@example.com	6105551062
65	Kayden	Perry	kperry@example.com	2155551063
66	Bentley	Powell	bpowell@example.com	3025551064
67	Ryker	Long	rlong@example.com	2675551065
68	Zachary	Patterson	zpatterson@example.com	7175551066
69	Parker	Hughes	phughes@example.com	5705551067
70	Evan	Flores	eflores@example.com	8565551068
71	Weston	Washington	wwashington@example.com	9085551069
72	Miles	Butler	mbutler@example.com	6095551070
73	Jason	Simmons	jsimmons@example.com	4845551071
74	Declan	Foster	dfoster@example.com	6105551072
75	Carson	Gonzales	cgonzales@example.com	2155551073
76	Emmett	Bryant	ebryant@example.com	3025551074
77	Greyson	Alexander	galexander@example.com	2675551075
78	Nicholas	Russell	nrussell@example.com	7175551076
79	Dominic	Griffin	dgriffin@example.com	5705551077
80	Jace	Diaz	jdiaz@example.com	8565551078
81	Adam	Hayes	ahayes@example.com	9085551079
82	Ian	Myers	imyers@example.com	6095551080
83	Austin	Ford	aford@example.com	4845551081
84	Brody	Hamilton	bhamilton@example.com	6105551082
85	Xavier	Graham	xgraham@example.com	2155551083
86	Jose	Sullivan	jsullivan@example.com	3025551084
87	Jasper	Wallace	jwallace@example.com	2675551085
88	Sawyer	Woods	swoods@example.com	7175551086
89	Silas	Cole	scole@example.com	5705551087
90	Brayden	West	bwest@example.com	8565551088
91	Gavin	Jordan	gjordan@example.com	9085551089
92	Chase	Owens	cowens@example.com	6095551090
93	Ryder	Reynolds	rreynolds@example.com	4845551091
94	Diego	Fisher	dfisher@example.com	6105551092
95	Micah	Ellis	mellis@example.com	2155551093
96	Theo	Harrison	tharrison@example.com	3025551094
97	Jonah	Gibson	jgibson@example.com	2675551095
98	Caleb	McDonald	cmcdonald@example.com	7175551096
99	Cole	Cruz	ccruz@example.com	5705551097
100	Maxwell	Marshall	mmarshall@example.com	8565551098
101	Tristan	Ortiz	tortiz@example.com	9085551099
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (item_id, order_id, product_id, quantity) FROM stdin;
1	1	1	1
2	1	2	1
3	1	3	1
4	1	4	3
5	1	1	1
6	1	4	3
7	2	31	1
8	3	5	1
9	3	7	1
10	4	43	2
11	5	2	1
12	5	36	1
13	6	32	1
14	7	8	1
15	7	10	1
16	8	31	1
17	9	3	1
18	9	4	3
19	10	33	1
20	11	6	1
21	11	7	1
22	12	42	1
23	13	17	1
24	13	36	1
25	14	25	2
26	15	5	1
27	15	20	1
28	16	31	1
29	17	11	1
30	17	21	1
31	18	34	1
32	19	3	1
33	19	27	2
34	20	43	1
35	21	13	1
36	21	15	1
37	22	32	1
38	23	9	1
39	23	20	1
40	24	31	1
41	25	16	1
42	25	36	1
43	26	42	1
44	27	5	1
45	27	7	1
46	28	33	1
47	29	3	1
48	29	28	2
49	30	34	1
50	31	11	1
51	31	12	1
52	32	31	1
53	33	17	1
54	33	37	1
55	34	25	2
56	35	6	1
57	35	20	1
58	36	42	1
59	37	8	1
60	37	10	1
61	38	32	1
62	39	3	1
63	39	26	2
64	40	43	1
65	41	13	1
66	41	14	1
67	42	31	1
68	43	16	1
69	43	36	1
70	44	25	2
71	45	5	1
72	45	7	1
73	46	42	1
74	47	11	1
75	47	21	1
76	48	33	1
77	49	3	1
78	49	27	2
79	50	34	1
80	51	17	1
81	51	37	1
82	52	31	1
83	53	9	1
84	53	20	1
85	54	25	2
86	55	6	1
87	55	7	1
88	56	42	1
89	57	8	1
90	57	10	1
91	58	32	1
92	59	3	1
93	59	28	2
94	60	43	1
95	61	13	1
96	61	15	1
97	62	31	1
98	63	16	1
99	63	36	1
100	64	25	2
101	65	5	1
102	65	7	1
103	66	42	1
104	67	11	1
105	67	21	1
106	68	33	1
107	69	3	1
108	69	27	2
109	70	34	1
110	71	17	1
111	71	37	1
112	72	31	1
113	73	9	1
114	73	20	1
115	74	25	2
116	75	6	1
117	75	7	1
118	76	42	1
119	77	8	1
120	77	10	1
121	78	32	1
122	79	3	1
123	79	28	2
124	80	43	1
125	81	13	1
126	81	14	1
127	82	31	1
128	83	16	1
129	83	36	1
130	84	25	2
131	85	5	1
132	85	7	1
133	86	42	1
134	87	11	1
135	87	21	1
136	88	33	1
137	89	3	1
138	89	27	2
139	90	34	1
140	91	17	1
141	91	37	1
142	92	31	1
143	93	9	1
144	93	20	1
145	94	25	2
146	95	6	1
147	95	7	1
148	96	42	1
149	97	8	1
150	97	10	1
151	98	32	1
152	99	3	1
153	99	28	2
154	100	43	1
155	101	13	1
156	101	15	1
157	102	31	1
\.


--
-- Data for Name: order_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_services (order_id, service_id) FROM stdin;
1	1
1	2
1	3
2	3
3	1
3	3
4	4
5	1
5	2
6	3
7	1
7	3
8	4
9	1
9	2
9	3
10	3
11	1
11	3
12	4
13	1
13	2
14	3
15	1
15	3
16	4
17	1
17	2
17	3
18	3
19	1
19	3
20	4
21	1
21	2
22	3
23	1
23	3
24	4
25	1
25	2
26	3
27	1
27	3
28	4
29	1
29	2
29	3
30	3
31	1
31	2
31	3
32	4
33	1
33	3
34	3
35	1
35	2
36	4
37	1
37	3
38	3
39	1
39	2
39	3
40	4
41	1
41	2
42	3
43	1
43	3
44	4
45	1
45	2
46	3
47	1
47	3
48	4
49	1
49	2
49	3
50	3
51	1
51	2
51	3
52	3
53	1
53	3
54	4
55	1
55	2
56	3
57	1
57	3
58	4
59	1
59	2
59	3
60	3
61	1
61	2
62	3
63	1
63	3
64	4
65	1
65	2
66	3
67	1
67	3
68	4
69	1
69	2
69	3
70	3
71	1
71	2
71	3
72	3
73	1
73	3
74	4
75	1
75	2
76	3
77	1
77	3
78	4
79	1
79	2
79	3
80	3
81	1
81	2
82	3
83	1
83	3
84	4
85	1
85	2
86	3
87	1
87	3
88	4
89	1
89	2
89	3
90	3
91	1
91	2
91	3
92	3
93	1
93	3
94	4
95	1
95	2
96	3
97	1
97	3
98	4
99	1
99	2
99	3
100	3
101	1
101	2
102	3
103	3
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (order_id, order_date, price, customer_id, payment_method, status) FROM stdin;
1	2025-04-13	7038.97	1	Credit Card	Completed
2	2026-04-21	250.00	2	PayPal	Pending
3	2025-04-13	4200.00	1	Credit Card	completed
4	2025-04-15	800.00	2	Debit Card	completed
6	2025-04-22	300.00	4	Cash	completed
7	2025-04-25	2200.00	5	Credit Card	completed
8	2025-04-28	450.00	6	PayPal	completed
9	2025-05-01	1800.00	7	Credit Card	completed
10	2025-05-03	275.00	8	Debit Card	completed
11	2025-05-06	3200.00	9	Credit Card	completed
12	2025-05-08	600.00	10	PayPal	completed
13	2025-05-10	1400.00	11	Credit Card	completed
14	2025-05-12	350.00	12	Cash	completed
15	2025-05-15	2600.00	13	Credit Card	completed
16	2025-05-18	900.00	14	Debit Card	completed
17	2025-05-20	1750.00	15	Credit Card	completed
18	2025-05-22	500.00	16	PayPal	completed
19	2025-05-25	3100.00	17	Credit Card	completed
20	2025-05-28	700.00	18	Credit Card	completed
21	2025-06-01	2100.00	19	Debit Card	completed
22	2025-06-03	450.00	20	Cash	completed
23	2025-06-05	3800.00	21	Credit Card	completed
24	2025-06-08	1200.00	22	PayPal	completed
25	2025-06-10	2900.00	23	Credit Card	completed
26	2025-06-12	650.00	24	Debit Card	completed
27	2025-06-15	1700.00	25	Credit Card	completed
28	2025-06-18	300.00	26	Cash	completed
29	2025-06-20	2400.00	27	Credit Card	completed
30	2025-06-22	800.00	28	PayPal	completed
31	2025-06-25	3300.00	29	Credit Card	completed
32	2025-06-28	950.00	30	Debit Card	completed
33	2025-07-01	4100.00	31	Credit Card	completed
34	2025-07-03	600.00	32	Cash	completed
35	2025-07-06	2600.00	33	Credit Card	completed
36	2025-07-08	1200.00	34	Debit Card	completed
37	2025-07-10	1950.00	35	Credit Card	completed
38	2025-07-12	400.00	36	PayPal	completed
39	2025-07-15	3000.00	37	Credit Card	completed
40	2025-07-18	750.00	38	Credit Card	completed
41	2025-07-20	2200.00	39	Debit Card	completed
42	2025-07-22	500.00	40	Cash	completed
43	2025-07-25	3700.00	41	Credit Card	completed
44	2025-07-28	900.00	42	PayPal	completed
45	2025-08-01	2800.00	43	Credit Card	completed
46	2025-08-03	650.00	44	Debit Card	completed
47	2025-08-05	1600.00	45	Credit Card	completed
48	2025-08-08	350.00	46	Cash	completed
49	2025-08-10	3100.00	47	Credit Card	completed
50	2025-08-12	700.00	48	PayPal	completed
51	2025-08-15	2500.00	49	Credit Card	completed
52	2025-08-18	800.00	50	Debit Card	completed
53	2025-08-20	4200.00	51	Credit Card	completed
54	2025-08-22	1000.00	52	Credit Card	completed
55	2025-08-25	2700.00	53	PayPal	completed
56	2025-08-28	600.00	54	Debit Card	completed
57	2025-09-01	1800.00	55	Credit Card	completed
58	2025-09-03	400.00	56	Cash	completed
59	2025-09-05	3000.00	57	Credit Card	completed
60	2025-09-08	750.00	58	PayPal	completed
61	2025-09-10	2100.00	59	Credit Card	completed
62	2025-09-12	500.00	60	Debit Card	completed
63	2025-09-15	3900.00	61	Credit Card	completed
64	2025-09-18	1100.00	62	PayPal	completed
65	2025-09-20	2600.00	63	Credit Card	completed
66	2025-09-22	700.00	64	Debit Card	completed
67	2025-09-25	1500.00	65	Credit Card	completed
68	2025-09-28	350.00	66	Cash	completed
69	2025-10-01	3100.00	67	Credit Card	completed
70	2025-10-03	800.00	68	PayPal	completed
71	2025-10-05	2400.00	69	Credit Card	completed
72	2025-10-08	600.00	70	Debit Card	completed
73	2025-10-10	4000.00	71	Credit Card	completed
74	2025-10-12	950.00	72	Credit Card	completed
75	2025-10-15	2800.00	73	PayPal	completed
76	2025-10-18	650.00	74	Debit Card	completed
77	2025-10-20	1700.00	75	Credit Card	completed
78	2025-10-22	450.00	76	Cash	completed
79	2025-10-25	3200.00	77	Credit Card	completed
80	2025-10-28	700.00	78	PayPal	completed
81	2025-11-01	2600.00	79	Credit Card	completed
82	2025-11-03	850.00	80	Debit Card	completed
83	2025-11-05	4100.00	81	Credit Card	completed
84	2025-11-08	1200.00	82	PayPal	completed
85	2025-11-10	2900.00	83	Credit Card	completed
86	2025-11-12	600.00	84	Debit Card	completed
87	2025-11-15	1800.00	85	Credit Card	completed
88	2025-11-18	400.00	86	Cash	completed
89	2025-11-20	3000.00	87	Credit Card	completed
90	2025-11-22	750.00	88	PayPal	completed
91	2025-11-25	2200.00	89	Credit Card	completed
92	2025-11-28	500.00	90	Debit Card	completed
93	2025-12-01	3700.00	91	Credit Card	completed
94	2025-12-03	900.00	92	PayPal	completed
95	2025-12-05	2800.00	93	Credit Card	completed
96	2025-12-08	650.00	94	Debit Card	completed
97	2025-12-10	1600.00	95	Credit Card	completed
98	2025-12-12	350.00	96	Cash	completed
99	2025-12-15	3100.00	97	Credit Card	completed
100	2025-12-18	700.00	98	PayPal	completed
101	2025-12-20	2500.00	99	Credit Card	completed
102	2025-12-22	800.00	100	Debit Card	completed
103	2025-12-24	4200.00	101	Credit Card	pending
5	2025-04-20	1500.00	3	Credit Card	cancelled
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (product_id, product_name, price) FROM stdin;
1	Turtle Beach VelocityOne Race Wheel & Pedal System	649.99
2	Imperator GM-520 Zero Gravity Reclining Workstation Gaming Cockpit (5-Monitor Brackets, Black)	2899.00
3	HP Omen 40L Gaming Desktop i9-14900K RTX 4080 SUPER 64GB DDR5 2TB SSD	2190.00
4	Samsung 32" Odyssey G5 Gaming Monitor LC32G55TQWNXZA	299.99
5	Moza R9 Direct Drive Wheel Base	399.00
6	Moza CS V2 Steering Wheel	279.00
7	Moza SR-P Load Cell Pedals	199.00
8	Simagic Alpha Mini Wheel Base	599.00
9	Simagic FX Formula Wheel	499.00
10	Simagic P2000 Pedals	699.00
11	Simucube 2 Sport Base	1299.00
12	Simucube Tahko GT-21 Wireless Wheel	999.00
13	Fanatec CSL DD 8Nm Base	499.00
14	Fanatec ClubSport Formula V2.5 Wheel	399.00
15	Fanatec CSL Pedals LC	199.00
16	Sim Lab GT1 Evo Cockpit	449.00
17	Sim Lab P1-X Pro Cockpit	899.00
18	Next Level Racing F-GT Elite Cockpit	799.00
19	Trak Racer TR160 Cockpit	899.00
20	Heusinkveld Sprint Pedals	699.00
21	Heusinkveld Ultimate+ Pedals	1199.00
22	Thrustmaster T818 Base	799.00
23	Thrustmaster SF1000 Ferrari Wheel	499.00
24	Thrustmaster T-LCM Pedals	229.00
25	LG UltraGear 27GP850-B 27 Monitor,379.99\r\nDell S2721DGF 27 Gaming Monitor	329.99
26	ASUS TUF VG32VQ1B 32 Curved Monitor,299.99\r\nSamsung Odyssey Neo G7 43 Monitor	999.99
27	NZXT Player Three Gaming PC RTX 4080	2499.00
28	Corsair Vengeance i7400 Gaming PC	2299.00
29	Logitech G Pro X Mechanical Keyboard	149.99
30	Logitech G502 X Gaming Mouse	79.99
31	Elgato Stream Deck MK.2	149.99
32	GT Omega Apex Wheel Stand	149.00
33	Next Level Racing Wheel Stand 2.0	249.00
34	Sim Lab Monitor Stand Triple	349.00
35	Advanced Sim Racing Triple Monitor Stand	399.00
36	Buttkicker Gamer Plus Haptic Feedback Kit	299.00
37	SimHub Compatible Bass Shaker Kit	199.00
38	HP Reverb G2 VR Headset	499.00
39	Meta Quest 3 VR Headset	499.00
40	Cable Management Kit for Sim Rigs	49.99
41	High-End Racing Gloves	39.99
42	Sim Racing Seat Bucket Style	299.00
43	Adjustable Keyboard Tray for Cockpit	89.99
\.


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.services (service_id, service_name, price) FROM stdin;
1	Free Consultation	0.00
2	Full Simulator Build & Assembly	300.00
3	On-Site Installation & Travel	200.00
4	Software Setup & Calibration	150.00
5	Driver Coaching Session	100.00
\.


--
-- Name: addresses_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.addresses_address_id_seq', 101, true);


--
-- Name: appointments_appointment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointments_appointment_id_seq', 202, true);


--
-- Name: customers_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_customer_id_seq', 101, true);


--
-- Name: order_items_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_item_id_seq', 157, true);


--
-- Name: orders_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_order_id_seq', 103, true);


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_product_id_seq', 43, true);


--
-- Name: services_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.services_service_id_seq', 5, true);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (address_id);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (appointment_id);


--
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (item_id);


--
-- Name: order_services order_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_services
    ADD CONSTRAINT order_services_pkey PRIMARY KEY (order_id, service_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_id);


--
-- Name: services services_service_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_service_name_key UNIQUE (service_name);


--
-- Name: addresses addresses_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: appointments appointments_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id);


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- Name: order_services order_services_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_services
    ADD CONSTRAINT order_services_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id);


--
-- Name: order_services order_services_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_services
    ADD CONSTRAINT order_services_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- PostgreSQL database dump complete
--

\unrestrict keeHsguyvGiAK6ORsPQ0eXLtRkPnjasUekSMayaV6VdNLYYmu9jGHclESz5GwFt

