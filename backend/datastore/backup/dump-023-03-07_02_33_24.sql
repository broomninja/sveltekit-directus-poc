--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Drop databases (except postgres and template1)
--

DROP DATABASE directus;
DROP DATABASE template_postgis;

--
-- Drop roles
--

DROP ROLE ddb_user;
DROP ROLE postgres;

--
-- Roles
--

CREATE ROLE ddb_user;
ALTER ROLE ddb_user WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:nuiGsg3Z6BoPN3OabqJHFg==$Q4KKWPXE4pe1htP+af+vczXYdiguwzZmsqHIfSQJ0qc=:gFXdjiAgvK/erM8cCZF/RJML1O0Tk6MLHSFwOKvHu+Q=';
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:WihbDdYt35xDkoonBybQEA==$nKuRFZNBbeyjq1I8mlhunCKFJXdDZG5lSPs6HmAEyHI=:iScjd+m91QuX+kTVdXF+KidHTiaHAMz7tGVaAdRiDTA=';

--
-- User Configurations
--








--
-- Databases
--

--
-- Database "template1" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 15.2 (Debian 15.2-1.pgdg110+1)
-- Dumped by pg_dump version 15.2 (Debian 15.2-1.pgdg110+1)

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

UPDATE pg_catalog.pg_database SET datistemplate = false WHERE datname = 'template1';
DROP DATABASE template1;
--
-- Name: template1; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE template1 OWNER TO postgres;

\connect template1

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

--
-- Name: DATABASE template1; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: template1; Type: DATABASE PROPERTIES; Schema: -; Owner: postgres
--

ALTER DATABASE template1 IS_TEMPLATE = true;


\connect template1

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

--
-- Name: DATABASE template1; Type: ACL; Schema: -; Owner: postgres
--

REVOKE CONNECT,TEMPORARY ON DATABASE template1 FROM PUBLIC;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- Database "directus" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 15.2 (Debian 15.2-1.pgdg110+1)
-- Dumped by pg_dump version 15.2 (Debian 15.2-1.pgdg110+1)

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

--
-- Name: directus; Type: DATABASE; Schema: -; Owner: ddb_user
--

CREATE DATABASE directus WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE directus OWNER TO ddb_user;

\connect directus

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

--
-- Name: global_match(text, regproc, text[], text[], text); Type: FUNCTION; Schema: public; Owner: ddb_user
--

CREATE FUNCTION public.global_match(search_term text, comparator regproc DEFAULT 'texteq'::regproc, tables text[] DEFAULT '{}'::text[], schemas text[] DEFAULT '{public}'::text[], progress text DEFAULT NULL::text) RETURNS TABLE(schemaname text, tablename text, columnname text, columnvalue text, rowctid tid)
    LANGUAGE plpgsql
    AS $$

DECLARE

  query text;

  func_schema_name name;

  func_name name;

BEGIN

  SELECT nspname, proname FROM pg_proc p JOIN pg_namespace n ON (n.oid=p.pronamespace)

    WHERE p.oid = comparator

  INTO func_schema_name, func_name;



  FOR schemaname,tablename IN

      SELECT t.table_schema, t.table_name

        FROM information_schema.tables t

	JOIN information_schema.schemata s ON

	  (s.schema_name=t.table_schema)

      WHERE (t.table_name=ANY(tables) OR tables='{}')

        AND t.table_schema=ANY(schemas)

        AND t.table_type='BASE TABLE'

	AND EXISTS (SELECT 1 FROM information_schema.table_privileges p

	  WHERE p.table_name=t.table_name

	    AND p.table_schema=t.table_schema

	    AND p.privilege_type='SELECT'

	)

  LOOP



    IF (progress in ('tables','all')) THEN

      raise info '%', format('Searching globally in table: %I.%I',

         schemaname, tablename);

    END IF;



    FOR columnname IN

	SELECT column_name

	FROM information_schema.columns

	WHERE table_name=tablename

	  AND table_schema=schemaname

    LOOP

      query := format('SELECT ctid,cast(%I as text) FROM ONLY %I.%I WHERE %I.%I(cast(%I as text), %L)',

	columnname,

	schemaname, tablename,

	func_schema_name, func_name,

	columnname, search_term);



    FOR rowctid,columnvalue IN EXECUTE query

      LOOP

	IF (progress in ('hits', 'all')) THEN

	  raise info '%', format('Found in %I.%I.%I at ctid %s',

		 schemaname, tablename, columnname, rowctid);

	END IF;

	RETURN NEXT;

      END LOOP; -- for rowctid

    END LOOP; -- for columnname

  END LOOP; -- for table

END;

$$;


ALTER FUNCTION public.global_match(search_term text, comparator regproc, tables text[], schemas text[], progress text) OWNER TO ddb_user;

--
-- Name: search_columns(text, name[], name[]); Type: FUNCTION; Schema: public; Owner: ddb_user
--

CREATE FUNCTION public.search_columns(needle text, haystack_tables name[] DEFAULT '{}'::name[], haystack_schema name[] DEFAULT '{}'::name[]) RETURNS TABLE(schemaname text, tablename text, columnname text, rowctid text)
    LANGUAGE plpgsql
    AS $$

begin

  FOR schemaname,tablename,columnname IN

      SELECT c.table_schema,c.table_name,c.column_name

      FROM information_schema.columns c

        JOIN information_schema.tables t ON

          (t.table_name=c.table_name AND t.table_schema=c.table_schema)

        JOIN information_schema.table_privileges p ON

          (t.table_name=p.table_name AND t.table_schema=p.table_schema

              AND p.privilege_type='SELECT')

        JOIN information_schema.schemata s ON

          (s.schema_name=t.table_schema)

      WHERE (c.table_name=ANY(haystack_tables) OR haystack_tables='{}')

        AND (c.table_schema=ANY(haystack_schema) OR haystack_schema='{}')

        AND t.table_type='BASE TABLE'

  LOOP

    FOR rowctid IN

      EXECUTE format('SELECT ctid FROM %I.%I WHERE cast(%I as text)=%L',

       schemaname,

       tablename,

       columnname,

       needle

      )

    LOOP

      -- uncomment next line to get some progress report

      -- RAISE NOTICE 'hit in %.%', schemaname, tablename;

      RETURN NEXT;

    END LOOP;

 END LOOP;

END;

$$;


ALTER FUNCTION public.search_columns(needle text, haystack_tables name[], haystack_schema name[]) OWNER TO ddb_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ddb_comment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ddb_comment (
    id uuid NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    sort integer,
    user_created uuid,
    date_created timestamp with time zone,
    user_updated uuid,
    date_updated timestamp with time zone,
    author_id uuid NOT NULL,
    feedback_id uuid,
    content text
);


ALTER TABLE public.ddb_comment OWNER TO postgres;

--
-- Name: ddb_company; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ddb_company (
    id uuid NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying,
    sort integer,
    user_created uuid,
    date_created timestamp with time zone,
    user_updated uuid,
    date_updated timestamp with time zone,
    name character varying(255) DEFAULT NULL::character varying NOT NULL,
    slug character varying(255) DEFAULT NULL::character varying NOT NULL
);


ALTER TABLE public.ddb_company OWNER TO postgres;

--
-- Name: ddb_feedback; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ddb_feedback (
    id uuid NOT NULL,
    status character varying(255) DEFAULT 'public'::character varying,
    sort integer,
    user_created uuid,
    date_created timestamp with time zone,
    user_updated uuid,
    date_updated timestamp with time zone,
    title text NOT NULL,
    body2 text,
    body3 text,
    company_id uuid,
    author_id uuid,
    content text
);


ALTER TABLE public.ddb_feedback OWNER TO postgres;

--
-- Name: ddb_vote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ddb_vote (
    id bigint NOT NULL,
    user_created uuid,
    date_created timestamp with time zone,
    user_updated uuid,
    date_updated timestamp with time zone,
    voted_for uuid,
    voted_by uuid
);


ALTER TABLE public.ddb_vote OWNER TO postgres;

--
-- Name: ddb_vote_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ddb_vote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ddb_vote_id_seq OWNER TO postgres;

--
-- Name: ddb_vote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ddb_vote_id_seq OWNED BY public.ddb_vote.id;


--
-- Name: directus_activity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_activity (
    id integer NOT NULL,
    action character varying(45) NOT NULL,
    "user" uuid,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip character varying(50),
    user_agent character varying(255),
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    comment text,
    origin character varying(255)
);


ALTER TABLE public.directus_activity OWNER TO postgres;

--
-- Name: directus_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_activity_id_seq OWNER TO postgres;

--
-- Name: directus_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_activity_id_seq OWNED BY public.directus_activity.id;


--
-- Name: directus_collections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_collections (
    collection character varying(64) NOT NULL,
    icon character varying(30),
    note text,
    display_template character varying(255),
    hidden boolean DEFAULT false NOT NULL,
    singleton boolean DEFAULT false NOT NULL,
    translations json,
    archive_field character varying(64),
    archive_app_filter boolean DEFAULT true NOT NULL,
    archive_value character varying(255),
    unarchive_value character varying(255),
    sort_field character varying(64),
    accountability character varying(255) DEFAULT 'all'::character varying,
    color character varying(255),
    item_duplication_fields json,
    sort integer,
    "group" character varying(64),
    collapse character varying(255) DEFAULT 'open'::character varying NOT NULL
);


ALTER TABLE public.directus_collections OWNER TO postgres;

--
-- Name: directus_dashboards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_dashboards (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    icon character varying(30) DEFAULT 'dashboard'::character varying NOT NULL,
    note text,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid,
    color character varying(255)
);


ALTER TABLE public.directus_dashboards OWNER TO postgres;

--
-- Name: directus_fields; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_fields (
    id integer NOT NULL,
    collection character varying(64) NOT NULL,
    field character varying(64) NOT NULL,
    special character varying(64),
    interface character varying(64),
    options json,
    display character varying(64),
    display_options json,
    readonly boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    sort integer,
    width character varying(30) DEFAULT 'full'::character varying,
    translations json,
    note text,
    conditions json,
    required boolean DEFAULT false,
    "group" character varying(64),
    validation json,
    validation_message text
);


ALTER TABLE public.directus_fields OWNER TO postgres;

--
-- Name: directus_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_fields_id_seq OWNER TO postgres;

--
-- Name: directus_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_fields_id_seq OWNED BY public.directus_fields.id;


--
-- Name: directus_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_files (
    id uuid NOT NULL,
    storage character varying(255) NOT NULL,
    filename_disk character varying(255),
    filename_download character varying(255) NOT NULL,
    title character varying(255),
    type character varying(255),
    folder uuid,
    uploaded_by uuid,
    uploaded_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by uuid,
    modified_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    charset character varying(50),
    filesize bigint,
    width integer,
    height integer,
    duration integer,
    embed character varying(200),
    description text,
    location text,
    tags text,
    metadata json
);


ALTER TABLE public.directus_files OWNER TO postgres;

--
-- Name: directus_flows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_flows (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    icon character varying(30),
    color character varying(255),
    description text,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    trigger character varying(255),
    accountability character varying(255) DEFAULT 'all'::character varying,
    options json,
    operation uuid,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid
);


ALTER TABLE public.directus_flows OWNER TO postgres;

--
-- Name: directus_folders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_folders (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    parent uuid
);


ALTER TABLE public.directus_folders OWNER TO postgres;

--
-- Name: directus_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_migrations (
    version character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.directus_migrations OWNER TO postgres;

--
-- Name: directus_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_notifications (
    id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(255) DEFAULT 'inbox'::character varying,
    recipient uuid NOT NULL,
    sender uuid,
    subject character varying(255) NOT NULL,
    message text,
    collection character varying(64),
    item character varying(255)
);


ALTER TABLE public.directus_notifications OWNER TO postgres;

--
-- Name: directus_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_notifications_id_seq OWNER TO postgres;

--
-- Name: directus_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_notifications_id_seq OWNED BY public.directus_notifications.id;


--
-- Name: directus_operations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_operations (
    id uuid NOT NULL,
    name character varying(255),
    key character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    position_x integer NOT NULL,
    position_y integer NOT NULL,
    options json,
    resolve uuid,
    reject uuid,
    flow uuid NOT NULL,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid
);


ALTER TABLE public.directus_operations OWNER TO postgres;

--
-- Name: directus_panels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_panels (
    id uuid NOT NULL,
    dashboard uuid NOT NULL,
    name character varying(255),
    icon character varying(30) DEFAULT NULL::character varying,
    color character varying(10),
    show_header boolean DEFAULT false NOT NULL,
    note text,
    type character varying(255) NOT NULL,
    position_x integer NOT NULL,
    position_y integer NOT NULL,
    width integer NOT NULL,
    height integer NOT NULL,
    options json,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_created uuid
);


ALTER TABLE public.directus_panels OWNER TO postgres;

--
-- Name: directus_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_permissions (
    id integer NOT NULL,
    role uuid,
    collection character varying(64) NOT NULL,
    action character varying(10) NOT NULL,
    permissions json,
    validation json,
    presets json,
    fields text
);


ALTER TABLE public.directus_permissions OWNER TO postgres;

--
-- Name: directus_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_permissions_id_seq OWNER TO postgres;

--
-- Name: directus_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_permissions_id_seq OWNED BY public.directus_permissions.id;


--
-- Name: directus_presets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_presets (
    id integer NOT NULL,
    bookmark character varying(255),
    "user" uuid,
    role uuid,
    collection character varying(64),
    search character varying(100),
    layout character varying(100) DEFAULT 'tabular'::character varying,
    layout_query json,
    layout_options json,
    refresh_interval integer,
    filter json,
    icon character varying(30) DEFAULT 'bookmark_outline'::character varying NOT NULL,
    color character varying(255)
);


ALTER TABLE public.directus_presets OWNER TO postgres;

--
-- Name: directus_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_presets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_presets_id_seq OWNER TO postgres;

--
-- Name: directus_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_presets_id_seq OWNED BY public.directus_presets.id;


--
-- Name: directus_relations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_relations (
    id integer NOT NULL,
    many_collection character varying(64) NOT NULL,
    many_field character varying(64) NOT NULL,
    one_collection character varying(64),
    one_field character varying(64),
    one_collection_field character varying(64),
    one_allowed_collections text,
    junction_field character varying(64),
    sort_field character varying(64),
    one_deselect_action character varying(255) DEFAULT 'nullify'::character varying NOT NULL
);


ALTER TABLE public.directus_relations OWNER TO postgres;

--
-- Name: directus_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_relations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_relations_id_seq OWNER TO postgres;

--
-- Name: directus_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_relations_id_seq OWNED BY public.directus_relations.id;


--
-- Name: directus_revisions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_revisions (
    id integer NOT NULL,
    activity integer NOT NULL,
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    data json,
    delta json,
    parent integer
);


ALTER TABLE public.directus_revisions OWNER TO postgres;

--
-- Name: directus_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_revisions_id_seq OWNER TO postgres;

--
-- Name: directus_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_revisions_id_seq OWNED BY public.directus_revisions.id;


--
-- Name: directus_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_roles (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    icon character varying(30) DEFAULT 'supervised_user_circle'::character varying NOT NULL,
    description text,
    ip_access text,
    enforce_tfa boolean DEFAULT false NOT NULL,
    admin_access boolean DEFAULT false NOT NULL,
    app_access boolean DEFAULT true NOT NULL
);


ALTER TABLE public.directus_roles OWNER TO postgres;

--
-- Name: directus_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_sessions (
    token character varying(64) NOT NULL,
    "user" uuid,
    expires timestamp with time zone NOT NULL,
    ip character varying(255),
    user_agent character varying(255),
    share uuid,
    origin character varying(255)
);


ALTER TABLE public.directus_sessions OWNER TO postgres;

--
-- Name: directus_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_settings (
    id integer NOT NULL,
    project_name character varying(100) DEFAULT 'Directus'::character varying NOT NULL,
    project_url character varying(255),
    project_color character varying(50) DEFAULT NULL::character varying,
    project_logo uuid,
    public_foreground uuid,
    public_background uuid,
    public_note text,
    auth_login_attempts integer DEFAULT 25,
    auth_password_policy character varying(100),
    storage_asset_transform character varying(7) DEFAULT 'all'::character varying,
    storage_asset_presets json,
    custom_css text,
    storage_default_folder uuid,
    basemaps json,
    mapbox_key character varying(255),
    module_bar json,
    project_descriptor character varying(100),
    translation_strings json,
    default_language character varying(255) DEFAULT 'en-US'::character varying NOT NULL,
    custom_aspect_ratios json
);


ALTER TABLE public.directus_settings OWNER TO postgres;

--
-- Name: directus_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_settings_id_seq OWNER TO postgres;

--
-- Name: directus_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_settings_id_seq OWNED BY public.directus_settings.id;


--
-- Name: directus_shares; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_shares (
    id uuid NOT NULL,
    name character varying(255),
    collection character varying(64),
    item character varying(255),
    role uuid,
    password character varying(255),
    user_created uuid,
    date_created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    date_start timestamp with time zone,
    date_end timestamp with time zone,
    times_used integer DEFAULT 0,
    max_uses integer
);


ALTER TABLE public.directus_shares OWNER TO postgres;

--
-- Name: directus_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_users (
    id uuid NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    email character varying(128),
    password character varying(255),
    location character varying(255),
    title character varying(50),
    description text,
    tags json,
    avatar uuid,
    language character varying(255) DEFAULT NULL::character varying,
    theme character varying(20) DEFAULT 'auto'::character varying,
    tfa_secret character varying(255),
    status character varying(16) DEFAULT 'active'::character varying NOT NULL,
    role uuid,
    token character varying(255),
    last_access timestamp with time zone,
    last_page character varying(255),
    provider character varying(128) DEFAULT 'default'::character varying NOT NULL,
    external_identifier character varying(255),
    auth_data json,
    email_notifications boolean DEFAULT true
);


ALTER TABLE public.directus_users OWNER TO postgres;

--
-- Name: directus_webhooks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.directus_webhooks (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    method character varying(10) DEFAULT 'POST'::character varying NOT NULL,
    url character varying(255) NOT NULL,
    status character varying(10) DEFAULT 'active'::character varying NOT NULL,
    data boolean DEFAULT true NOT NULL,
    actions character varying(100) NOT NULL,
    collections character varying(255) NOT NULL,
    headers json
);


ALTER TABLE public.directus_webhooks OWNER TO postgres;

--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.directus_webhooks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.directus_webhooks_id_seq OWNER TO postgres;

--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.directus_webhooks_id_seq OWNED BY public.directus_webhooks.id;


--
-- Name: ddb_vote id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_vote ALTER COLUMN id SET DEFAULT nextval('public.ddb_vote_id_seq'::regclass);


--
-- Name: directus_activity id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_activity ALTER COLUMN id SET DEFAULT nextval('public.directus_activity_id_seq'::regclass);


--
-- Name: directus_fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_fields ALTER COLUMN id SET DEFAULT nextval('public.directus_fields_id_seq'::regclass);


--
-- Name: directus_notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications ALTER COLUMN id SET DEFAULT nextval('public.directus_notifications_id_seq'::regclass);


--
-- Name: directus_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_permissions ALTER COLUMN id SET DEFAULT nextval('public.directus_permissions_id_seq'::regclass);


--
-- Name: directus_presets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets ALTER COLUMN id SET DEFAULT nextval('public.directus_presets_id_seq'::regclass);


--
-- Name: directus_relations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_relations ALTER COLUMN id SET DEFAULT nextval('public.directus_relations_id_seq'::regclass);


--
-- Name: directus_revisions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions ALTER COLUMN id SET DEFAULT nextval('public.directus_revisions_id_seq'::regclass);


--
-- Name: directus_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings ALTER COLUMN id SET DEFAULT nextval('public.directus_settings_id_seq'::regclass);


--
-- Name: directus_webhooks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_webhooks ALTER COLUMN id SET DEFAULT nextval('public.directus_webhooks_id_seq'::regclass);


--
-- Data for Name: ddb_comment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ddb_comment (id, status, sort, user_created, date_created, user_updated, date_updated, author_id, feedback_id, content) FROM stdin;
e5279992-8fb4-463d-add6-e5822c64452b	active	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:08:43.025+00	\N	\N	15b505d3-5248-4766-b271-fcdf176a5ef5	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	<p>Great idea!</p>
3dd9f793-0980-4847-9747-7d4a45c2a207	active	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 06:29:17.228+00	\N	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2b423a4f-f127-4b85-8225-90ed99d2c33f	yes please, i can go anytime
b751b9d6-86d9-45e6-a1b1-80bf3d5c2afa	active	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 09:42:07.24+00	\N	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2b423a4f-f127-4b85-8225-90ed99d2c33f	i'd love that!
17d9c74d-61e5-4553-8dd4-aed87611c0aa	active	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 09:46:12.062+00	\N	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2b423a4f-f127-4b85-8225-90ed99d2c33f	Thumbs up!
1cfd0c59-5bc8-4793-b434-4c52b199357b	active	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 19:23:18.682+00	\N	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2604d2c1-4929-4d69-84d9-cd13972e4321	more shopping yay!
5a941db1-d769-4053-b169-1d3b9752be43	active	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 19:33:35.198+00	\N	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2604d2c1-4929-4d69-84d9-cd13972e4321	i like it!
\.


--
-- Data for Name: ddb_company; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ddb_company (id, status, sort, user_created, date_created, user_updated, date_updated, name, slug) FROM stdin;
1bb4b697-845f-4d31-a352-2945cba97978	active	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 22:54:45.769+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:50.084+00	Tesco	tesco
fe46d89a-d7d8-4276-9542-aed168d130ec	active	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 22:57:02.75+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:55.844+00	ASDA	asda
a821325f-9b2a-4539-928d-451d8dfca2e3	active	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:52:56.713+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:02:07.562+00	Sainsbury's	sainsburys
ae6c2f43-d315-4223-a869-07720a5288e0	active	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:12:28.073+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:02:12.762+00	Ocado	ocado
\.


--
-- Data for Name: ddb_feedback; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ddb_feedback (id, status, sort, user_created, date_created, user_updated, date_updated, title, body2, body3, company_id, author_id, content) FROM stdin;
c9888177-d211-46b1-ab0f-dd85b5ae34aa	public	\N	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 23:48:56.226+00	\N	\N	Birthday discounts	\N	\N	1bb4b697-845f-4d31-a352-2945cba97978	cab90e35-563a-4aea-a129-bb7d3d149f9f	for all under 18s
6bec83d0-adb0-4294-990f-4fea685d2488	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 02:39:24.188+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-05 15:28:28.021+00	More doughnuts!	def need more doughnuts!\n<script>alert('fortunately, this will not work!')</script>	def need more doughnuts!	1bb4b697-845f-4d31-a352-2945cba97978	aad86e98-7c2e-4157-a7bc-3828ef1a705a	<p>defo need more doughnuts!</p>\n<p>and gingerbread biscuits!</p>\n<p>and cookies!</p>
6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:59:44.472+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 02:57:31.919+00	More pet snacks	We **LOVE** pets!!!	We LOVE pets!!!	1bb4b697-845f-4d31-a352-2945cba97978	15b505d3-5248-4766-b271-fcdf176a5ef5	<p>We <strong>LOVE </strong>pets!!!</p>
55e79a9c-9f06-439d-9a70-af0876bdbd39	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:09:32.685+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:01:28.91+00	More ready meals	Cannot live without ready meals!!	Cannot live without ready meals!!	fe46d89a-d7d8-4276-9542-aed168d130ec	15b505d3-5248-4766-b271-fcdf176a5ef5	<p>Cannot live without ready meals!!</p>
2a099a4b-f5ba-4fd5-addf-debe4972b6c3	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:14:48.217+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:01:34.881+00	Free membership for students	Yes please	Yes please	ae6c2f43-d315-4223-a869-07720a5288e0	6aefe5e6-a952-429a-aad9-690ceb487bee	<p>Yes please</p>
2604d2c1-4929-4d69-84d9-cd13972e4321	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:20:13.798+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:04:20.963+00	Bigger shopping trolley in shops	Existing ones are too small!	Existing ones are too small!	1bb4b697-845f-4d31-a352-2945cba97978	aad86e98-7c2e-4157-a7bc-3828ef1a705a	<p>Existing ones are too small!</p>
2b423a4f-f127-4b85-8225-90ed99d2c33f	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:07:37.77+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:04:37.806+00	Longer opening hours	Please open 24 hours everyday!	Please open 24 hours everyday!	1bb4b697-845f-4d31-a352-2945cba97978	15b505d3-5248-4766-b271-fcdf176a5ef5	<p>Please open 24 hours everyday!</p>
9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:11:07.267+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:05:42.838+00	more ice-cream during winter	we need ice-cream all the time	we need ice-cream all the time	fe46d89a-d7d8-4276-9542-aed168d130ec	6aefe5e6-a952-429a-aad9-690ceb487bee	<p>we need ice-cream all the time</p>
5899bcf3-b9e9-4c49-8410-ad9cea183a8c	public	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 02:46:46.516+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 00:45:42.55+00	Please offer free car washing service while shopping	... for everyone driving a white car/van!	... for everyone driving a white car/van!	1bb4b697-845f-4d31-a352-2945cba97978	cab90e35-563a-4aea-a129-bb7d3d149f9f	<p>... for everyone driving a white car/van!</p>
\.


--
-- Data for Name: ddb_vote; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ddb_vote (id, user_created, date_created, user_updated, date_updated, voted_for, voted_by) FROM stdin;
3	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 02:28:12.588+00	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 02:29:21.106+00	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	aad86e98-7c2e-4157-a7bc-3828ef1a705a
21	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:48.342+00	\N	\N	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	cab90e35-563a-4aea-a129-bb7d3d149f9f
32	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:46:04.306+00	\N	\N	2604d2c1-4929-4d69-84d9-cd13972e4321	cab90e35-563a-4aea-a129-bb7d3d149f9f
45	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:19:14.009+00	\N	\N	2b423a4f-f127-4b85-8225-90ed99d2c33f	cab90e35-563a-4aea-a129-bb7d3d149f9f
47	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:59:24.8+00	\N	\N	6bec83d0-adb0-4294-990f-4fea685d2488	cab90e35-563a-4aea-a129-bb7d3d149f9f
48	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-01 23:11:15.925+00	\N	\N	6bec83d0-adb0-4294-990f-4fea685d2488	15b505d3-5248-4766-b271-fcdf176a5ef5
49	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-01 23:15:20.489+00	\N	\N	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	15b505d3-5248-4766-b271-fcdf176a5ef5
50	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 04:09:52.224+00	\N	\N	6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	cab90e35-563a-4aea-a129-bb7d3d149f9f
51	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 04:31:41.183+00	\N	\N	2a099a4b-f5ba-4fd5-addf-debe4972b6c3	cab90e35-563a-4aea-a129-bb7d3d149f9f
52	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-05 02:40:51.862+00	\N	\N	55e79a9c-9f06-439d-9a70-af0876bdbd39	cab90e35-563a-4aea-a129-bb7d3d149f9f
\.


--
-- Data for Name: directus_activity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_activity (id, action, "user", "timestamp", ip, user_agent, collection, item, comment, origin) FROM stdin;
1	login	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-19 21:58:04.993+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	http://uk1.descafe.com:8055
2	login	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-19 22:11:14.938+00	172.22.0.1	axios/0.24.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	\N
3	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 00:10:57.435+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	98336213-8d8b-4c4d-b7e3-9834003ebe1c	\N	http://uk1.descafe.com:8055
4	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 00:12:32.036+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	98336213-8d8b-4c4d-b7e3-9834003ebe1c	\N	http://uk1.descafe.com:8055
5	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 00:12:46.231+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	b53e2997-c47d-4507-88b6-b742652db504	\N	http://uk1.descafe.com:8055
6	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:24:17.444+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	b53e2997-c47d-4507-88b6-b742652db504	\N	http://uk1.descafe.com:8055
7	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:50:02.91+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_settings	1	\N	http://uk1.descafe.com:8055
8	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:47.569+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	1	\N	http://uk1.descafe.com:8055
9	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:47.974+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	2	\N	http://uk1.descafe.com:8055
10	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:48.368+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	3	\N	http://uk1.descafe.com:8055
11	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:48.714+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	4	\N	http://uk1.descafe.com:8055
12	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:48.776+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	5	\N	http://uk1.descafe.com:8055
13	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:48.8+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	6	\N	http://uk1.descafe.com:8055
14	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:48.866+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	7	\N	http://uk1.descafe.com:8055
15	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:52:48.928+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_collections	suggestion	\N	http://uk1.descafe.com:8055
16	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:03.601+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	8	\N	http://uk1.descafe.com:8055
17	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:53.354+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	1	\N	http://uk1.descafe.com:8055
18	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:53.431+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	8	\N	http://uk1.descafe.com:8055
19	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:53.549+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	2	\N	http://uk1.descafe.com:8055
20	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:53.649+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	3	\N	http://uk1.descafe.com:8055
21	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:53.818+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	4	\N	http://uk1.descafe.com:8055
22	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:54.026+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	5	\N	http://uk1.descafe.com:8055
23	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:54.075+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	6	\N	http://uk1.descafe.com:8055
24	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:54:54.138+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	7	\N	http://uk1.descafe.com:8055
25	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:08.195+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	9	\N	http://uk1.descafe.com:8055
26	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:10.902+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	1	\N	http://uk1.descafe.com:8055
27	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:10.98+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	9	\N	http://uk1.descafe.com:8055
28	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:11.03+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	8	\N	http://uk1.descafe.com:8055
29	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:11.091+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	2	\N	http://uk1.descafe.com:8055
30	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:11.174+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	3	\N	http://uk1.descafe.com:8055
31	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:11.228+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	4	\N	http://uk1.descafe.com:8055
32	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:11.347+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	5	\N	http://uk1.descafe.com:8055
33	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:11.519+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	6	\N	http://uk1.descafe.com:8055
34	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:55:11.594+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	7	\N	http://uk1.descafe.com:8055
1088	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:37:02.16+00	172.22.0.1	axios/0.27.2	ddb_vote	23	\N	\N
1090	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:07.816+00	172.22.0.1	axios/0.27.2	ddb_vote	24	\N	\N
1092	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:34.521+00	172.22.0.1	axios/0.27.2	ddb_vote	25	\N	\N
1095	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:42.996+00	172.22.0.1	axios/0.27.2	ddb_vote	26	\N	\N
37	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:58:13.456+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	9	\N	http://uk1.descafe.com:8055
38	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 01:58:32.633+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	8	\N	http://uk1.descafe.com:8055
40	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:00:47.543+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	10	\N	http://uk1.descafe.com:8055
41	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:00:58.86+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	1	\N	http://uk1.descafe.com:8055
42	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:00:59.082+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	9	\N	http://uk1.descafe.com:8055
43	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:00:59.297+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	8	\N	http://uk1.descafe.com:8055
44	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:00:59.407+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	2	\N	http://uk1.descafe.com:8055
45	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:00:59.512+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	10	\N	http://uk1.descafe.com:8055
46	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:00:59.705+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	3	\N	http://uk1.descafe.com:8055
47	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:01:00.022+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	4	\N	http://uk1.descafe.com:8055
48	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:01:00.37+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	5	\N	http://uk1.descafe.com:8055
49	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:01:00.471+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	6	\N	http://uk1.descafe.com:8055
50	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 02:01:00.627+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_fields	7	\N	http://uk1.descafe.com:8055
51	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:37.932+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_roles	a2a22e06-e905-4a8e-a3a2-4abf257469e9	\N	http://uk1.descafe.com:8055
52	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.294+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	1	\N	http://uk1.descafe.com:8055
53	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.351+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	2	\N	http://uk1.descafe.com:8055
54	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.367+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	3	\N	http://uk1.descafe.com:8055
55	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.377+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	4	\N	http://uk1.descafe.com:8055
56	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.391+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	5	\N	http://uk1.descafe.com:8055
57	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.406+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	6	\N	http://uk1.descafe.com:8055
58	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.417+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	7	\N	http://uk1.descafe.com:8055
59	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.43+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	8	\N	http://uk1.descafe.com:8055
60	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.44+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	9	\N	http://uk1.descafe.com:8055
61	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.454+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	10	\N	http://uk1.descafe.com:8055
62	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.478+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	11	\N	http://uk1.descafe.com:8055
63	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.5+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	12	\N	http://uk1.descafe.com:8055
64	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.514+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	13	\N	http://uk1.descafe.com:8055
65	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.527+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	14	\N	http://uk1.descafe.com:8055
66	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.564+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	15	\N	http://uk1.descafe.com:8055
67	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.583+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	16	\N	http://uk1.descafe.com:8055
68	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.598+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	17	\N	http://uk1.descafe.com:8055
69	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.61+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	18	\N	http://uk1.descafe.com:8055
70	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.623+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	19	\N	http://uk1.descafe.com:8055
71	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.631+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	20	\N	http://uk1.descafe.com:8055
72	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.647+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	21	\N	http://uk1.descafe.com:8055
73	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.666+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	22	\N	http://uk1.descafe.com:8055
74	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.684+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	23	\N	http://uk1.descafe.com:8055
75	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:38.698+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	24	\N	http://uk1.descafe.com:8055
76	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:07:58.764+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	25	\N	http://uk1.descafe.com:8055
77	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:08:10.254+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	26	\N	http://uk1.descafe.com:8055
78	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:08:19.27+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	25	\N	http://uk1.descafe.com:8055
79	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:08:43.472+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	b53e2997-c47d-4507-88b6-b742652db504	\N	http://uk1.descafe.com:8055
80	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:08:43.501+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_roles	a2a22e06-e905-4a8e-a3a2-4abf257469e9	\N	http://uk1.descafe.com:8055
81	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:11:02.755+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	b53e2997-c47d-4507-88b6-b742652db504	\N	http://uk1.descafe.com:8055
82	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:44:53.409+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	27	\N	http://uk1.descafe.com:8055
83	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:08.488+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	28	\N	http://uk1.descafe.com:8055
84	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:09.926+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	29	\N	http://uk1.descafe.com:8055
85	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:11.303+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	27	\N	http://uk1.descafe.com:8055
86	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:14.884+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	30	\N	http://uk1.descafe.com:8055
87	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:16.409+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	31	\N	http://uk1.descafe.com:8055
88	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:30.196+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	31	\N	http://uk1.descafe.com:8055
89	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:31.57+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	28	\N	http://uk1.descafe.com:8055
90	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:33.012+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	29	\N	http://uk1.descafe.com:8055
91	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:46:34.45+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	30	\N	http://uk1.descafe.com:8055
92	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:51:38.42+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	32	\N	http://uk1.descafe.com:8055
93	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:52:02.222+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	32	\N	http://uk1.descafe.com:8055
94	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:54:59.161+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	33	\N	http://uk1.descafe.com:8055
95	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 03:55:19.979+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	33	\N	http://uk1.descafe.com:8055
96	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:02:55.378+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	34	\N	http://uk1.descafe.com:8055
97	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:03:04.681+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	35	\N	http://uk1.descafe.com:8055
98	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:03:06.3+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	36	\N	http://uk1.descafe.com:8055
99	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:03:14.243+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	34	\N	http://uk1.descafe.com:8055
100	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:03:16.233+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	35	\N	http://uk1.descafe.com:8055
101	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:03:17.719+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	36	\N	http://uk1.descafe.com:8055
102	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:10:03.503+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	26	\N	http://uk1.descafe.com:8055
103	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:10:09.605+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	37	\N	http://uk1.descafe.com:8055
104	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:23:49.783+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	37	\N	http://uk1.descafe.com:8055
105	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 04:29:32.982+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	38	\N	http://uk1.descafe.com:8055
106	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:41:47.657+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	39	\N	http://uk1.descafe.com:8055
107	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:42:15.669+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	39	\N	http://uk1.descafe.com:8055
108	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:42:40.964+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	38	\N	http://uk1.descafe.com:8055
109	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:42:54.8+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	40	\N	http://uk1.descafe.com:8055
110	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:39.854+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	41	\N	http://uk1.descafe.com:8055
111	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:40.052+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	42	\N	http://uk1.descafe.com:8055
112	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:40.054+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	43	\N	http://uk1.descafe.com:8055
113	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:40.092+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	44	\N	http://uk1.descafe.com:8055
114	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:40.157+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	45	\N	http://uk1.descafe.com:8055
115	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:55.148+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	41	\N	http://uk1.descafe.com:8055
116	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:55.154+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	42	\N	http://uk1.descafe.com:8055
117	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:55.158+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	43	\N	http://uk1.descafe.com:8055
118	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:55.161+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	44	\N	http://uk1.descafe.com:8055
119	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:46:55.171+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	45	\N	http://uk1.descafe.com:8055
120	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 17:47:10.208+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	46	\N	http://uk1.descafe.com:8055
121	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-20 23:50:47.124+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	40	\N	http://uk1.descafe.com:8055
122	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 00:02:07.44+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	47	\N	http://uk1.descafe.com:8055
123	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 00:04:17.255+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	46	\N	http://uk1.descafe.com:8055
124	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 00:06:50.097+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	47	\N	http://uk1.descafe.com:8055
125	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 00:06:53.946+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	48	\N	http://uk1.descafe.com:8055
126	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:16:04.317+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	48	\N	http://uk1.descafe.com:8055
127	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:30:34.82+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	49	\N	http://uk1.descafe.com:8055
128	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:39:17.433+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	49	\N	http://uk1.descafe.com:8055
129	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:39:26.822+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	50	\N	http://uk1.descafe.com:8055
130	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:40:25.441+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	50	\N	http://uk1.descafe.com:8055
131	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:42:31.962+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	51	\N	http://uk1.descafe.com:8055
132	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:42:50.85+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	51	\N	http://uk1.descafe.com:8055
134	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-21 01:45:57.74+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	52	\N	http://uk1.descafe.com:8055
1089	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:37:53.455+00	172.22.0.1	axios/0.27.2	ddb_vote	23	\N	\N
1091	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:12.392+00	172.22.0.1	axios/0.27.2	ddb_vote	24	\N	\N
1093	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:37.347+00	172.22.0.1	axios/0.27.2	ddb_vote	25	\N	\N
1094	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:40.648+00	172.22.0.1	axios/0.27.2	ddb_vote	26	\N	\N
1096	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:45.843+00	172.22.0.1	axios/0.27.2	ddb_vote	27	\N	\N
1097	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:47.495+00	172.22.0.1	axios/0.27.2	ddb_vote	27	\N	\N
1098	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:50.161+00	172.22.0.1	axios/0.27.2	ddb_vote	28	\N	\N
1099	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:51.885+00	172.22.0.1	axios/0.27.2	ddb_vote	28	\N	\N
1100	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:53.062+00	172.22.0.1	axios/0.27.2	ddb_vote	29	\N	\N
1101	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:54.457+00	172.22.0.1	axios/0.27.2	ddb_vote	29	\N	\N
1102	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:42:56.84+00	172.22.0.1	axios/0.27.2	ddb_vote	30	\N	\N
1103	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:44:00.84+00	172.22.0.1	axios/0.27.2	ddb_vote	30	\N	\N
1104	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:44:02.423+00	172.22.0.1	axios/0.27.2	ddb_vote	31	\N	\N
1105	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:45:37.705+00	172.22.0.1	axios/0.27.2	ddb_vote	31	\N	\N
1106	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:46:04.362+00	172.22.0.1	axios/0.27.2	ddb_vote	32	\N	\N
1107	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:32:15.055+00	172.22.0.1	axios/0.27.2	ddb_vote	33	\N	\N
1108	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:32:22.774+00	172.22.0.1	axios/0.27.2	ddb_vote	33	\N	\N
1109	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:34:11.271+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1110	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:34:13.741+00	172.22.0.1	axios/0.27.2	ddb_vote	34	\N	\N
1111	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:34:33.999+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
163	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-22 23:50:33.578+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_settings	1	\N	http://uk1.descafe.com:8055
169	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 01:25:17.887+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	b53e2997-c47d-4507-88b6-b742652db504	\N	http://uk1.descafe.com:8055
174	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.756+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_roles	a257a32a-b4d2-4782-a145-0200d277d527	\N	http://uk1.descafe.com:8055
175	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.857+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	53	\N	http://uk1.descafe.com:8055
176	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.893+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	54	\N	http://uk1.descafe.com:8055
177	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.915+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	55	\N	http://uk1.descafe.com:8055
178	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.927+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	56	\N	http://uk1.descafe.com:8055
179	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.938+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	57	\N	http://uk1.descafe.com:8055
180	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.959+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	58	\N	http://uk1.descafe.com:8055
181	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.978+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	59	\N	http://uk1.descafe.com:8055
182	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.987+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	60	\N	http://uk1.descafe.com:8055
183	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:24.997+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	61	\N	http://uk1.descafe.com:8055
184	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.008+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	62	\N	http://uk1.descafe.com:8055
185	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.016+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	63	\N	http://uk1.descafe.com:8055
186	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.027+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	64	\N	http://uk1.descafe.com:8055
187	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.056+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	65	\N	http://uk1.descafe.com:8055
188	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.068+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	66	\N	http://uk1.descafe.com:8055
189	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.078+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	67	\N	http://uk1.descafe.com:8055
190	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.088+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	68	\N	http://uk1.descafe.com:8055
191	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.104+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	69	\N	http://uk1.descafe.com:8055
192	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.126+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	70	\N	http://uk1.descafe.com:8055
193	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.145+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	71	\N	http://uk1.descafe.com:8055
194	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.156+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	72	\N	http://uk1.descafe.com:8055
195	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.165+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	73	\N	http://uk1.descafe.com:8055
196	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.186+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	74	\N	http://uk1.descafe.com:8055
197	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.206+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	75	\N	http://uk1.descafe.com:8055
198	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:25.242+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	76	\N	http://uk1.descafe.com:8055
199	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.339+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	53	\N	http://uk1.descafe.com:8055
200	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.346+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	54	\N	http://uk1.descafe.com:8055
201	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.352+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	55	\N	http://uk1.descafe.com:8055
202	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.355+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	56	\N	http://uk1.descafe.com:8055
203	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.362+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	57	\N	http://uk1.descafe.com:8055
204	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.364+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	58	\N	http://uk1.descafe.com:8055
205	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.372+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	59	\N	http://uk1.descafe.com:8055
206	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.374+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	60	\N	http://uk1.descafe.com:8055
207	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.377+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	61	\N	http://uk1.descafe.com:8055
208	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.38+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	62	\N	http://uk1.descafe.com:8055
209	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.382+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	63	\N	http://uk1.descafe.com:8055
210	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.385+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	64	\N	http://uk1.descafe.com:8055
211	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.388+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	65	\N	http://uk1.descafe.com:8055
212	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.391+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	66	\N	http://uk1.descafe.com:8055
213	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.393+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	67	\N	http://uk1.descafe.com:8055
214	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.395+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	68	\N	http://uk1.descafe.com:8055
215	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.399+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	69	\N	http://uk1.descafe.com:8055
216	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.401+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	70	\N	http://uk1.descafe.com:8055
457	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 04:17:21.987+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
217	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.403+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	71	\N	http://uk1.descafe.com:8055
218	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.406+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	72	\N	http://uk1.descafe.com:8055
219	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.408+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	73	\N	http://uk1.descafe.com:8055
220	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.413+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	74	\N	http://uk1.descafe.com:8055
221	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.416+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	75	\N	http://uk1.descafe.com:8055
222	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:34.419+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	76	\N	http://uk1.descafe.com:8055
223	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:40.318+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	77	\N	http://uk1.descafe.com:8055
224	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:17:52.236+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	77	\N	http://uk1.descafe.com:8055
225	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.468+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	78	\N	http://uk1.descafe.com:8055
226	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.482+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	79	\N	http://uk1.descafe.com:8055
227	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.493+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	80	\N	http://uk1.descafe.com:8055
228	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.504+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	81	\N	http://uk1.descafe.com:8055
229	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.527+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	82	\N	http://uk1.descafe.com:8055
230	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.542+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	83	\N	http://uk1.descafe.com:8055
231	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.555+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	84	\N	http://uk1.descafe.com:8055
232	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.564+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	85	\N	http://uk1.descafe.com:8055
233	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.583+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	86	\N	http://uk1.descafe.com:8055
234	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.611+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	87	\N	http://uk1.descafe.com:8055
235	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.628+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	88	\N	http://uk1.descafe.com:8055
236	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.649+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	89	\N	http://uk1.descafe.com:8055
237	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.66+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	90	\N	http://uk1.descafe.com:8055
238	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.672+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	91	\N	http://uk1.descafe.com:8055
239	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.691+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	92	\N	http://uk1.descafe.com:8055
240	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.716+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	93	\N	http://uk1.descafe.com:8055
241	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.728+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	94	\N	http://uk1.descafe.com:8055
242	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.747+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	95	\N	http://uk1.descafe.com:8055
243	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.756+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	96	\N	http://uk1.descafe.com:8055
244	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.768+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	97	\N	http://uk1.descafe.com:8055
245	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.777+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	98	\N	http://uk1.descafe.com:8055
246	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.789+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	99	\N	http://uk1.descafe.com:8055
247	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.801+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	100	\N	http://uk1.descafe.com:8055
248	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:09.822+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	101	\N	http://uk1.descafe.com:8055
249	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.382+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	78	\N	http://uk1.descafe.com:8055
250	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.396+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	79	\N	http://uk1.descafe.com:8055
251	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.4+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	80	\N	http://uk1.descafe.com:8055
458	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 04:22:33.076+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
252	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.403+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	81	\N	http://uk1.descafe.com:8055
253	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.406+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	82	\N	http://uk1.descafe.com:8055
254	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.408+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	83	\N	http://uk1.descafe.com:8055
255	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.413+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	84	\N	http://uk1.descafe.com:8055
256	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.416+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	85	\N	http://uk1.descafe.com:8055
257	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.419+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	86	\N	http://uk1.descafe.com:8055
258	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.421+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	87	\N	http://uk1.descafe.com:8055
259	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.423+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	88	\N	http://uk1.descafe.com:8055
260	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.434+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	89	\N	http://uk1.descafe.com:8055
261	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.44+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	90	\N	http://uk1.descafe.com:8055
262	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.45+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	91	\N	http://uk1.descafe.com:8055
263	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.453+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	92	\N	http://uk1.descafe.com:8055
264	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.455+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	93	\N	http://uk1.descafe.com:8055
265	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.457+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	94	\N	http://uk1.descafe.com:8055
266	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.466+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	95	\N	http://uk1.descafe.com:8055
267	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.469+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	96	\N	http://uk1.descafe.com:8055
268	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.482+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	97	\N	http://uk1.descafe.com:8055
269	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.486+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	98	\N	http://uk1.descafe.com:8055
270	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.489+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	99	\N	http://uk1.descafe.com:8055
271	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.494+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	100	\N	http://uk1.descafe.com:8055
272	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:15.496+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	101	\N	http://uk1.descafe.com:8055
273	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.554+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	102	\N	http://uk1.descafe.com:8055
274	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.587+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	103	\N	http://uk1.descafe.com:8055
275	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.619+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	104	\N	http://uk1.descafe.com:8055
276	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.63+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	105	\N	http://uk1.descafe.com:8055
277	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.648+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	106	\N	http://uk1.descafe.com:8055
278	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.663+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	107	\N	http://uk1.descafe.com:8055
279	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.685+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	108	\N	http://uk1.descafe.com:8055
280	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.699+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	109	\N	http://uk1.descafe.com:8055
281	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.713+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	110	\N	http://uk1.descafe.com:8055
282	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.728+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	111	\N	http://uk1.descafe.com:8055
283	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.752+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	112	\N	http://uk1.descafe.com:8055
284	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.767+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	113	\N	http://uk1.descafe.com:8055
285	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.806+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	114	\N	http://uk1.descafe.com:8055
286	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.827+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	115	\N	http://uk1.descafe.com:8055
459	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 04:39:03.626+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
287	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.843+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	116	\N	http://uk1.descafe.com:8055
288	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.867+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	117	\N	http://uk1.descafe.com:8055
289	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.889+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	118	\N	http://uk1.descafe.com:8055
290	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:23.959+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	119	\N	http://uk1.descafe.com:8055
291	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:24.037+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	120	\N	http://uk1.descafe.com:8055
292	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:24.091+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	121	\N	http://uk1.descafe.com:8055
293	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:24.121+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	122	\N	http://uk1.descafe.com:8055
294	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:24.166+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	123	\N	http://uk1.descafe.com:8055
295	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:24.228+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	124	\N	http://uk1.descafe.com:8055
296	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:24.253+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	125	\N	http://uk1.descafe.com:8055
297	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.579+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	102	\N	http://uk1.descafe.com:8055
298	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.586+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	103	\N	http://uk1.descafe.com:8055
299	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.588+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	104	\N	http://uk1.descafe.com:8055
300	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.592+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	105	\N	http://uk1.descafe.com:8055
301	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.595+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	106	\N	http://uk1.descafe.com:8055
302	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.597+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	107	\N	http://uk1.descafe.com:8055
303	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.599+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	108	\N	http://uk1.descafe.com:8055
304	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.603+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	109	\N	http://uk1.descafe.com:8055
305	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.606+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	110	\N	http://uk1.descafe.com:8055
306	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.608+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	111	\N	http://uk1.descafe.com:8055
307	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.61+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	112	\N	http://uk1.descafe.com:8055
308	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.612+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	113	\N	http://uk1.descafe.com:8055
309	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.615+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	114	\N	http://uk1.descafe.com:8055
310	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.619+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	115	\N	http://uk1.descafe.com:8055
311	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.628+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	116	\N	http://uk1.descafe.com:8055
312	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.636+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	117	\N	http://uk1.descafe.com:8055
313	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.642+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	118	\N	http://uk1.descafe.com:8055
314	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.655+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	119	\N	http://uk1.descafe.com:8055
315	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.661+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	120	\N	http://uk1.descafe.com:8055
316	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.664+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	121	\N	http://uk1.descafe.com:8055
317	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.689+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	122	\N	http://uk1.descafe.com:8055
318	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.697+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	123	\N	http://uk1.descafe.com:8055
319	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.708+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	124	\N	http://uk1.descafe.com:8055
320	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:30.713+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	125	\N	http://uk1.descafe.com:8055
321	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:18:47.807+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	126	\N	http://uk1.descafe.com:8055
460	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-04 04:53:35.088+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
322	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:19:27.857+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_permissions	126	\N	http://uk1.descafe.com:8055
323	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:32:22.664+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	http://uk1.descafe.com:8055
324	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:32:46.996+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	http://uk1.descafe.com:8055
325	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:33:01.715+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_roles	a257a32a-b4d2-4782-a145-0200d277d527	\N	http://uk1.descafe.com:8055
326	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-25 21:33:26.738+00	146.70.83.76	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	http://uk1.descafe.com:8055
327	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-27 00:23:19.813+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
328	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 00:24:20.92+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
329	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 00:27:48.032+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	127	\N	http://uk1.descafe.com:8055
330	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 00:49:39.735+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
331	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 00:51:47.343+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
332	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-27 02:54:06.478+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
333	login	b53e2997-c47d-4507-88b6-b742652db504	2023-01-27 03:04:00.689+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_users	b53e2997-c47d-4507-88b6-b742652db504	\N	http://uk1.descafe.com:8055
334	login	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 03:17:24.115+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	http://uk1.descafe.com:8055
335	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-27 04:10:55.974+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
336	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.609+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	128	\N	http://uk1.descafe.com:8055
337	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.632+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	129	\N	http://uk1.descafe.com:8055
338	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.647+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	130	\N	http://uk1.descafe.com:8055
339	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.657+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	131	\N	http://uk1.descafe.com:8055
340	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.699+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	132	\N	http://uk1.descafe.com:8055
341	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.716+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	133	\N	http://uk1.descafe.com:8055
342	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.734+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	134	\N	http://uk1.descafe.com:8055
343	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.75+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	135	\N	http://uk1.descafe.com:8055
344	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.77+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	136	\N	http://uk1.descafe.com:8055
345	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.789+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	137	\N	http://uk1.descafe.com:8055
346	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.803+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	138	\N	http://uk1.descafe.com:8055
347	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.812+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	139	\N	http://uk1.descafe.com:8055
348	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.826+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	140	\N	http://uk1.descafe.com:8055
349	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.842+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	141	\N	http://uk1.descafe.com:8055
350	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.855+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	142	\N	http://uk1.descafe.com:8055
351	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.865+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	143	\N	http://uk1.descafe.com:8055
352	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.874+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	144	\N	http://uk1.descafe.com:8055
353	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.885+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	145	\N	http://uk1.descafe.com:8055
354	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.899+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	146	\N	http://uk1.descafe.com:8055
355	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.91+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	147	\N	http://uk1.descafe.com:8055
356	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.929+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	148	\N	http://uk1.descafe.com:8055
357	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.937+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	149	\N	http://uk1.descafe.com:8055
358	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.961+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	150	\N	http://uk1.descafe.com:8055
359	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-27 04:11:49.99+00	78.32.148.89	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	151	\N	http://uk1.descafe.com:8055
360	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-27 04:20:25.348+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
361	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-27 04:21:09.74+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
362	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 04:23:58.901+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
363	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 04:57:20.278+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
364	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-27 05:08:57.885+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
365	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 05:09:58.86+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
366	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 05:10:55.13+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
367	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 05:11:45.116+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
368	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 18:14:25.479+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
369	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-27 19:33:59.389+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
370	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 19:39:31.089+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
371	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 19:44:07.7+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
372	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-27 21:38:34.255+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
373	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 03:42:43.322+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
374	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 03:46:09.121+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
375	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 03:48:21.924+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
376	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 03:54:33.109+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
377	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 03:55:09.343+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
378	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 04:07:25.808+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
379	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 04:11:23.729+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
380	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 04:13:55.733+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
381	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 04:15:26.119+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
382	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 04:16:51.509+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
383	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 04:17:14.779+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
384	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 04:24:57.654+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
385	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 04:35:00.485+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
386	login	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-28 04:46:51.413+00	146.70.83.75	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	http://uk1.descafe.com:8055
387	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 05:10:51.183+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
388	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 05:12:37.62+00	172.24.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
389	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 15:48:45.516+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
390	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 16:08:07.805+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
391	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 19:25:32.909+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
392	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 19:29:03.224+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
393	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 19:36:55.328+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
394	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 19:59:51.674+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
395	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 22:20:48.629+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
396	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 22:23:25.488+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
397	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 22:24:18.452+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
398	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 22:26:02.079+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
399	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 22:26:52.182+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
400	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 22:36:57.42+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
401	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-28 22:37:34.436+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
402	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-28 22:40:23.703+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
403	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-29 00:13:22.686+00	146.70.83.75	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_users	aaa1b7cb-2f23-4e92-828a-a90946b50992	\N	http://uk1.descafe.com:8055
404	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 01:53:10.506+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
405	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-29 02:18:37.066+00	146.70.83.75	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_roles	a257a32a-b4d2-4782-a145-0200d277d527	\N	http://uk1.descafe.com:8055
406	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-29 02:18:37.22+00	146.70.83.75	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	http://uk1.descafe.com:8055
461	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 04:57:09.164+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
407	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-29 02:19:34.183+00	146.70.83.75	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	152	\N	http://uk1.descafe.com:8055
408	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-29 02:20:33.782+00	146.70.83.75	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_permissions	18	\N	http://uk1.descafe.com:8055
409	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 03:14:40.621+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
410	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 03:17:35.717+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
411	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 03:31:36.572+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
412	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 03:41:49.952+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
413	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 03:46:36.214+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
414	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 03:51:55.941+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
415	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 03:56:50.693+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
416	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 04:01:05.64+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
417	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 14:53:48.769+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
418	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 15:33:38.938+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
419	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 15:43:46.172+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
420	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 15:45:08.653+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
421	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 15:45:11.384+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
422	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 16:37:51.289+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
423	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 16:38:40.888+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
424	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 16:53:14.059+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
425	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 16:53:28.363+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
426	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 16:58:03.023+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
427	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 17:58:12.862+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
428	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 18:17:11.578+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
429	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 18:28:54.739+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
430	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 18:30:05.774+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
431	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 18:30:57.778+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
432	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 18:32:14.394+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
433	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 18:33:16.19+00	45.63.100.231	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
434	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 19:28:17.536+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
435	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 19:29:16.229+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
436	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 19:31:20.565+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
437	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 19:31:22.115+00	45.63.100.231	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
438	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 19:31:53.276+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
439	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 19:32:02.473+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
440	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 19:33:31.077+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
441	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-29 19:41:25.821+00	45.63.100.231	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
442	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 19:41:28.584+00	45.63.100.231	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
443	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 21:08:16.11+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
444	create	b53e2997-c47d-4507-88b6-b742652db504	2023-01-29 21:15:55.4+00	172.25.0.1	axios/0.27.2	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	\N	\N
445	login	6a85a60f-5e1e-443a-b698-f7dc396583b9	2023-01-29 21:15:56.569+00	172.25.0.1	axios/0.27.2	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	\N	\N
446	login	6a85a60f-5e1e-443a-b698-f7dc396583b9	2023-01-29 21:19:23.459+00	172.25.0.1	axios/0.27.2	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	\N	\N
447	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-01-29 21:19:54.567+00	146.70.83.75	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	\N	http://uk1.descafe.com:8055
448	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 21:29:33.294+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
449	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-29 21:55:10.075+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
450	create	b53e2997-c47d-4507-88b6-b742652db504	2023-01-29 22:23:13.869+00	172.25.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
451	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-01-29 22:23:14.669+00	172.25.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
452	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-01-29 22:23:30.242+00	172.25.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
453	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-30 17:07:22.199+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
454	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-30 17:25:18.35+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
455	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-01-30 17:26:08.424+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
456	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-01-31 19:40:48.02+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
462	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:14:52.191+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
463	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:18:48.975+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
464	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:21:04.476+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
465	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:22:52.955+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
466	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-04 05:22:57.914+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
467	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:23:03.059+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
468	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:24:08.577+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
469	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:26:15.723+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
470	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 05:26:41.558+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
471	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-04 05:27:17.511+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
472	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-04 06:15:00.788+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
473	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-04 09:46:55.815+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
474	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-04 09:47:03.851+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
475	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 18:00:47.041+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
476	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-04 18:01:14.625+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
477	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-04 18:01:29.629+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
478	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-05 00:20:55.675+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
479	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-05 00:21:08.197+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
480	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-05 00:58:48.951+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
481	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-05 01:21:42.649+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
482	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-05 21:27:37.586+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
483	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-07 05:38:00.35+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
484	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-07 05:41:15.244+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
485	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 01:54:01.333+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
486	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 01:55:03.665+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
487	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 02:05:04.271+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
488	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 02:05:21.989+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
489	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 02:05:58.214+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
490	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 02:08:31.88+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
491	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 02:54:05.668+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
492	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 02:56:46.404+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
493	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 03:01:58.893+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
494	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 03:40:07.346+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
495	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 03:42:18.044+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
496	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 03:56:38.605+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
497	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 20:14:59.535+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
498	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 20:19:39.668+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
499	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 20:40:34.29+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
500	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 20:50:34.191+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
501	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:13:59.11+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
502	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:20:55.179+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
503	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:21:19.256+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
504	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 22:22:41.128+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
505	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:24:09.089+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
506	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:24:34.062+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
507	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:25:10.54+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
508	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:27:17.675+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
509	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 22:27:29.12+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
510	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:31:17.477+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
511	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:34:24.252+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
512	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 22:34:38.32+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
513	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:34:52.047+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
514	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:35:18.473+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
515	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:36:19.588+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
516	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 22:37:09.318+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
517	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:37:43.82+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
518	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:37:53.487+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
519	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 22:45:50.224+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
520	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-09 22:46:06.848+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
521	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 23:29:08.792+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
522	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-09 23:29:24.77+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
523	login	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-10 02:10:08.265+00	146.70.83.71	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	http://uk1.descafe.com:8055
524	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-10 02:40:01.703+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
525	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 02:40:48.767+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
526	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 02:45:42.866+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
527	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 02:49:09.18+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
528	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 03:45:57.447+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
529	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 03:47:40.653+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
530	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-10 04:08:08.75+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
531	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 04:11:49.348+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
532	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-10 04:15:48.604+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
533	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-10 04:23:19.142+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
534	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-10 04:30:03.237+00	172.25.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
535	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 04:33:31.693+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
536	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 05:48:57.423+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
537	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-10 22:12:59.344+00	172.25.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
538	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-15 01:59:32.008+00	172.19.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
539	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-15 04:21:24.891+00	172.19.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
540	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-15 04:41:08.546+00	172.19.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
541	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-15 04:41:27.932+00	172.19.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
542	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-15 04:42:00.471+00	172.19.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
543	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-15 04:46:18.511+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
544	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-15 20:20:24.92+00	172.19.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
545	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-16 01:36:40.559+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
546	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-18 02:46:19.009+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
547	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-18 02:48:09.543+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
548	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-18 22:32:31.699+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
549	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-18 22:38:51.97+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
550	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-18 22:54:49.532+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
551	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-18 22:54:55.927+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
552	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-18 22:54:58.153+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
553	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-18 23:53:10.336+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
554	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 00:24:23.739+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
555	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 00:26:33.911+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
556	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 00:29:52.161+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
557	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 03:19:49.44+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
558	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 04:54:59.557+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
559	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 05:28:47.313+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
560	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 05:34:04.19+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
561	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-19 05:44:44.879+00	172.19.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
562	create	b53e2997-c47d-4507-88b6-b742652db504	2023-02-20 00:32:13.7+00	172.19.0.1	axios/0.27.2	directus_users	d95fe57c-1cbb-490b-a664-4772d34b2024	\N	\N
563	login	d95fe57c-1cbb-490b-a664-4772d34b2024	2023-02-20 00:32:14.239+00	172.19.0.1	axios/0.27.2	directus_users	d95fe57c-1cbb-490b-a664-4772d34b2024	\N	\N
564	login	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 00:34:34.936+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	http://uk1.descafe.com:8055
565	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 00:35:42.164+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	d95fe57c-1cbb-490b-a664-4772d34b2024	\N	http://uk1.descafe.com:8055
566	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 00:35:57.113+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	http://uk1.descafe.com:8055
567	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 00:36:06.026+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	http://uk1.descafe.com:8055
1029	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-25 14:27:49.21+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
568	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 00:36:14.634+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	\N	http://uk1.descafe.com:8055
569	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 00:36:21.164+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	http://uk1.descafe.com:8055
570	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 00:36:41.906+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	http://uk1.descafe.com:8055
571	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-20 01:55:37.295+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
572	create	b53e2997-c47d-4507-88b6-b742652db504	2023-02-20 03:06:27.152+00	172.19.0.1	axios/0.27.2	directus_users	6aefe5e6-a952-429a-aad9-690ceb487bee	\N	\N
573	login	6aefe5e6-a952-429a-aad9-690ceb487bee	2023-02-20 03:06:28.018+00	172.19.0.1	axios/0.27.2	directus_users	6aefe5e6-a952-429a-aad9-690ceb487bee	\N	\N
574	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.401+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	11	\N	http://uk1.descafe.com:8055
575	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.476+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	12	\N	http://uk1.descafe.com:8055
576	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.541+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	13	\N	http://uk1.descafe.com:8055
577	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.586+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	14	\N	http://uk1.descafe.com:8055
578	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.612+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	15	\N	http://uk1.descafe.com:8055
579	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.656+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	16	\N	http://uk1.descafe.com:8055
580	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.686+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	17	\N	http://uk1.descafe.com:8055
581	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:19:56.716+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	Company	\N	http://uk1.descafe.com:8055
582	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:21:22.163+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	18	\N	http://uk1.descafe.com:8055
583	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:21:22.203+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	19	\N	http://uk1.descafe.com:8055
584	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:21:22.232+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	20	\N	http://uk1.descafe.com:8055
585	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:21:22.262+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	21	\N	http://uk1.descafe.com:8055
586	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:21:22.279+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	22	\N	http://uk1.descafe.com:8055
587	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:21:22.311+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	23	\N	http://uk1.descafe.com:8055
588	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 03:21:22.323+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	Idea	\N	http://uk1.descafe.com:8055
589	login	6aefe5e6-a952-429a-aad9-690ceb487bee	2023-02-20 03:56:15.774+00	172.19.0.1	axios/0.27.2	directus_users	6aefe5e6-a952-429a-aad9-690ceb487bee	\N	\N
590	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:13:11.052+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	Company	\N	http://uk1.descafe.com:8055
591	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:13:15.075+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	Idea	\N	http://uk1.descafe.com:8055
592	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:17.673+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	24	\N	http://uk1.descafe.com:8055
593	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:17.848+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	25	\N	http://uk1.descafe.com:8055
594	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:17.909+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	26	\N	http://uk1.descafe.com:8055
595	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:18.002+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	27	\N	http://uk1.descafe.com:8055
596	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:18.069+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	28	\N	http://uk1.descafe.com:8055
597	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:18.098+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	29	\N	http://uk1.descafe.com:8055
598	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:18.121+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	30	\N	http://uk1.descafe.com:8055
599	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:28:18.203+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	dap_idea	\N	http://uk1.descafe.com:8055
600	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.442+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	31	\N	http://uk1.descafe.com:8055
601	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.693+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	32	\N	http://uk1.descafe.com:8055
602	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.713+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	33	\N	http://uk1.descafe.com:8055
603	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.727+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	34	\N	http://uk1.descafe.com:8055
604	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.746+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	35	\N	http://uk1.descafe.com:8055
605	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.759+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	36	\N	http://uk1.descafe.com:8055
606	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.775+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	37	\N	http://uk1.descafe.com:8055
1030	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-25 14:41:07.376+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
607	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:11.828+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	dab_company	\N	http://uk1.descafe.com:8055
608	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:27.079+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	dab_company	\N	http://uk1.descafe.com:8055
609	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.251+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	38	\N	http://uk1.descafe.com:8055
610	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.273+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	39	\N	http://uk1.descafe.com:8055
611	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.284+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	40	\N	http://uk1.descafe.com:8055
612	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.294+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	41	\N	http://uk1.descafe.com:8055
613	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.307+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	42	\N	http://uk1.descafe.com:8055
614	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.332+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	43	\N	http://uk1.descafe.com:8055
615	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.343+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	44	\N	http://uk1.descafe.com:8055
616	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:30:57.354+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	dap_company	\N	http://uk1.descafe.com:8055
617	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:36:51.139+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	dap_idea	\N	http://uk1.descafe.com:8055
618	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:02.509+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	dap_company	\N	http://uk1.descafe.com:8055
619	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:54.961+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	45	\N	http://uk1.descafe.com:8055
620	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:55.026+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	46	\N	http://uk1.descafe.com:8055
621	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:55.053+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	47	\N	http://uk1.descafe.com:8055
622	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:55.084+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	48	\N	http://uk1.descafe.com:8055
623	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:55.12+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	49	\N	http://uk1.descafe.com:8055
624	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:55.164+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	50	\N	http://uk1.descafe.com:8055
625	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:55.223+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	51	\N	http://uk1.descafe.com:8055
626	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:37:55.318+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	ddb_idea	\N	http://uk1.descafe.com:8055
627	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.465+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	52	\N	http://uk1.descafe.com:8055
628	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.505+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
629	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.521+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	54	\N	http://uk1.descafe.com:8055
630	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.538+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	55	\N	http://uk1.descafe.com:8055
631	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.554+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	56	\N	http://uk1.descafe.com:8055
632	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.586+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	57	\N	http://uk1.descafe.com:8055
633	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.617+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	58	\N	http://uk1.descafe.com:8055
634	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:17.64+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	ddb_company	\N	http://uk1.descafe.com:8055
635	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:47.113+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	59	\N	http://uk1.descafe.com:8055
636	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:52.371+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	52	\N	http://uk1.descafe.com:8055
637	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:52.482+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	59	\N	http://uk1.descafe.com:8055
638	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:52.585+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
639	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:52.701+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	54	\N	http://uk1.descafe.com:8055
640	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:52.821+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	55	\N	http://uk1.descafe.com:8055
641	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:52.975+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	56	\N	http://uk1.descafe.com:8055
642	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:53.254+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	57	\N	http://uk1.descafe.com:8055
1087	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:36:59.976+00	172.22.0.1	axios/0.27.2	ddb_vote	22	\N	\N
643	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:38:53.338+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	58	\N	http://uk1.descafe.com:8055
644	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:18.26+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	60	\N	http://uk1.descafe.com:8055
645	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:23.952+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	45	\N	http://uk1.descafe.com:8055
646	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:24.043+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	60	\N	http://uk1.descafe.com:8055
647	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:24.136+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	46	\N	http://uk1.descafe.com:8055
648	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:24.226+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	47	\N	http://uk1.descafe.com:8055
649	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:24.295+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	48	\N	http://uk1.descafe.com:8055
650	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:24.351+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	49	\N	http://uk1.descafe.com:8055
651	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:24.435+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	50	\N	http://uk1.descafe.com:8055
652	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:40:24.497+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	51	\N	http://uk1.descafe.com:8055
653	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:08.987+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	61	\N	http://uk1.descafe.com:8055
654	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:12.339+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	45	\N	http://uk1.descafe.com:8055
655	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:12.427+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	60	\N	http://uk1.descafe.com:8055
656	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:12.502+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	61	\N	http://uk1.descafe.com:8055
657	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:12.582+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	46	\N	http://uk1.descafe.com:8055
658	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:13.237+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	47	\N	http://uk1.descafe.com:8055
659	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:13.74+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	48	\N	http://uk1.descafe.com:8055
660	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:13.837+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	49	\N	http://uk1.descafe.com:8055
661	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:13.94+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	50	\N	http://uk1.descafe.com:8055
662	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:43:14.082+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	51	\N	http://uk1.descafe.com:8055
663	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:53.377+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	62	\N	http://uk1.descafe.com:8055
664	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:58.688+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	45	\N	http://uk1.descafe.com:8055
665	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:58.745+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	60	\N	http://uk1.descafe.com:8055
666	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:58.809+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	61	\N	http://uk1.descafe.com:8055
667	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:58.915+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	62	\N	http://uk1.descafe.com:8055
668	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:59.079+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	46	\N	http://uk1.descafe.com:8055
669	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:59.321+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	47	\N	http://uk1.descafe.com:8055
670	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:59.396+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	48	\N	http://uk1.descafe.com:8055
671	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:59.45+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	49	\N	http://uk1.descafe.com:8055
672	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:59.528+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	50	\N	http://uk1.descafe.com:8055
673	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:44:59.613+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	51	\N	http://uk1.descafe.com:8055
674	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.223+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	45	\N	http://uk1.descafe.com:8055
675	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.285+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	60	\N	http://uk1.descafe.com:8055
676	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.341+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	62	\N	http://uk1.descafe.com:8055
677	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.404+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	61	\N	http://uk1.descafe.com:8055
678	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.488+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	46	\N	http://uk1.descafe.com:8055
679	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.537+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	47	\N	http://uk1.descafe.com:8055
680	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.596+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	48	\N	http://uk1.descafe.com:8055
681	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.646+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	49	\N	http://uk1.descafe.com:8055
682	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.749+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	50	\N	http://uk1.descafe.com:8055
683	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:45:01.818+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	51	\N	http://uk1.descafe.com:8055
685	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:45.135+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	45	\N	http://uk1.descafe.com:8055
686	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:45.212+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	63	\N	http://uk1.descafe.com:8055
687	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:45.292+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	61	\N	http://uk1.descafe.com:8055
688	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:45.397+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	46	\N	http://uk1.descafe.com:8055
689	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:45.584+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	47	\N	http://uk1.descafe.com:8055
690	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:45.992+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	48	\N	http://uk1.descafe.com:8055
691	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:46.109+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	49	\N	http://uk1.descafe.com:8055
692	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:46.219+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	50	\N	http://uk1.descafe.com:8055
693	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:46.303+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	51	\N	http://uk1.descafe.com:8055
684	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:48:41.993+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	63	\N	http://uk1.descafe.com:8055
694	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:51:01.481+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	64	\N	http://uk1.descafe.com:8055
695	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:42.908+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	45	\N	http://uk1.descafe.com:8055
696	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:43.179+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	63	\N	http://uk1.descafe.com:8055
697	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:43.677+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	61	\N	http://uk1.descafe.com:8055
698	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:43.743+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	64	\N	http://uk1.descafe.com:8055
699	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:43.799+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	46	\N	http://uk1.descafe.com:8055
700	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:43.878+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	47	\N	http://uk1.descafe.com:8055
701	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:43.943+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	48	\N	http://uk1.descafe.com:8055
702	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:44.001+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	49	\N	http://uk1.descafe.com:8055
703	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:44.09+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	50	\N	http://uk1.descafe.com:8055
704	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:55:44.184+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	51	\N	http://uk1.descafe.com:8055
705	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.653+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
706	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.707+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
707	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.723+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
708	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.746+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
709	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.768+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
710	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.793+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
711	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.834+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
712	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 10:59:55.854+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	ddb_feedback	\N	http://uk1.descafe.com:8055
713	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:00:38.259+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
714	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:33.955+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
715	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:48.227+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
716	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.054+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
717	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.199+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
718	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.337+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
719	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.425+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
720	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.565+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
721	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.675+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
722	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.906+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
723	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:53.963+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
724	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:54.035+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
725	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:54.113+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
726	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:55.881+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
727	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:55.946+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
728	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.014+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
729	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.068+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
730	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.17+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
731	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.231+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
732	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.285+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
733	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.349+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
734	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.453+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
735	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:56.51+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
736	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:57.53+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
737	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:57.582+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
738	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:57.633+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
739	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:57.705+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
740	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:57.851+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
741	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:58.041+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
742	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:58.125+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
743	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:58.18+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
744	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:58.242+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
745	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:01:58.312+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
746	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:54.027+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	75	\N	http://uk1.descafe.com:8055
747	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:58.277+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
748	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:58.464+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
749	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:58.722+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
750	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.01+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
751	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.302+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	75	\N	http://uk1.descafe.com:8055
752	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.4+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
753	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.494+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
754	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.587+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
755	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.687+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
756	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.799+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
757	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:02:59.911+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
758	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:05:45.581+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	7054d44a-1ab0-4738-a634-c5982913d256	\N	http://uk1.descafe.com:8055
759	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:33.42+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	76	\N	http://uk1.descafe.com:8055
760	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:39.859+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
761	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:39.989+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
762	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.089+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
763	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.198+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
764	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.317+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	75	\N	http://uk1.descafe.com:8055
765	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.445+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	76	\N	http://uk1.descafe.com:8055
1031	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-25 14:41:57.995+00	172.22.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
766	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.521+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
767	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.596+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
768	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.745+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
769	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.812+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
770	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.875+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
771	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:08:40.934+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
772	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:09:29.82+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	7054d44a-1ab0-4738-a634-c5982913d256	\N	http://uk1.descafe.com:8055
775	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:47.704+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
776	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:47.887+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
777	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:48.081+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
778	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:48.632+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
779	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:48.724+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
780	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:48.855+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
781	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:48.973+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
782	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:49.082+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
783	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:49.233+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
786	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:09.689+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	78	\N	http://uk1.descafe.com:8055
811	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:13:53.066+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
773	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:09:44.157+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	76	\N	http://uk1.descafe.com:8055
774	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:36.797+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
784	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:49.402+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
785	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:11:49.551+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
787	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:14.327+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
788	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:14.417+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
789	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:14.556+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
790	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:14.905+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
791	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:15.431+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
792	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:15.545+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	78	\N	http://uk1.descafe.com:8055
793	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:15.683+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
794	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:15.874+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
795	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:16.06+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
796	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:16.211+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
797	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:16.377+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
798	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:16.578+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
799	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:28.176+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
800	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:28.353+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	78	\N	http://uk1.descafe.com:8055
801	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:28.47+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
802	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:28.605+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
803	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:28.738+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
804	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:28.862+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
805	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:29.004+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
806	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:29.108+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
807	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:29.193+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
808	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:29.419+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
809	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:29.947+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
810	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:12:30.063+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
812	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:15:10.526+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	ddb_idea	\N	http://uk1.descafe.com:8055
813	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.001+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	80	\N	http://uk1.descafe.com:8055
814	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.07+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
815	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.101+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	82	\N	http://uk1.descafe.com:8055
816	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.173+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	83	\N	http://uk1.descafe.com:8055
817	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.212+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	84	\N	http://uk1.descafe.com:8055
818	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.266+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	85	\N	http://uk1.descafe.com:8055
819	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.307+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	86	\N	http://uk1.descafe.com:8055
821	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:49.917+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	87	\N	http://uk1.descafe.com:8055
820	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:01.355+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	ddb_comment	\N	http://uk1.descafe.com:8055
822	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:53.797+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	80	\N	http://uk1.descafe.com:8055
823	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:53.995+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	87	\N	http://uk1.descafe.com:8055
824	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:54.222+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
825	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:54.784+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	82	\N	http://uk1.descafe.com:8055
826	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:54.952+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	83	\N	http://uk1.descafe.com:8055
827	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:55.088+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	84	\N	http://uk1.descafe.com:8055
828	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:55.26+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	85	\N	http://uk1.descafe.com:8055
829	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:16:55.392+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	86	\N	http://uk1.descafe.com:8055
830	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:19:28.203+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	78	\N	http://uk1.descafe.com:8055
831	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:19:38.183+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
832	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:10.584+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
833	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:28.038+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
834	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:32.55+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
835	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:33.315+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	78	\N	http://uk1.descafe.com:8055
836	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:33.426+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
837	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:33.539+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
838	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:33.656+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
839	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:33.799+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
840	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:33.931+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
841	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:34.129+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
842	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:34.26+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
843	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:34.484+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
844	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:34.759+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
845	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:34.859+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
846	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:34.925+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
847	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:38.849+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
848	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:46.31+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
849	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:20:59.318+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	59	\N	http://uk1.descafe.com:8055
850	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 11:21:17.734+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	87	\N	http://uk1.descafe.com:8055
851	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 20:43:25.866+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	88	\N	http://uk1.descafe.com:8055
852	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 22:51:22.778+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
853	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 22:53:37.963+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
854	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 22:54:45.8+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	1bb4b697-845f-4d31-a352-2945cba97978	\N	http://uk1.descafe.com:8055
855	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 22:55:37.406+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
856	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-20 22:57:02.767+00	89.238.150.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	fe46d89a-d7d8-4276-9542-aed168d130ec	\N	http://uk1.descafe.com:8055
857	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:47:32.309+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
858	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:55:56.681+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
859	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:55:57.124+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	90	\N	http://uk1.descafe.com:8055
860	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:03.756+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
861	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:03.902+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
1032	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-02-25 14:44:08.259+00	172.22.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
862	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:03.984+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
863	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.065+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
864	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.136+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
865	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.244+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
866	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.31+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
867	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.383+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
868	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.511+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
869	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.614+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
870	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.674+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
871	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.734+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
872	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:04.802+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
873	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.237+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
874	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.305+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
875	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.37+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
876	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.438+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
877	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.498+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
878	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.645+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
879	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.819+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	77	\N	http://uk1.descafe.com:8055
880	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.873+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
881	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.924+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
882	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:07.986+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
883	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:08.075+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
884	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:08.149+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
885	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:56:08.209+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
886	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 01:59:44.5+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	\N	http://uk1.descafe.com:8055
887	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:07:37.803+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	2b423a4f-f127-4b85-8225-90ed99d2c33f	\N	http://uk1.descafe.com:8055
888	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:09:32.759+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	55e79a9c-9f06-439d-9a70-af0876bdbd39	\N	http://uk1.descafe.com:8055
889	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:11:26.626+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	153	\N	http://uk1.descafe.com:8055
890	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:11:28.472+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	154	\N	http://uk1.descafe.com:8055
891	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:11:29.949+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	155	\N	http://uk1.descafe.com:8055
892	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:21:13.211+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	91	\N	http://uk1.descafe.com:8055
893	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:08.574+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
894	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:08.68+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
895	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:08.759+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
896	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:08.854+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
897	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:08.979+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
898	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.205+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
899	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.267+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	91	\N	http://uk1.descafe.com:8055
900	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.336+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
901	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.436+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
902	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.494+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
903	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.576+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
904	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.638+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
905	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:09.706+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
906	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:22:25.345+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	\N	http://uk1.descafe.com:8055
907	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:23:58.209+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	2b423a4f-f127-4b85-8225-90ed99d2c33f	\N	http://uk1.descafe.com:8055
908	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:24:06.83+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	55e79a9c-9f06-439d-9a70-af0876bdbd39	\N	http://uk1.descafe.com:8055
909	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 02:24:43.132+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	156	\N	http://uk1.descafe.com:8055
910	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 23:47:13.215+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	157	\N	http://uk1.descafe.com:8055
911	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 23:47:14.62+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	158	\N	http://uk1.descafe.com:8055
912	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-21 23:47:15.848+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	159	\N	http://uk1.descafe.com:8055
913	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:11:07.295+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	\N	http://uk1.descafe.com:8055
914	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:12:28.099+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	ae6c2f43-d315-4223-a869-07720a5288e0	\N	http://uk1.descafe.com:8055
915	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:12:58.923+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	90	\N	http://uk1.descafe.com:8055
916	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:14:48.255+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	2a099a4b-f5ba-4fd5-addf-debe4972b6c3	\N	http://uk1.descafe.com:8055
917	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:20:13.839+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	2604d2c1-4929-4d69-84d9-cd13972e4321	\N	http://uk1.descafe.com:8055
918	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 00:52:56.772+00	81.92.200.52	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	a821325f-9b2a-4539-928d-451d8dfca2e3	\N	http://uk1.descafe.com:8055
919	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 02:57:16.809+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
920	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 02:57:31.95+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	\N	http://uk1.descafe.com:8055
921	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 02:58:17.199+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
922	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 02:58:32.794+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
923	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:01:18.783+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
924	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:01:28.917+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	55e79a9c-9f06-439d-9a70-af0876bdbd39	\N	http://uk1.descafe.com:8055
925	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:01:34.885+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	2a099a4b-f5ba-4fd5-addf-debe4972b6c3	\N	http://uk1.descafe.com:8055
926	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:04:20.991+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	2604d2c1-4929-4d69-84d9-cd13972e4321	\N	http://uk1.descafe.com:8055
927	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:04:37.816+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	2b423a4f-f127-4b85-8225-90ed99d2c33f	\N	http://uk1.descafe.com:8055
928	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:05:34.227+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
929	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-22 03:05:42.843+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	\N	http://uk1.descafe.com:8055
930	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-22 21:42:58.153+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
931	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 02:39:24.26+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	\N	http://uk1.descafe.com:8055
932	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 02:46:46.624+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	5899bcf3-b9e9-4c49-8410-ad9cea183a8c	\N	http://uk1.descafe.com:8055
933	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:20.955+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	92	\N	http://uk1.descafe.com:8055
934	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:26.974+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	52	\N	http://uk1.descafe.com:8055
935	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:27.193+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	59	\N	http://uk1.descafe.com:8055
936	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:27.375+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
937	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:27.547+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	92	\N	http://uk1.descafe.com:8055
938	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:27.706+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	54	\N	http://uk1.descafe.com:8055
939	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:28.504+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	55	\N	http://uk1.descafe.com:8055
940	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:28.623+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	56	\N	http://uk1.descafe.com:8055
941	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:28.714+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	57	\N	http://uk1.descafe.com:8055
942	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:28.774+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	58	\N	http://uk1.descafe.com:8055
943	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:28.843+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	90	\N	http://uk1.descafe.com:8055
944	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.332+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	52	\N	http://uk1.descafe.com:8055
945	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.425+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	59	\N	http://uk1.descafe.com:8055
946	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.489+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	92	\N	http://uk1.descafe.com:8055
947	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.549+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
948	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.601+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	54	\N	http://uk1.descafe.com:8055
949	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.665+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	55	\N	http://uk1.descafe.com:8055
950	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.724+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	56	\N	http://uk1.descafe.com:8055
951	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.802+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	57	\N	http://uk1.descafe.com:8055
952	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.889+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	58	\N	http://uk1.descafe.com:8055
953	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:30.987+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	90	\N	http://uk1.descafe.com:8055
954	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:50.097+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	1bb4b697-845f-4d31-a352-2945cba97978	\N	http://uk1.descafe.com:8055
955	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:01:55.848+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	fe46d89a-d7d8-4276-9542-aed168d130ec	\N	http://uk1.descafe.com:8055
956	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:02:07.576+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	a821325f-9b2a-4539-928d-451d8dfca2e3	\N	http://uk1.descafe.com:8055
957	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:02:12.776+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_company	ae6c2f43-d315-4223-a869-07720a5288e0	\N	http://uk1.descafe.com:8055
958	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:06.827+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	93	\N	http://uk1.descafe.com:8055
959	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:14.231+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	94	\N	http://uk1.descafe.com:8055
960	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:38.331+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	80	\N	http://uk1.descafe.com:8055
961	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:38.504+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	87	\N	http://uk1.descafe.com:8055
962	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:38.693+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	93	\N	http://uk1.descafe.com:8055
963	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:38.846+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
964	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:39.099+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	82	\N	http://uk1.descafe.com:8055
965	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:39.239+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	83	\N	http://uk1.descafe.com:8055
966	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:39.351+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	84	\N	http://uk1.descafe.com:8055
967	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:39.445+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	85	\N	http://uk1.descafe.com:8055
968	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:31:39.58+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	86	\N	http://uk1.descafe.com:8055
969	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:02.297+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
970	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:02.654+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
971	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:02.833+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
972	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:03.004+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
973	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:03.128+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
974	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:03.253+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
975	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:03.342+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	91	\N	http://uk1.descafe.com:8055
976	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:03.437+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	94	\N	http://uk1.descafe.com:8055
977	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:03.561+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
978	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:03.787+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
979	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:04.059+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
980	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:04.123+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
981	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:04.194+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
982	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 18:32:04.268+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
983	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 23:25:54.445+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	95	\N	http://uk1.descafe.com:8055
984	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 23:25:54.537+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	96	\N	http://uk1.descafe.com:8055
985	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 23:25:54.557+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	97	\N	http://uk1.descafe.com:8055
986	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 23:25:54.594+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	98	\N	http://uk1.descafe.com:8055
987	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 23:25:54.636+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	99	\N	http://uk1.descafe.com:8055
988	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-23 23:25:54.685+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	ddb_vote	\N	http://uk1.descafe.com:8055
989	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-24 18:51:41.178+00	172.19.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
990	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-24 18:53:03.244+00	172.19.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
991	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 22:04:33.495+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	100	\N	http://uk1.descafe.com:8055
992	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 22:04:34.428+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	101	\N	http://uk1.descafe.com:8055
993	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 22:04:35.384+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	102	\N	http://uk1.descafe.com:8055
994	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:18:31.597+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	103	\N	http://uk1.descafe.com:8055
995	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:18:32.191+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	104	\N	http://uk1.descafe.com:8055
996	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:22:36.758+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	105	\N	http://uk1.descafe.com:8055
997	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:22:37.202+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	106	\N	http://uk1.descafe.com:8055
998	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:22:37.541+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	107	\N	http://uk1.descafe.com:8055
999	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:22:38.262+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	108	\N	http://uk1.descafe.com:8055
1000	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:28:32.38+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	1	\N	http://uk1.descafe.com:8055
1001	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:29:06.471+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	2	\N	http://uk1.descafe.com:8055
1002	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:29:20.308+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	1	\N	http://uk1.descafe.com:8055
1003	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:29:20.312+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	2	\N	http://uk1.descafe.com:8055
1004	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:49.291+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	95	\N	http://uk1.descafe.com:8055
1005	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:49.488+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	107	\N	http://uk1.descafe.com:8055
1006	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:49.614+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	96	\N	http://uk1.descafe.com:8055
1007	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:49.74+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	97	\N	http://uk1.descafe.com:8055
1008	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:49.997+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	98	\N	http://uk1.descafe.com:8055
1009	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:50.171+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	99	\N	http://uk1.descafe.com:8055
1010	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:50.341+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	108	\N	http://uk1.descafe.com:8055
1011	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:50.769+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	95	\N	http://uk1.descafe.com:8055
1012	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:51.025+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	107	\N	http://uk1.descafe.com:8055
1013	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:51.113+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	108	\N	http://uk1.descafe.com:8055
1014	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:51.242+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	96	\N	http://uk1.descafe.com:8055
1015	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:51.371+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	97	\N	http://uk1.descafe.com:8055
1016	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:51.462+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	98	\N	http://uk1.descafe.com:8055
1017	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:32:51.554+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	99	\N	http://uk1.descafe.com:8055
1018	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:33:12.717+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	107	\N	http://uk1.descafe.com:8055
1019	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-24 23:33:15.659+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	108	\N	http://uk1.descafe.com:8055
1020	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 01:38:22.443+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	160	\N	http://uk1.descafe.com:8055
1021	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-25 01:39:24.132+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1022	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 02:28:12.599+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	3	\N	http://uk1.descafe.com:8055
1023	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 02:29:21.111+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	3	\N	http://uk1.descafe.com:8055
1024	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 03:34:02.446+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	161	\N	http://uk1.descafe.com:8055
1025	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 03:34:06.474+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	52	\N	http://uk1.descafe.com:8055
1026	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-25 03:34:17.808+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_collections	suggestion	\N	http://uk1.descafe.com:8055
1027	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-25 03:51:36.129+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1028	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-25 14:02:24.678+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1033	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-25 14:48:33.262+00	172.22.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
1034	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-25 14:48:44.43+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1035	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-25 14:49:01.262+00	172.22.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
1036	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-25 21:58:40.354+00	172.22.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
1037	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-25 23:45:31.718+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1038	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-26 01:45:00.601+00	172.22.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
1039	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-26 14:44:49.534+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	4	\N	http://uk1.descafe.com:8055
1040	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-26 14:47:13.543+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	4	\N	http://uk1.descafe.com:8055
1041	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-26 14:51:18.828+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	5	\N	http://uk1.descafe.com:8055
1042	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-26 14:52:25.832+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	5	\N	http://uk1.descafe.com:8055
1043	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-26 15:04:06.312+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	6	\N	http://uk1.descafe.com:8055
1044	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-26 15:04:52.131+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_vote	6	\N	http://uk1.descafe.com:8055
1045	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-26 16:40:44.215+00	172.22.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
1046	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-26 16:41:20.263+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1047	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-26 16:43:08.944+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1048	login	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 00:29:07.061+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	http://uk1.descafe.com:8055
1049	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 02:59:01.599+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	162	\N	http://uk1.descafe.com:8055
1050	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 02:59:32.736+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	163	\N	http://uk1.descafe.com:8055
1051	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 02:59:47.051+00	172.22.0.1	axios/0.27.2	ddb_vote	7	\N	\N
1052	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 03:01:40.911+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	164	\N	http://uk1.descafe.com:8055
1053	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 03:12:18.781+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	164	\N	http://uk1.descafe.com:8055
1054	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 03:33:56.809+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	165	\N	http://uk1.descafe.com:8055
1055	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 03:38:10.875+00	172.22.0.1	axios/0.27.2	ddb_vote	7	\N	\N
1056	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 03:38:30.374+00	172.22.0.1	axios/0.27.2	ddb_vote	8	\N	\N
1057	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 03:41:55.691+00	172.22.0.1	axios/0.27.2	ddb_vote	8	\N	\N
1058	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 03:48:34.858+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	165	\N	http://uk1.descafe.com:8055
1059	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-27 03:48:37.206+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_permissions	166	\N	http://uk1.descafe.com:8055
1060	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:01:59.33+00	172.22.0.1	axios/0.27.2	ddb_vote	9	\N	\N
1061	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:02:35.396+00	172.22.0.1	axios/0.27.2	ddb_vote	9	\N	\N
1062	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:21:31.037+00	172.22.0.1	axios/0.27.2	ddb_vote	10	\N	\N
1063	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:22:21.3+00	172.22.0.1	axios/0.27.2	ddb_vote	10	\N	\N
1064	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:23:53.552+00	172.22.0.1	axios/0.27.2	ddb_vote	11	\N	\N
1065	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:24:05.828+00	172.22.0.1	axios/0.27.2	ddb_vote	11	\N	\N
1066	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:24:08.393+00	172.22.0.1	axios/0.27.2	ddb_vote	12	\N	\N
1067	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:24:10.049+00	172.22.0.1	axios/0.27.2	ddb_vote	12	\N	\N
1068	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:24:58.687+00	172.22.0.1	axios/0.27.2	ddb_vote	13	\N	\N
1069	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:25:04.961+00	172.22.0.1	axios/0.27.2	ddb_vote	13	\N	\N
1070	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:24.641+00	172.22.0.1	axios/0.27.2	ddb_vote	14	\N	\N
1071	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:30.909+00	172.22.0.1	axios/0.27.2	ddb_vote	14	\N	\N
1072	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:33.182+00	172.22.0.1	axios/0.27.2	ddb_vote	15	\N	\N
1073	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:34.518+00	172.22.0.1	axios/0.27.2	ddb_vote	15	\N	\N
1074	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:35.783+00	172.22.0.1	axios/0.27.2	ddb_vote	16	\N	\N
1075	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:36.918+00	172.22.0.1	axios/0.27.2	ddb_vote	16	\N	\N
1076	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:38.148+00	172.22.0.1	axios/0.27.2	ddb_vote	17	\N	\N
1077	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:39.173+00	172.22.0.1	axios/0.27.2	ddb_vote	17	\N	\N
1078	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:40.214+00	172.22.0.1	axios/0.27.2	ddb_vote	18	\N	\N
1079	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:41.827+00	172.22.0.1	axios/0.27.2	ddb_vote	18	\N	\N
1080	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:42.871+00	172.22.0.1	axios/0.27.2	ddb_vote	19	\N	\N
1081	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:44.127+00	172.22.0.1	axios/0.27.2	ddb_vote	19	\N	\N
1082	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:45.303+00	172.22.0.1	axios/0.27.2	ddb_vote	20	\N	\N
1083	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:46.21+00	172.22.0.1	axios/0.27.2	ddb_vote	20	\N	\N
1084	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:31:48.344+00	172.22.0.1	axios/0.27.2	ddb_vote	21	\N	\N
1085	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:36:11.167+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1086	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 04:36:45.434+00	172.22.0.1	axios/0.27.2	ddb_vote	22	\N	\N
1112	login	aad86e98-7c2e-4157-a7bc-3828ef1a705a	2023-02-27 18:34:51.799+00	172.22.0.1	axios/0.27.2	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	\N	\N
1113	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:35:17.667+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1115	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:35:38.489+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1116	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:44:38.029+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1114	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:35:23.975+00	172.22.0.1	axios/0.27.2	ddb_vote	34	\N	\N
1117	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:49:18.948+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1118	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:49:22.072+00	172.22.0.1	axios/0.27.2	ddb_vote	35	\N	\N
1119	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:49:33.105+00	172.22.0.1	axios/0.27.2	ddb_vote	35	\N	\N
1120	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 18:50:34.335+00	172.22.0.1	axios/0.27.2	ddb_vote	36	\N	\N
1121	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 19:08:15.985+00	172.22.0.1	axios/0.27.2	ddb_vote	37	\N	\N
1122	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 19:08:18.477+00	172.22.0.1	axios/0.27.2	ddb_vote	37	\N	\N
1123	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 19:08:35.253+00	172.22.0.1	axios/0.27.2	ddb_vote	38	\N	\N
1124	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 19:08:35.258+00	172.22.0.1	axios/0.27.2	ddb_vote	39	\N	\N
1125	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 19:08:40.391+00	172.22.0.1	axios/0.27.2	ddb_vote	38	\N	\N
1126	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 19:08:42.262+00	172.22.0.1	axios/0.27.2	ddb_vote	39	\N	\N
1127	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-27 21:53:44.139+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1128	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 02:39:43.694+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1129	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 04:32:38.954+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1130	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:12.645+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	109	\N	http://uk1.descafe.com:8055
1131	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:37.376+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	80	\N	http://uk1.descafe.com:8055
1132	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:37.642+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	87	\N	http://uk1.descafe.com:8055
1133	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:37.814+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	93	\N	http://uk1.descafe.com:8055
1134	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:38.115+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	109	\N	http://uk1.descafe.com:8055
1135	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:38.204+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
1136	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:38.298+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	82	\N	http://uk1.descafe.com:8055
1137	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:38.621+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	83	\N	http://uk1.descafe.com:8055
1138	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:38.809+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	84	\N	http://uk1.descafe.com:8055
1139	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:38.978+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	85	\N	http://uk1.descafe.com:8055
1140	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:05:39.079+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	86	\N	http://uk1.descafe.com:8055
1141	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:06:29.48+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
1142	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:06:43.766+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
1143	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:07:57.734+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
1144	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 05:08:43.163+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_comment	e5279992-8fb4-463d-add6-e5822c64452b	\N	http://uk1.descafe.com:8055
1145	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 06:23:22.424+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1146	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 06:29:17.286+00	172.22.0.1	axios/0.27.2	ddb_comment	3dd9f793-0980-4847-9747-7d4a45c2a207	\N	\N
1147	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 06:30:59.516+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
1148	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 06:31:17.936+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	81	\N	http://uk1.descafe.com:8055
1149	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 08:53:40.825+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1150	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 09:42:07.292+00	172.22.0.1	axios/0.27.2	ddb_comment	b751b9d6-86d9-45e6-a1b1-80bf3d5c2afa	\N	\N
1151	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 09:42:38.987+00	172.22.0.1	axios/0.27.2	ddb_vote	36	\N	\N
1152	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 09:43:58.984+00	172.22.0.1	axios/0.27.2	ddb_vote	40	\N	\N
1153	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 09:46:12.124+00	172.22.0.1	axios/0.27.2	ddb_comment	17d9c74d-61e5-4553-8dd4-aed87611c0aa	\N	\N
1154	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:17:41.979+00	172.22.0.1	axios/0.27.2	ddb_vote	40	\N	\N
1155	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:17:43.389+00	172.22.0.1	axios/0.27.2	ddb_vote	41	\N	\N
1156	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:18:51.6+00	172.22.0.1	axios/0.27.2	ddb_vote	41	\N	\N
1157	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:18:57.624+00	172.22.0.1	axios/0.27.2	ddb_vote	42	\N	\N
1158	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:19:02.855+00	172.22.0.1	axios/0.27.2	ddb_vote	42	\N	\N
1159	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:19:04.939+00	172.22.0.1	axios/0.27.2	ddb_vote	43	\N	\N
1160	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:19:06.505+00	172.22.0.1	axios/0.27.2	ddb_vote	43	\N	\N
1161	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:19:08.609+00	172.22.0.1	axios/0.27.2	ddb_vote	44	\N	\N
1162	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:19:10.915+00	172.22.0.1	axios/0.27.2	ddb_vote	44	\N	\N
1163	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:19:14.011+00	172.22.0.1	axios/0.27.2	ddb_vote	45	\N	\N
1164	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:59:13.844+00	172.22.0.1	axios/0.27.2	ddb_vote	46	\N	\N
1165	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:59:17.732+00	172.22.0.1	axios/0.27.2	ddb_vote	46	\N	\N
1166	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 21:59:24.815+00	172.22.0.1	axios/0.27.2	ddb_vote	47	\N	\N
1167	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:26.625+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	52	\N	http://uk1.descafe.com:8055
1168	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:26.926+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	59	\N	http://uk1.descafe.com:8055
1169	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:27.038+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	90	\N	http://uk1.descafe.com:8055
1170	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:27.207+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	92	\N	http://uk1.descafe.com:8055
1171	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:27.479+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	53	\N	http://uk1.descafe.com:8055
1172	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:27.706+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	54	\N	http://uk1.descafe.com:8055
1173	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:27.97+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	55	\N	http://uk1.descafe.com:8055
1174	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:28.109+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	56	\N	http://uk1.descafe.com:8055
1175	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:28.257+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	57	\N	http://uk1.descafe.com:8055
1176	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 22:37:28.371+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	58	\N	http://uk1.descafe.com:8055
1177	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-02-28 23:07:36.778+00	172.22.0.1	axios/0.27.2	ddb_comment	8fce529f-a30c-4d18-b70e-0b8cb3c22bea	\N	\N
1178	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-02-28 23:08:10.626+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_comment	8fce529f-a30c-4d18-b70e-0b8cb3c22bea	\N	http://uk1.descafe.com:8055
1179	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-01 03:15:14.817+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	94	\N	http://uk1.descafe.com:8055
1180	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-01 04:07:36.093+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	92	\N	http://uk1.descafe.com:8055
1181	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-01 04:23:46.427+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1182	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-01 04:26:14.693+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1183	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-01 05:23:17.489+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1184	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-01 23:11:12.7+00	172.22.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
1185	create	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-01 23:11:15.932+00	172.22.0.1	axios/0.27.2	ddb_vote	48	\N	\N
1186	create	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-01 23:15:20.523+00	172.22.0.1	axios/0.27.2	ddb_vote	49	\N	\N
1187	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 00:45:42.566+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	5899bcf3-b9e9-4c49-8410-ad9cea183a8c	\N	http://uk1.descafe.com:8055
1188	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 01:15:59.198+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1189	login	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-02 01:45:32.474+00	172.22.0.1	axios/0.27.2	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	\N	\N
1190	create	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:26.109+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	110	\N	http://uk1.descafe.com:8055
1191	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:34.582+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
1192	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:34.676+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
1193	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:34.791+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
1194	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:34.894+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
1195	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.172+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
1196	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.375+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
1197	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.453+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	91	\N	http://uk1.descafe.com:8055
1198	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.538+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	110	\N	http://uk1.descafe.com:8055
1199	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.648+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	94	\N	http://uk1.descafe.com:8055
1200	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.748+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
1201	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.851+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
1202	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:35.936+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
1203	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:36.034+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
1204	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:36.144+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
1205	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:36.231+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
1206	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:36.314+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	105	\N	http://uk1.descafe.com:8055
1207	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.31+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
1208	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.383+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
1209	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.437+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
1210	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.51+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	110	\N	http://uk1.descafe.com:8055
1211	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.577+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	74	\N	http://uk1.descafe.com:8055
1212	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.677+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
1213	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.81+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
1214	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:37.985+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	91	\N	http://uk1.descafe.com:8055
1215	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.045+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	94	\N	http://uk1.descafe.com:8055
1216	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.11+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
1217	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.177+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
1218	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.252+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
1219	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.317+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
1220	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.405+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
1221	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.509+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
1222	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 01:51:38.573+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	105	\N	http://uk1.descafe.com:8055
1223	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 03:11:33.313+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	\N	http://uk1.descafe.com:8055
1224	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 03:12:13.785+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	\N	http://uk1.descafe.com:8055
1225	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 04:45:15.547+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1226	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 05:19:14.026+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1227	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 05:32:13.865+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1228	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 16:30:18.771+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1229	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 19:23:18.73+00	172.22.0.1	axios/0.27.2	ddb_comment	1cfd0c59-5bc8-4793-b434-4c52b199357b	\N	\N
1230	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 19:33:35.276+00	172.22.0.1	axios/0.27.2	ddb_comment	5a941db1-d769-4053-b169-1d3b9752be43	\N	\N
1231	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 23:44:44.979+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
1232	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-02 23:44:57.154+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
1233	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-02 23:48:56.31+00	172.22.0.1	axios/0.27.2	ddb_feedback	c9888177-d211-46b1-ab0f-dd85b5ae34aa	\N	\N
1234	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 00:57:29.715+00	172.22.0.1	axios/0.27.2	ddb_feedback	f2cc582f-5303-42f3-bc02-c7c09897be25	\N	\N
1235	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 00:58:00.028+00	172.22.0.1	axios/0.27.2	ddb_feedback	a6e26ad4-d06c-42d0-9c03-220a42645c5c	\N	\N
1236	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 00:58:32.472+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	a6e26ad4-d06c-42d0-9c03-220a42645c5c	\N	http://uk1.descafe.com:8055
1237	delete	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 00:58:32.524+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	f2cc582f-5303-42f3-bc02-c7c09897be25	\N	http://uk1.descafe.com:8055
1238	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 04:09:29.076+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1239	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 04:09:52.251+00	172.22.0.1	axios/0.27.2	ddb_vote	50	\N	\N
1240	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 04:31:41.203+00	172.22.0.1	axios/0.27.2	ddb_vote	51	\N	\N
1241	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-03 04:38:47.202+00	172.22.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1242	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:09.762+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	65	\N	http://uk1.descafe.com:8055
1243	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:10.492+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	89	\N	http://uk1.descafe.com:8055
1244	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:10.689+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	72	\N	http://uk1.descafe.com:8055
1245	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:10.882+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	110	\N	http://uk1.descafe.com:8055
1246	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:11.02+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	73	\N	http://uk1.descafe.com:8055
1247	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:11.188+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	79	\N	http://uk1.descafe.com:8055
1248	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:11.299+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	91	\N	http://uk1.descafe.com:8055
1249	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:11.409+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	94	\N	http://uk1.descafe.com:8055
1250	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:11.683+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	105	\N	http://uk1.descafe.com:8055
1251	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:12.248+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	66	\N	http://uk1.descafe.com:8055
1252	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:12.452+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	67	\N	http://uk1.descafe.com:8055
1253	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:12.548+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	68	\N	http://uk1.descafe.com:8055
1254	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:12.662+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	69	\N	http://uk1.descafe.com:8055
1255	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:12.781+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	70	\N	http://uk1.descafe.com:8055
1256	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-03 05:04:12.902+00	81.92.200.53	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	directus_fields	71	\N	http://uk1.descafe.com:8055
1257	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-04 13:57:23.116+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1258	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-04 17:31:31.884+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1259	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-05 02:40:51.91+00	172.24.0.1	axios/0.27.2	ddb_vote	52	\N	\N
1260	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-05 15:27:13.397+00	81.92.200.60	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	\N	http://uk1.descafe.com:8055
1261	update	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-05 15:28:28.041+00	81.92.200.60	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	\N	http://uk1.descafe.com:8055
1262	login	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-05 17:48:40.797+00	172.24.0.1	axios/0.27.2	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	\N	\N
1263	create	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-05 18:42:53.677+00	172.24.0.1	axios/0.27.2	ddb_vote	53	\N	\N
1264	delete	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-05 18:42:55.281+00	172.24.0.1	axios/0.27.2	ddb_vote	53	\N	\N
\.


--
-- Data for Name: directus_collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse) FROM stdin;
ddb_company	\N	\N	\N	f	f	\N	status	t	archived	draft	sort	all	\N	\N	\N	\N	open
ddb_feedback	\N	\N	\N	f	f	\N	status	t	archived	draft	sort	all	\N	\N	\N	\N	open
ddb_comment	\N	\N	\N	f	f	\N	status	t	archived	draft	sort	all	\N	\N	\N	\N	open
ddb_vote	\N	\N	\N	f	f	\N	\N	t	\N	\N	\N	all	\N	\N	\N	\N	open
\.


--
-- Data for Name: directus_dashboards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_dashboards (id, name, icon, note, date_created, user_created, color) FROM stdin;
\.


--
-- Data for Name: directus_fields; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_fields (id, collection, field, special, interface, options, display, display_options, readonly, hidden, sort, width, translations, note, conditions, required, "group", validation, validation_message) FROM stdin;
81	ddb_comment	status	\N	select-dropdown	{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]}	labels	{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]}	f	f	5	full	\N	\N	\N	f	\N	\N	\N
52	ddb_company	id	uuid	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
89	ddb_feedback	company_id	m2o	select-dropdown-m2o	{"template":"{{name}}"}	\N	\N	f	f	2	full	\N	\N	\N	t	\N	\N	\N
72	ddb_feedback	title	\N	input	\N	\N	\N	f	f	3	full	\N	\N	\N	t	\N	\N	\N
110	ddb_feedback	content	\N	input-rich-text-html	\N	\N	\N	f	f	4	full	\N	\N	\N	t	\N	\N	\N
106	directus_users	m2m_voted_for	m2m	list-m2m	\N	\N	\N	f	f	\N	full	\N	\N	\N	f	\N	\N	\N
98	ddb_vote	user_updated	user-updated	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	6	half	\N	\N	\N	f	\N	\N	\N
82	ddb_comment	sort	\N	input	\N	\N	\N	f	t	6	full	\N	\N	\N	f	\N	\N	\N
83	ddb_comment	user_created	user-created	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	7	half	\N	\N	\N	f	\N	\N	\N
59	ddb_company	name	\N	input	\N	\N	\N	f	f	2	full	\N	\N	\N	t	\N	\N	\N
73	ddb_feedback	body2	\N	input-rich-text-md	\N	\N	\N	f	f	5	full	\N	\N	\N	f	\N	\N	\N
79	ddb_feedback	body3	\N	input-multiline	{"trim":true}	\N	\N	f	f	6	full	\N	\N	\N	f	\N	\N	\N
53	ddb_company	status	\N	select-dropdown	{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]}	labels	{"choices":null}	f	f	5	full	\N	\N	\N	f	\N	\N	\N
54	ddb_company	sort	\N	input	\N	\N	\N	f	t	6	full	\N	\N	\N	f	\N	\N	\N
55	ddb_company	user_created	user-created	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	7	half	\N	\N	\N	f	\N	\N	\N
56	ddb_company	date_created	date-created	datetime	\N	datetime	{"relative":true}	t	t	8	half	\N	\N	\N	f	\N	\N	\N
57	ddb_company	user_updated	user-updated	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	9	half	\N	\N	\N	f	\N	\N	\N
91	ddb_feedback	author_id	m2o	select-dropdown-m2o	{"template":"{{first_name}} {{last_name}}","enableCreate":false}	\N	\N	f	f	7	full	\N	\N	\N	t	\N	\N	\N
94	ddb_feedback	o2m_comment	o2m	list-o2m	{"enableCreate":false,"enableSelect":false}	\N	\N	t	t	8	full	\N	\N	\N	f	\N	\N	\N
99	ddb_vote	date_updated	date-updated	datetime	\N	datetime	{"relative":true}	t	t	7	half	\N	\N	\N	f	\N	\N	\N
105	ddb_feedback	m2m_voted_by	m2m	\N	\N	\N	\N	f	t	9	full	\N	\N	\N	f	\N	\N	\N
66	ddb_feedback	status	\N	select-dropdown	{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]}	labels	{"choices":null}	f	f	10	full	\N	\N	\N	f	\N	\N	\N
67	ddb_feedback	sort	\N	input	\N	\N	\N	f	t	11	full	\N	\N	\N	f	\N	\N	\N
68	ddb_feedback	user_created	user-created	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	12	half	\N	\N	\N	f	\N	\N	\N
58	ddb_company	date_updated	date-updated	datetime	\N	datetime	{"relative":true}	t	t	10	half	\N	\N	\N	f	\N	\N	\N
69	ddb_feedback	date_created	date-created	datetime	\N	datetime	{"relative":true}	t	t	13	half	\N	\N	\N	f	\N	\N	\N
107	ddb_vote	voted_for	\N	\N	\N	\N	\N	f	f	2	full	\N	\N	\N	f	\N	\N	\N
108	ddb_vote	voted_by	\N	\N	\N	\N	\N	f	f	3	full	\N	\N	\N	f	\N	\N	\N
80	ddb_comment	id	uuid	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
93	ddb_comment	feedback_id	m2o	select-dropdown-m2o	{"enableCreate":false}	\N	\N	f	f	3	full	\N	\N	\N	t	\N	\N	\N
70	ddb_feedback	user_updated	user-updated	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	14	half	\N	\N	\N	f	\N	\N	\N
95	ddb_vote	id	\N	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
71	ddb_feedback	date_updated	date-updated	datetime	\N	datetime	{"relative":true}	t	t	15	half	\N	\N	\N	f	\N	\N	\N
96	ddb_vote	user_created	user-created	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	4	half	\N	\N	\N	f	\N	\N	\N
97	ddb_vote	date_created	date-created	datetime	\N	datetime	{"relative":true}	t	t	5	half	\N	\N	\N	f	\N	\N	\N
65	ddb_feedback	id	uuid	input	\N	\N	\N	t	t	1	full	\N	\N	\N	f	\N	\N	\N
87	ddb_comment	author_id	m2o	select-dropdown-m2o	{"template":"{{first_name}} {{last_name}}"}	\N	\N	f	f	2	full	\N	\N	\N	t	\N	\N	\N
109	ddb_comment	content	\N	input-rich-text-html	\N	\N	\N	f	f	4	full	\N	\N	\N	t	\N	\N	\N
84	ddb_comment	date_created	date-created	datetime	\N	datetime	{"relative":true}	t	t	8	half	\N	\N	\N	f	\N	\N	\N
85	ddb_comment	user_updated	user-updated	select-dropdown-m2o	{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}	user	\N	t	t	9	half	\N	\N	\N	f	\N	\N	\N
86	ddb_comment	date_updated	date-updated	datetime	\N	datetime	{"relative":true}	t	t	10	half	\N	\N	\N	f	\N	\N	\N
90	ddb_company	ddb_feedback	o2m	list-o2m	{"enableCreate":false,"enableSelect":false}	\N	\N	f	f	3	full	\N	\N	\N	f	\N	\N	\N
92	ddb_company	slug	\N	input	{"slug":true}	\N	\N	f	f	4	full	\N	\N	\N	t	\N	\N	\N
\.


--
-- Data for Name: directus_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_files (id, storage, filename_disk, filename_download, title, type, folder, uploaded_by, uploaded_on, modified_by, modified_on, charset, filesize, width, height, duration, embed, description, location, tags, metadata) FROM stdin;
\.


--
-- Data for Name: directus_flows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_flows (id, name, icon, color, description, status, trigger, accountability, options, operation, date_created, user_created) FROM stdin;
\.


--
-- Data for Name: directus_folders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_folders (id, name, parent) FROM stdin;
\.


--
-- Data for Name: directus_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_migrations (version, name, "timestamp") FROM stdin;
20201028A	Remove Collection Foreign Keys	2023-01-19 21:31:17.979441+00
20201029A	Remove System Relations	2023-01-19 21:31:17.98422+00
20201029B	Remove System Collections	2023-01-19 21:31:17.988156+00
20201029C	Remove System Fields	2023-01-19 21:31:18.003113+00
20201105A	Add Cascade System Relations	2023-01-19 21:31:18.048329+00
20201105B	Change Webhook URL Type	2023-01-19 21:31:18.054943+00
20210225A	Add Relations Sort Field	2023-01-19 21:31:18.061857+00
20210304A	Remove Locked Fields	2023-01-19 21:31:18.065816+00
20210312A	Webhooks Collections Text	2023-01-19 21:31:18.072399+00
20210331A	Add Refresh Interval	2023-01-19 21:31:18.075458+00
20210415A	Make Filesize Nullable	2023-01-19 21:31:18.082054+00
20210416A	Add Collections Accountability	2023-01-19 21:31:18.087879+00
20210422A	Remove Files Interface	2023-01-19 21:31:18.092201+00
20210506A	Rename Interfaces	2023-01-19 21:31:18.132343+00
20210510A	Restructure Relations	2023-01-19 21:31:18.151528+00
20210518A	Add Foreign Key Constraints	2023-01-19 21:31:18.163631+00
20210519A	Add System Fk Triggers	2023-01-19 21:31:18.190306+00
20210521A	Add Collections Icon Color	2023-01-19 21:31:18.194154+00
20210525A	Add Insights	2023-01-19 21:31:18.216014+00
20210608A	Add Deep Clone Config	2023-01-19 21:31:18.219478+00
20210626A	Change Filesize Bigint	2023-01-19 21:31:18.229779+00
20210716A	Add Conditions to Fields	2023-01-19 21:31:18.232903+00
20210721A	Add Default Folder	2023-01-19 21:31:18.238814+00
20210802A	Replace Groups	2023-01-19 21:31:18.243572+00
20210803A	Add Required to Fields	2023-01-19 21:31:18.247274+00
20210805A	Update Groups	2023-01-19 21:31:18.252338+00
20210805B	Change Image Metadata Structure	2023-01-19 21:31:18.255824+00
20210811A	Add Geometry Config	2023-01-19 21:31:18.260605+00
20210831A	Remove Limit Column	2023-01-19 21:31:18.264222+00
20210903A	Add Auth Provider	2023-01-19 21:31:18.27686+00
20210907A	Webhooks Collections Not Null	2023-01-19 21:31:18.282069+00
20210910A	Move Module Setup	2023-01-19 21:31:18.287527+00
20210920A	Webhooks URL Not Null	2023-01-19 21:31:18.294181+00
20210924A	Add Collection Organization	2023-01-19 21:31:18.300824+00
20210927A	Replace Fields Group	2023-01-19 21:31:18.312783+00
20210927B	Replace M2M Interface	2023-01-19 21:31:18.315991+00
20210929A	Rename Login Action	2023-01-19 21:31:18.319677+00
20211007A	Update Presets	2023-01-19 21:31:18.326154+00
20211009A	Add Auth Data	2023-01-19 21:31:18.331791+00
20211016A	Add Webhook Headers	2023-01-19 21:31:18.335289+00
20211103A	Set Unique to User Token	2023-01-19 21:31:18.341015+00
20211103B	Update Special Geometry	2023-01-19 21:31:18.351274+00
20211104A	Remove Collections Listing	2023-01-19 21:31:18.357003+00
20211118A	Add Notifications	2023-01-19 21:31:18.374784+00
20211211A	Add Shares	2023-01-19 21:31:18.395761+00
20211230A	Add Project Descriptor	2023-01-19 21:31:18.400037+00
20220303A	Remove Default Project Color	2023-01-19 21:31:18.406784+00
20220308A	Add Bookmark Icon and Color	2023-01-19 21:31:18.410954+00
20220314A	Add Translation Strings	2023-01-19 21:31:18.416413+00
20220322A	Rename Field Typecast Flags	2023-01-19 21:31:18.421302+00
20220323A	Add Field Validation	2023-01-19 21:31:18.425845+00
20220325A	Fix Typecast Flags	2023-01-19 21:31:18.43081+00
20220325B	Add Default Language	2023-01-19 21:31:18.439271+00
20220402A	Remove Default Value Panel Icon	2023-01-19 21:31:18.444565+00
20220429A	Add Flows	2023-01-19 21:31:18.47249+00
20220429B	Add Color to Insights Icon	2023-01-19 21:31:18.476564+00
20220429C	Drop Non Null From IP of Activity	2023-01-19 21:31:18.479578+00
20220429D	Drop Non Null From Sender of Notifications	2023-01-19 21:31:18.483228+00
20220614A	Rename Hook Trigger to Event	2023-01-19 21:31:18.486402+00
20220801A	Update Notifications Timestamp Column	2023-01-19 21:31:18.495712+00
20220802A	Add Custom Aspect Ratios	2023-01-19 21:31:18.499504+00
20220826A	Add Origin to Accountability	2023-01-19 21:31:18.505218+00
\.


--
-- Data for Name: directus_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_notifications (id, "timestamp", status, recipient, sender, subject, message, collection, item) FROM stdin;
\.


--
-- Data for Name: directus_operations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_operations (id, name, key, type, position_x, position_y, options, resolve, reject, flow, date_created, user_created) FROM stdin;
\.


--
-- Data for Name: directus_panels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_panels (id, dashboard, name, icon, color, show_header, note, type, position_x, position_y, width, height, options, date_created, user_created) FROM stdin;
\.


--
-- Data for Name: directus_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_permissions (id, role, collection, action, permissions, validation, presets, fields) FROM stdin;
1	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_files	create	{}	\N	\N	*
2	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_files	read	{}	\N	\N	*
3	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_files	update	{}	\N	\N	*
4	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_files	delete	{}	\N	\N	*
5	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_dashboards	create	{}	\N	\N	*
6	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_dashboards	read	{}	\N	\N	*
7	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_dashboards	update	{}	\N	\N	*
8	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_dashboards	delete	{}	\N	\N	*
9	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_panels	create	{}	\N	\N	*
10	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_panels	read	{}	\N	\N	*
11	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_panels	update	{}	\N	\N	*
12	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_panels	delete	{}	\N	\N	*
13	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_folders	create	{}	\N	\N	*
14	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_folders	read	{}	\N	\N	*
15	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_folders	update	{}	\N	\N	*
16	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_folders	delete	{}	\N	\N	\N
17	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_users	read	{}	\N	\N	*
19	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_roles	read	{}	\N	\N	*
20	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_shares	read	{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]}	\N	\N	*
21	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_shares	create	{}	\N	\N	*
22	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_shares	update	{"user_created":{"_eq":"$CURRENT_USER"}}	\N	\N	*
23	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_shares	delete	{"user_created":{"_eq":"$CURRENT_USER"}}	\N	\N	*
24	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_flows	read	{"trigger":{"_eq":"manual"}}	\N	\N	id,name,icon,color,options,trigger
128	a257a32a-b4d2-4782-a145-0200d277d527	directus_files	create	{}	\N	\N	*
129	a257a32a-b4d2-4782-a145-0200d277d527	directus_files	read	{}	\N	\N	*
130	a257a32a-b4d2-4782-a145-0200d277d527	directus_files	update	{}	\N	\N	*
131	a257a32a-b4d2-4782-a145-0200d277d527	directus_files	delete	{}	\N	\N	*
132	a257a32a-b4d2-4782-a145-0200d277d527	directus_dashboards	create	{}	\N	\N	*
133	a257a32a-b4d2-4782-a145-0200d277d527	directus_dashboards	read	{}	\N	\N	*
134	a257a32a-b4d2-4782-a145-0200d277d527	directus_dashboards	update	{}	\N	\N	*
135	a257a32a-b4d2-4782-a145-0200d277d527	directus_dashboards	delete	{}	\N	\N	*
136	a257a32a-b4d2-4782-a145-0200d277d527	directus_panels	create	{}	\N	\N	*
137	a257a32a-b4d2-4782-a145-0200d277d527	directus_panels	read	{}	\N	\N	*
138	a257a32a-b4d2-4782-a145-0200d277d527	directus_panels	update	{}	\N	\N	*
139	a257a32a-b4d2-4782-a145-0200d277d527	directus_panels	delete	{}	\N	\N	*
140	a257a32a-b4d2-4782-a145-0200d277d527	directus_folders	create	{}	\N	\N	*
141	a257a32a-b4d2-4782-a145-0200d277d527	directus_folders	read	{}	\N	\N	*
142	a257a32a-b4d2-4782-a145-0200d277d527	directus_folders	update	{}	\N	\N	*
143	a257a32a-b4d2-4782-a145-0200d277d527	directus_folders	delete	{}	\N	\N	\N
144	a257a32a-b4d2-4782-a145-0200d277d527	directus_users	read	{}	\N	\N	*
145	a257a32a-b4d2-4782-a145-0200d277d527	directus_users	update	{"id":{"_eq":"$CURRENT_USER"}}	\N	\N	first_name,last_name,email,password,location,title,description,avatar,language,theme,tfa_secret
146	a257a32a-b4d2-4782-a145-0200d277d527	directus_roles	read	{}	\N	\N	*
147	a257a32a-b4d2-4782-a145-0200d277d527	directus_shares	read	{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]}	\N	\N	*
148	a257a32a-b4d2-4782-a145-0200d277d527	directus_shares	create	{}	\N	\N	*
149	a257a32a-b4d2-4782-a145-0200d277d527	directus_shares	update	{"user_created":{"_eq":"$CURRENT_USER"}}	\N	\N	*
150	a257a32a-b4d2-4782-a145-0200d277d527	directus_shares	delete	{"user_created":{"_eq":"$CURRENT_USER"}}	\N	\N	*
151	a257a32a-b4d2-4782-a145-0200d277d527	directus_flows	read	{"trigger":{"_eq":"manual"}}	\N	\N	id,name,icon,color,options,trigger
152	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_users	create	{}	{}	\N	*
18	a2a22e06-e905-4a8e-a3a2-4abf257469e9	directus_users	update	{"id":{"_eq":"$CURRENT_USER"}}	\N	\N	first_name,last_name,email,password,location,title,description,avatar,language,theme,tfa_secret,status
153	\N	ddb_comment	read	{}	{}	\N	*
154	\N	ddb_company	read	{}	{}	\N	*
155	\N	ddb_feedback	read	{}	{}	\N	*
157	a2a22e06-e905-4a8e-a3a2-4abf257469e9	ddb_comment	read	{}	{}	\N	*
158	a2a22e06-e905-4a8e-a3a2-4abf257469e9	ddb_company	read	{}	{}	\N	*
159	a2a22e06-e905-4a8e-a3a2-4abf257469e9	ddb_feedback	read	{}	{}	\N	*
160	\N	ddb_vote	read	{}	{}	\N	*
162	a257a32a-b4d2-4782-a145-0200d277d527	ddb_vote	create	{}	{}	\N	*
163	a257a32a-b4d2-4782-a145-0200d277d527	ddb_comment	create	{}	{}	\N	*
156	a257a32a-b4d2-4782-a145-0200d277d527	ddb_feedback	create	{}	{}	\N	*
161	a2a22e06-e905-4a8e-a3a2-4abf257469e9	ddb_vote	read	{}	{}	\N	*
164	a257a32a-b4d2-4782-a145-0200d277d527	ddb_vote	delete	{}	{}	\N	*
166	a257a32a-b4d2-4782-a145-0200d277d527	ddb_vote	read	{}	{}	\N	*
\.


--
-- Data for Name: directus_presets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_presets (id, bookmark, "user", role, collection, search, layout, layout_query, layout_options, refresh_interval, filter, icon, color) FROM stdin;
9	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	ddb_company	\N	\N	{"tabular":{"page":1}}	\N	\N	\N	bookmark_outline	\N
5	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	ddb_feedback	\N	\N	{"tabular":{"fields":["company_id.name","title","author_id.first_name","status"],"sort":["company_id.name"],"page":1}}	{"tabular":{"widths":{"company_id.name":104,"title":205,"body2":176}}}	\N	\N	bookmark_outline	\N
4	\N	b53e2997-c47d-4507-88b6-b742652db504	\N	directus_users	\N	cards	{"cards":{"sort":["email"],"page":1}}	{"cards":{"icon":"account_circle","title":"{{ first_name }} {{ last_name }}","subtitle":"{{ email }}","size":4}}	\N	\N	bookmark_outline	\N
3	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	directus_activity	\N	tabular	{"tabular":{"sort":["-timestamp"],"fields":["action","collection","timestamp","user"],"page":1}}	{"tabular":{"widths":{"action":100,"collection":210,"timestamp":240,"user":240}}}	\N	\N	bookmark_outline	\N
7	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	ddb_vote	\N	\N	{"tabular":{"page":1,"fields":["voted_for","voted_for.title","voted_by","voted_by.first_name","date_created"]}}	{"tabular":{"widths":{}}}	\N	\N	bookmark_outline	\N
1	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	directus_users	\N	tabular	{"cards":{"sort":["email"],"page":1},"tabular":{"fields":["email","first_name","last_name","role","status","id"],"page":1}}	{"cards":{"icon":"account_circle","title":"{{ first_name }} {{ last_name }}","subtitle":"{{ email }}","size":2}}	\N	\N	bookmark_outline	\N
8	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	ddb_comment	\N	\N	{"tabular":{"page":1,"fields":["author_id","content","feedback_id","status","date_created"]}}	\N	\N	\N	bookmark_outline	\N
6	\N	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	\N	ddb_feedback	\N	\N	{"tabular":{"fields":["company_id.name","title","author_id.first_name","status"],"sort":["company_id.name"],"page":1}}	{"tabular":{"widths":{"company_id.name":104,"title":205,"body2":176}}}	\N	\N	bookmark_outline	\N
\.


--
-- Data for Name: directus_relations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_relations (id, many_collection, many_field, one_collection, one_field, one_collection_field, one_allowed_collections, junction_field, sort_field, one_deselect_action) FROM stdin;
15	ddb_company	user_created	directus_users	\N	\N	\N	\N	\N	nullify
16	ddb_company	user_updated	directus_users	\N	\N	\N	\N	\N	nullify
18	ddb_feedback	user_created	directus_users	\N	\N	\N	\N	\N	nullify
19	ddb_feedback	user_updated	directus_users	\N	\N	\N	\N	\N	nullify
24	ddb_comment	user_created	directus_users	\N	\N	\N	\N	\N	nullify
25	ddb_comment	user_updated	directus_users	\N	\N	\N	\N	\N	nullify
26	ddb_comment	author_id	directus_users	\N	\N	\N	\N	\N	nullify
27	ddb_feedback	company_id	ddb_company	ddb_feedback	\N	\N	\N	\N	nullify
29	ddb_comment	feedback_id	ddb_feedback	o2m_comment	\N	\N	\N	\N	nullify
28	ddb_feedback	author_id	directus_users	\N	\N	\N	\N	\N	nullify
30	ddb_vote	user_created	directus_users	\N	\N	\N	\N	\N	nullify
31	ddb_vote	user_updated	directus_users	\N	\N	\N	\N	\N	nullify
34	ddb_vote	voted_by	directus_users	m2m_voted_for	\N	\N	voted_for	\N	nullify
35	ddb_vote	voted_for	ddb_feedback	m2m_voted_by	\N	\N	voted_by	\N	nullify
\.


--
-- Data for Name: directus_revisions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_revisions (id, activity, collection, item, data, delta, parent) FROM stdin;
1	3	directus_users	98336213-8d8b-4c4d-b7e3-9834003ebe1c	{"role":"e9cc001b-b4f1-4096-bf59-b7572b19d012","first_name":"API user 1","token":"**********"}	{"role":"e9cc001b-b4f1-4096-bf59-b7572b19d012","first_name":"API user 1","token":"**********"}	\N
2	5	directus_users	b53e2997-c47d-4507-88b6-b742652db504	{"first_name":"API User 1","token":"**********"}	{"first_name":"API User 1","token":"**********"}	\N
3	6	directus_users	b53e2997-c47d-4507-88b6-b742652db504	{"id":"b53e2997-c47d-4507-88b6-b742652db504","first_name":"API User 1","last_name":null,"email":"apiuser1@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":null,"token":"**********","last_access":null,"last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":true}	{"email":"apiuser1@test.com","password":"**********"}	\N
4	7	directus_settings	1	{"project_name":"GetMAS"}	{"project_name":"GetMAS"}	\N
5	8	directus_fields	1	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"suggestion"}	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"suggestion"}	\N
6	9	directus_fields	2	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"suggestion"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"suggestion"}	\N
7	10	directus_fields	3	{"interface":"input","hidden":true,"field":"sort","collection":"suggestion"}	{"interface":"input","hidden":true,"field":"sort","collection":"suggestion"}	\N
8	11	directus_fields	4	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"suggestion"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"suggestion"}	\N
9	12	directus_fields	5	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"suggestion"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"suggestion"}	\N
10	13	directus_fields	6	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"suggestion"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"suggestion"}	\N
11	14	directus_fields	7	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"suggestion"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"suggestion"}	\N
12	15	directus_collections	suggestion	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"suggestion"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"suggestion"}	\N
13	16	directus_fields	8	{"interface":"input-multiline","special":null,"collection":"suggestion","field":"description"}	{"interface":"input-multiline","special":null,"collection":"suggestion","field":"description"}	\N
14	17	directus_fields	1	{"id":1,"collection":"suggestion","field":"id","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"id","sort":1,"group":null}	\N
15	18	directus_fields	8	{"id":8,"collection":"suggestion","field":"description","special":null,"interface":"input-multiline","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"description","sort":2,"group":null}	\N
16	19	directus_fields	2	{"id":2,"collection":"suggestion","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"status","sort":3,"group":null}	\N
17	20	directus_fields	3	{"id":3,"collection":"suggestion","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"sort","sort":4,"group":null}	\N
53	56	directus_permissions	5	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
18	21	directus_fields	4	{"id":4,"collection":"suggestion","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":5,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"user_created","sort":5,"group":null}	\N
19	22	directus_fields	5	{"id":5,"collection":"suggestion","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"date_created","sort":6,"group":null}	\N
20	23	directus_fields	6	{"id":6,"collection":"suggestion","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"user_updated","sort":7,"group":null}	\N
21	24	directus_fields	7	{"id":7,"collection":"suggestion","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"date_updated","sort":8,"group":null}	\N
22	25	directus_fields	9	{"interface":"input","special":null,"collection":"suggestion","field":"company"}	{"interface":"input","special":null,"collection":"suggestion","field":"company"}	\N
23	26	directus_fields	1	{"id":1,"collection":"suggestion","field":"id","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"id","sort":1,"group":null}	\N
24	27	directus_fields	9	{"id":9,"collection":"suggestion","field":"company","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"company","sort":2,"group":null}	\N
25	28	directus_fields	8	{"id":8,"collection":"suggestion","field":"description","special":null,"interface":"input-multiline","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"description","sort":3,"group":null}	\N
26	29	directus_fields	2	{"id":2,"collection":"suggestion","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"status","sort":4,"group":null}	\N
27	30	directus_fields	3	{"id":3,"collection":"suggestion","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"sort","sort":5,"group":null}	\N
28	31	directus_fields	4	{"id":4,"collection":"suggestion","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"user_created","sort":6,"group":null}	\N
29	32	directus_fields	5	{"id":5,"collection":"suggestion","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"date_created","sort":7,"group":null}	\N
30	33	directus_fields	6	{"id":6,"collection":"suggestion","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"user_updated","sort":8,"group":null}	\N
31	34	directus_fields	7	{"id":7,"collection":"suggestion","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"date_updated","sort":9,"group":null}	\N
34	37	directus_fields	9	{"id":9,"collection":"suggestion","field":"company","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"company","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
35	38	directus_fields	8	{"id":8,"collection":"suggestion","field":"description","special":null,"interface":"input-multiline","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"description","special":null,"interface":"input-multiline","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
37	40	directus_fields	10	{"interface":"input","special":null,"options":{"min":-3},"collection":"suggestion","field":"votes"}	{"interface":"input","special":null,"options":{"min":-3},"collection":"suggestion","field":"votes"}	\N
38	41	directus_fields	1	{"id":1,"collection":"suggestion","field":"id","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"id","sort":1,"group":null}	\N
39	42	directus_fields	9	{"id":9,"collection":"suggestion","field":"company","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"company","sort":2,"group":null}	\N
40	43	directus_fields	8	{"id":8,"collection":"suggestion","field":"description","special":null,"interface":"input-multiline","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"description","sort":3,"group":null}	\N
41	44	directus_fields	2	{"id":2,"collection":"suggestion","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"status","sort":4,"group":null}	\N
42	45	directus_fields	10	{"id":10,"collection":"suggestion","field":"votes","special":null,"interface":"input","options":{"min":-3},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"votes","sort":5,"group":null}	\N
43	46	directus_fields	3	{"id":3,"collection":"suggestion","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"sort","sort":6,"group":null}	\N
44	47	directus_fields	4	{"id":4,"collection":"suggestion","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"user_created","sort":7,"group":null}	\N
45	48	directus_fields	5	{"id":5,"collection":"suggestion","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"date_created","sort":8,"group":null}	\N
46	49	directus_fields	6	{"id":6,"collection":"suggestion","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"user_updated","sort":9,"group":null}	\N
47	50	directus_fields	7	{"id":7,"collection":"suggestion","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"suggestion","field":"date_updated","sort":10,"group":null}	\N
48	51	directus_roles	a2a22e06-e905-4a8e-a3a2-4abf257469e9	{"name":"API user","admin_access":false,"app_access":true}	{"name":"API user","admin_access":false,"app_access":true}	\N
49	52	directus_permissions	1	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
50	53	directus_permissions	2	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
51	54	directus_permissions	3	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
52	55	directus_permissions	4	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
54	57	directus_permissions	6	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
55	58	directus_permissions	7	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
56	59	directus_permissions	8	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
57	60	directus_permissions	9	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
58	61	directus_permissions	10	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
59	62	directus_permissions	11	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
60	63	directus_permissions	12	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
61	64	directus_permissions	13	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
62	65	directus_permissions	14	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
63	66	directus_permissions	15	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
64	67	directus_permissions	16	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
65	68	directus_permissions	17	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
66	69	directus_permissions	18	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
67	70	directus_permissions	19	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
68	71	directus_permissions	20	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
69	72	directus_permissions	21	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
70	73	directus_permissions	22	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
71	74	directus_permissions	23	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
72	75	directus_permissions	24	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
73	76	directus_permissions	25	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
74	77	directus_permissions	26	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
75	79	directus_users	b53e2997-c47d-4507-88b6-b742652db504	{"id":"b53e2997-c47d-4507-88b6-b742652db504","first_name":"API User 1","last_name":null,"email":"apiuser1@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","token":"**********","last_access":null,"last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":true}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9"}	\N
76	81	directus_users	b53e2997-c47d-4507-88b6-b742652db504	{"id":"b53e2997-c47d-4507-88b6-b742652db504","first_name":"API User 1","last_name":null,"email":"apiuser1@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","token":"**********","last_access":null,"last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":false}	{"email_notifications":false}	\N
77	82	directus_permissions	27	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
78	83	directus_permissions	28	{"role":null,"collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
79	84	directus_permissions	29	{"role":null,"collection":"suggestion","action":"update","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"update","fields":["*"],"permissions":{},"validation":{}}	\N
80	86	directus_permissions	30	{"role":null,"collection":"suggestion","action":"delete","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"delete","fields":["*"],"permissions":{},"validation":{}}	\N
81	87	directus_permissions	31	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
82	92	directus_permissions	32	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
83	94	directus_permissions	33	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
84	96	directus_permissions	34	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
85	97	directus_permissions	35	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"update","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"update","fields":["*"],"permissions":{},"validation":{}}	\N
86	98	directus_permissions	36	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"delete","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"delete","fields":["*"],"permissions":{},"validation":{}}	\N
87	103	directus_permissions	37	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
88	105	directus_permissions	38	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
89	106	directus_permissions	39	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
90	109	directus_permissions	40	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
91	110	directus_permissions	41	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
92	111	directus_permissions	42	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"update","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"update","fields":["*"],"permissions":{},"validation":{}}	\N
93	112	directus_permissions	43	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"delete","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"delete","fields":["*"],"permissions":{},"validation":{}}	\N
94	113	directus_permissions	44	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
95	114	directus_permissions	45	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"share","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"share","fields":["*"],"permissions":{},"validation":{}}	\N
96	120	directus_permissions	46	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
97	122	directus_permissions	47	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
98	125	directus_permissions	48	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
99	127	directus_permissions	49	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
100	129	directus_permissions	50	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
101	131	directus_permissions	51	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
103	134	directus_permissions	52	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
132	163	directus_settings	1	{"id":1,"project_name":"GetMAS","project_url":null,"project_color":null,"project_logo":null,"public_foreground":null,"public_background":null,"public_note":null,"auth_login_attempts":25,"auth_password_policy":null,"storage_asset_transform":"all","storage_asset_presets":null,"custom_css":null,"storage_default_folder":null,"basemaps":null,"mapbox_key":null,"module_bar":[{"type":"module","id":"content","enabled":true},{"type":"module","id":"users","enabled":true},{"type":"module","id":"files","enabled":true},{"type":"module","id":"insights","enabled":true},{"type":"module","id":"docs","enabled":true},{"type":"module","id":"settings","enabled":true,"locked":true},{"type":"module","id":"generate-types","enabled":true}],"project_descriptor":null,"translation_strings":null,"default_language":"en-US","custom_aspect_ratios":null}	{"module_bar":[{"type":"module","id":"content","enabled":true},{"type":"module","id":"users","enabled":true},{"type":"module","id":"files","enabled":true},{"type":"module","id":"insights","enabled":true},{"type":"module","id":"docs","enabled":true},{"type":"module","id":"settings","enabled":true,"locked":true},{"type":"module","id":"generate-types","enabled":true}]}	\N
156	187	directus_permissions	65	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
138	169	directus_users	b53e2997-c47d-4507-88b6-b742652db504	{"id":"b53e2997-c47d-4507-88b6-b742652db504","first_name":"API User 1","last_name":null,"email":"apiuser1@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","token":"**********","last_access":null,"last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":false}	{"token":"**********"}	\N
143	174	directus_roles	a257a32a-b4d2-4782-a145-0200d277d527	{"name":"web user","admin_access":false,"app_access":true}	{"name":"web user","admin_access":false,"app_access":true}	\N
144	175	directus_permissions	53	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
145	176	directus_permissions	54	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
146	177	directus_permissions	55	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
147	178	directus_permissions	56	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
148	179	directus_permissions	57	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
149	180	directus_permissions	58	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
150	181	directus_permissions	59	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
151	182	directus_permissions	60	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
152	183	directus_permissions	61	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
153	184	directus_permissions	62	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
154	185	directus_permissions	63	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
155	186	directus_permissions	64	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
157	188	directus_permissions	66	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
158	189	directus_permissions	67	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
159	190	directus_permissions	68	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
160	191	directus_permissions	69	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
161	192	directus_permissions	70	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
162	193	directus_permissions	71	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
163	194	directus_permissions	72	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
164	195	directus_permissions	73	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
165	196	directus_permissions	74	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
166	197	directus_permissions	75	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
167	198	directus_permissions	76	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
168	223	directus_permissions	77	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"directus_users","action":"read"}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"directus_users","action":"read"}	\N
169	225	directus_permissions	78	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
170	226	directus_permissions	79	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
171	227	directus_permissions	80	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
172	228	directus_permissions	81	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
173	229	directus_permissions	82	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
174	230	directus_permissions	83	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
175	231	directus_permissions	84	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
176	232	directus_permissions	85	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
177	233	directus_permissions	86	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
178	234	directus_permissions	87	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
179	235	directus_permissions	88	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
180	236	directus_permissions	89	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
181	237	directus_permissions	90	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
182	238	directus_permissions	91	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
183	239	directus_permissions	92	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
184	240	directus_permissions	93	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
185	241	directus_permissions	94	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
186	242	directus_permissions	95	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
187	243	directus_permissions	96	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
188	244	directus_permissions	97	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
189	245	directus_permissions	98	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
190	246	directus_permissions	99	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
191	247	directus_permissions	100	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
192	248	directus_permissions	101	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
193	273	directus_permissions	102	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
194	274	directus_permissions	103	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
195	275	directus_permissions	104	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
196	276	directus_permissions	105	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
197	277	directus_permissions	106	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
198	278	directus_permissions	107	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
199	279	directus_permissions	108	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
200	280	directus_permissions	109	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
201	281	directus_permissions	110	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
202	282	directus_permissions	111	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
203	283	directus_permissions	112	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
204	284	directus_permissions	113	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
205	285	directus_permissions	114	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
206	286	directus_permissions	115	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
207	287	directus_permissions	116	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
208	288	directus_permissions	117	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
209	289	directus_permissions	118	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
210	290	directus_permissions	119	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
211	291	directus_permissions	120	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
212	292	directus_permissions	121	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
213	293	directus_permissions	122	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
214	294	directus_permissions	123	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
215	295	directus_permissions	124	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
216	296	directus_permissions	125	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
217	321	directus_permissions	126	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"directus_users","action":"read"}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"directus_users","action":"read"}	\N
218	323	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	{"first_name":"Bob","last_name":"WebUser1","email":"bob@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527","email_notifications":false}	{"first_name":"Bob","last_name":"WebUser1","email":"bob@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527","email_notifications":false}	\N
219	324	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	{"first_name":"Amy","last_name":"WebUser2","email_notifications":false,"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"first_name":"Amy","last_name":"WebUser2","email_notifications":false,"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
220	325	directus_roles	a257a32a-b4d2-4782-a145-0200d277d527	{"id":"a257a32a-b4d2-4782-a145-0200d277d527","name":"Web user","icon":"supervised_user_circle","description":null,"ip_access":null,"enforce_tfa":false,"admin_access":false,"app_access":true,"users":["aad86e98-7c2e-4157-a7bc-3828ef1a705a","cab90e35-563a-4aea-a129-bb7d3d149f9f"]}	{"name":"Web user"}	\N
221	326	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	{"id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","first_name":"Amy","last_name":"WebUser2","email":"amy@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a257a32a-b4d2-4782-a145-0200d277d527","token":null,"last_access":null,"last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":false}	{"email":"amy@test.com","password":"**********"}	\N
222	329	directus_permissions	127	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"suggestion","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
223	336	directus_permissions	128	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
224	337	directus_permissions	129	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
225	338	directus_permissions	130	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
226	339	directus_permissions	131	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_files","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
227	340	directus_permissions	132	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
228	341	directus_permissions	133	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
229	342	directus_permissions	134	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
230	343	directus_permissions	135	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_dashboards","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
231	344	directus_permissions	136	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
232	345	directus_permissions	137	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
233	346	directus_permissions	138	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
234	347	directus_permissions	139	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_panels","action":"delete","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
235	348	directus_permissions	140	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
236	349	directus_permissions	141	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
237	350	directus_permissions	142	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"update","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
238	351	directus_permissions	143	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_folders","action":"delete","permissions":{},"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
239	352	directus_permissions	144	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
240	353	directus_permissions	145	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
241	354	directus_permissions	146	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_roles","action":"read","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
242	355	directus_permissions	147	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"read","permissions":{"_or":[{"role":{"_eq":"$CURRENT_ROLE"}},{"role":{"_null":true}}]},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
243	356	directus_permissions	148	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"create","permissions":{},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
244	357	directus_permissions	149	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"update","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
245	358	directus_permissions	150	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_shares","action":"delete","permissions":{"user_created":{"_eq":"$CURRENT_USER"}},"fields":["*"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
246	359	directus_permissions	151	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"collection":"directus_flows","action":"read","permissions":{"trigger":{"_eq":"manual"}},"fields":["id","name","icon","color","options","trigger"],"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
247	403	directus_users	aaa1b7cb-2f23-4e92-828a-a90946b50992	{"first_name":"remix_api","email":"remix_api@test.com","password":"**********","role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","token":"**********"}	{"first_name":"remix_api","email":"remix_api@test.com","password":"**********","role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","token":"**********"}	\N
249	406	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	{"id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","first_name":"Bob","last_name":"WebUser1","email":"bob@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a257a32a-b4d2-4782-a145-0200d277d527","token":null,"last_access":"2023-01-28T22:37:34.470Z","last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":false}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
248	405	directus_roles	a257a32a-b4d2-4782-a145-0200d277d527	{"id":"a257a32a-b4d2-4782-a145-0200d277d527","name":"webuser","icon":"supervised_user_circle","description":null,"ip_access":null,"enforce_tfa":false,"admin_access":false,"app_access":true,"users":["aad86e98-7c2e-4157-a7bc-3828ef1a705a","cab90e35-563a-4aea-a129-bb7d3d149f9f"]}	{"name":"webuser"}	249
250	407	directus_permissions	152	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"directus_users","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"directus_users","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
251	408	directus_permissions	18	{"id":18,"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"validation":null,"presets":null,"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret","status"]}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"directus_users","action":"update","permissions":{"id":{"_eq":"$CURRENT_USER"}},"validation":null,"presets":null,"fields":["first_name","last_name","email","password","location","title","description","avatar","language","theme","tfa_secret","status"]}	\N
252	444	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	{"first_name":"cat","last_name":"webuser3","email":"cat@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"first_name":"cat","last_name":"webuser3","email":"cat@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
253	447	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	{"id":"6a85a60f-5e1e-443a-b698-f7dc396583b9","first_name":"cat","last_name":"webuser3","email":"cat@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"suspended","role":"a257a32a-b4d2-4782-a145-0200d277d527","token":null,"last_access":"2023-01-29T21:19:23.474Z","last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":true}	{"status":"suspended"}	\N
254	450	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	{"first_name":"dave","last_name":"webuser4","email":"dave@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"first_name":"dave","last_name":"webuser4","email":"dave@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
255	562	directus_users	d95fe57c-1cbb-490b-a664-4772d34b2024	{"first_name":"d","last_name":"3","email":"dfdf@dfd.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"first_name":"d","last_name":"3","email":"dfdf@dfd.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
256	566	directus_users	cab90e35-563a-4aea-a129-bb7d3d149f9f	{"id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","first_name":"Amy","last_name":"WebUser2","email":"amy@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a257a32a-b4d2-4782-a145-0200d277d527","token":null,"last_access":"2023-02-15T20:20:24.986Z","last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":false}	{"password":"**********"}	\N
257	567	directus_users	aad86e98-7c2e-4157-a7bc-3828ef1a705a	{"id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","first_name":"Bob","last_name":"WebUser1","email":"bob@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a257a32a-b4d2-4782-a145-0200d277d527","token":null,"last_access":"2023-02-18T22:32:31.762Z","last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":false}	{"password":"**********"}	\N
258	568	directus_users	6a85a60f-5e1e-443a-b698-f7dc396583b9	{"id":"6a85a60f-5e1e-443a-b698-f7dc396583b9","first_name":"cat","last_name":"webuser3","email":"cat@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"suspended","role":"a257a32a-b4d2-4782-a145-0200d277d527","token":null,"last_access":"2023-01-29T21:19:23.474Z","last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":true}	{"password":"**********"}	\N
259	569	directus_users	15b505d3-5248-4766-b271-fcdf176a5ef5	{"id":"15b505d3-5248-4766-b271-fcdf176a5ef5","first_name":"dave","last_name":"webuser4","email":"dave@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"a257a32a-b4d2-4782-a145-0200d277d527","token":null,"last_access":"2023-02-19T05:44:44.970Z","last_page":null,"provider":"default","external_identifier":null,"auth_data":null,"email_notifications":true}	{"password":"**********"}	\N
260	570	directus_users	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	{"id":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","first_name":"Admin","last_name":"User","email":"admin@test.com","password":"**********","location":null,"title":null,"description":null,"tags":null,"avatar":null,"language":null,"theme":"auto","tfa_secret":null,"status":"active","role":"e9cc001b-b4f1-4096-bf59-b7572b19d012","token":null,"last_access":"2023-02-20T00:34:34.947Z","last_page":"/users/96b1e708-8f8d-4d52-aed9-d46577cc6fa1","provider":"default","external_identifier":null,"auth_data":null,"email_notifications":true}	{"password":"**********"}	\N
261	572	directus_users	6aefe5e6-a952-429a-aad9-690ceb487bee	{"first_name":"Eve","last_name":"webuser 5","email":"eve@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	{"first_name":"Eve","last_name":"webuser 5","email":"eve@test.com","password":"**********","role":"a257a32a-b4d2-4782-a145-0200d277d527"}	\N
262	574	directus_fields	11	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"Company"}	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"Company"}	\N
263	575	directus_fields	12	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"Company"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"Company"}	\N
264	576	directus_fields	13	{"interface":"input","hidden":true,"field":"sort","collection":"Company"}	{"interface":"input","hidden":true,"field":"sort","collection":"Company"}	\N
265	577	directus_fields	14	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"Company"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"Company"}	\N
266	578	directus_fields	15	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"Company"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"Company"}	\N
267	579	directus_fields	16	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"Company"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"Company"}	\N
268	580	directus_fields	17	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"Company"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"Company"}	\N
269	581	directus_collections	Company	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"Company"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"Company"}	\N
270	582	directus_fields	18	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"Idea"}	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"Idea"}	\N
271	583	directus_fields	19	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"Idea"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"Idea"}	\N
272	584	directus_fields	20	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"Idea"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"Idea"}	\N
273	585	directus_fields	21	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"Idea"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"Idea"}	\N
274	586	directus_fields	22	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"Idea"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"Idea"}	\N
275	587	directus_fields	23	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"Idea"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"Idea"}	\N
276	588	directus_collections	Idea	{"archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"Idea"}	{"archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"Idea"}	\N
277	592	directus_fields	24	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"dap_idea"}	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"dap_idea"}	\N
278	593	directus_fields	25	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"dap_idea"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"dap_idea"}	\N
279	594	directus_fields	26	{"interface":"input","hidden":true,"field":"sort","collection":"dap_idea"}	{"interface":"input","hidden":true,"field":"sort","collection":"dap_idea"}	\N
280	595	directus_fields	27	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"dap_idea"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"dap_idea"}	\N
281	596	directus_fields	28	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"dap_idea"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"dap_idea"}	\N
282	597	directus_fields	29	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"dap_idea"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"dap_idea"}	\N
283	598	directus_fields	30	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"dap_idea"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"dap_idea"}	\N
284	599	directus_collections	dap_idea	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"dap_idea"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"dap_idea"}	\N
285	600	directus_fields	31	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"dab_company"}	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"dab_company"}	\N
286	601	directus_fields	32	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"dab_company"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"dab_company"}	\N
287	602	directus_fields	33	{"interface":"input","hidden":true,"field":"sort","collection":"dab_company"}	{"interface":"input","hidden":true,"field":"sort","collection":"dab_company"}	\N
288	603	directus_fields	34	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"dab_company"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"dab_company"}	\N
289	604	directus_fields	35	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"dab_company"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"dab_company"}	\N
290	605	directus_fields	36	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"dab_company"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"dab_company"}	\N
291	606	directus_fields	37	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"dab_company"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"dab_company"}	\N
292	607	directus_collections	dab_company	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"dab_company"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"dab_company"}	\N
293	609	directus_fields	38	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"dap_company"}	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"dap_company"}	\N
294	610	directus_fields	39	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"dap_company"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"dap_company"}	\N
295	611	directus_fields	40	{"interface":"input","hidden":true,"field":"sort","collection":"dap_company"}	{"interface":"input","hidden":true,"field":"sort","collection":"dap_company"}	\N
296	612	directus_fields	41	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"dap_company"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"dap_company"}	\N
297	613	directus_fields	42	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"dap_company"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"dap_company"}	\N
298	614	directus_fields	43	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"dap_company"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"dap_company"}	\N
299	615	directus_fields	44	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"dap_company"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"dap_company"}	\N
300	616	directus_collections	dap_company	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"dap_company"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"dap_company"}	\N
301	619	directus_fields	45	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_idea"}	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_idea"}	\N
302	620	directus_fields	46	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_idea"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_idea"}	\N
303	621	directus_fields	47	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_idea"}	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_idea"}	\N
304	622	directus_fields	48	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_idea"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_idea"}	\N
305	623	directus_fields	49	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_idea"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_idea"}	\N
306	624	directus_fields	50	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_idea"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_idea"}	\N
307	625	directus_fields	51	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_idea"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_idea"}	\N
308	626	directus_collections	ddb_idea	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_idea"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_idea"}	\N
309	627	directus_fields	52	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_company"}	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_company"}	\N
310	628	directus_fields	53	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_company"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_company"}	\N
311	629	directus_fields	54	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_company"}	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_company"}	\N
312	630	directus_fields	55	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_company"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_company"}	\N
313	631	directus_fields	56	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_company"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_company"}	\N
314	632	directus_fields	57	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_company"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_company"}	\N
315	633	directus_fields	58	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_company"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_company"}	\N
316	634	directus_collections	ddb_company	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_company"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_company"}	\N
317	635	directus_fields	59	{"interface":"input","special":null,"required":true,"collection":"ddb_company","field":"name"}	{"interface":"input","special":null,"required":true,"collection":"ddb_company","field":"name"}	\N
318	636	directus_fields	52	{"id":52,"collection":"ddb_company","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"id","sort":1,"group":null}	\N
319	637	directus_fields	59	{"id":59,"collection":"ddb_company","field":"name","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"name","sort":2,"group":null}	\N
320	638	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","sort":3,"group":null}	\N
321	639	directus_fields	54	{"id":54,"collection":"ddb_company","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"sort","sort":4,"group":null}	\N
322	640	directus_fields	55	{"id":55,"collection":"ddb_company","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":5,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_created","sort":5,"group":null}	\N
323	641	directus_fields	56	{"id":56,"collection":"ddb_company","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_created","sort":6,"group":null}	\N
324	642	directus_fields	57	{"id":57,"collection":"ddb_company","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_updated","sort":7,"group":null}	\N
325	643	directus_fields	58	{"id":58,"collection":"ddb_company","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_updated","sort":8,"group":null}	\N
326	644	directus_fields	60	{"interface":"input","special":null,"required":true,"collection":"ddb_idea","field":"title"}	{"interface":"input","special":null,"required":true,"collection":"ddb_idea","field":"title"}	\N
327	645	directus_fields	45	{"id":45,"collection":"ddb_idea","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"id","sort":1,"group":null}	\N
328	646	directus_fields	60	{"id":60,"collection":"ddb_idea","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"title","sort":2,"group":null}	\N
329	647	directus_fields	46	{"id":46,"collection":"ddb_idea","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"status","sort":3,"group":null}	\N
330	648	directus_fields	47	{"id":47,"collection":"ddb_idea","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"sort","sort":4,"group":null}	\N
331	649	directus_fields	48	{"id":48,"collection":"ddb_idea","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":5,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_created","sort":5,"group":null}	\N
332	650	directus_fields	49	{"id":49,"collection":"ddb_idea","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_created","sort":6,"group":null}	\N
333	651	directus_fields	50	{"id":50,"collection":"ddb_idea","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_updated","sort":7,"group":null}	\N
334	652	directus_fields	51	{"id":51,"collection":"ddb_idea","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_updated","sort":8,"group":null}	\N
335	653	directus_fields	61	{"interface":"input-rich-text-html","special":null,"options":{"trim":true,"softLength":null},"required":true,"collection":"ddb_idea","field":"body"}	{"interface":"input-rich-text-html","special":null,"options":{"trim":true,"softLength":null},"required":true,"collection":"ddb_idea","field":"body"}	\N
336	654	directus_fields	45	{"id":45,"collection":"ddb_idea","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"id","sort":1,"group":null}	\N
337	655	directus_fields	60	{"id":60,"collection":"ddb_idea","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"title","sort":2,"group":null}	\N
338	656	directus_fields	61	{"id":61,"collection":"ddb_idea","field":"body","special":null,"interface":"input-rich-text-html","options":{"trim":true,"softLength":null},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"body","sort":3,"group":null}	\N
354	672	directus_fields	50	{"id":50,"collection":"ddb_idea","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_updated","sort":9,"group":null}	\N
366	684	directus_fields	63	{"interface":"input","special":null,"required":true,"collection":"ddb_idea","field":"title"}	{"interface":"input","special":null,"required":true,"collection":"ddb_idea","field":"title"}	\N
339	657	directus_fields	46	{"id":46,"collection":"ddb_idea","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"status","sort":4,"group":null}	\N
340	658	directus_fields	47	{"id":47,"collection":"ddb_idea","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"sort","sort":5,"group":null}	\N
341	659	directus_fields	48	{"id":48,"collection":"ddb_idea","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_created","sort":6,"group":null}	\N
342	660	directus_fields	49	{"id":49,"collection":"ddb_idea","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_created","sort":7,"group":null}	\N
343	661	directus_fields	50	{"id":50,"collection":"ddb_idea","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_updated","sort":8,"group":null}	\N
344	662	directus_fields	51	{"id":51,"collection":"ddb_idea","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_updated","sort":9,"group":null}	\N
345	663	directus_fields	62	{"interface":"input","special":null,"collection":"ddb_idea","field":"t2"}	{"interface":"input","special":null,"collection":"ddb_idea","field":"t2"}	\N
346	664	directus_fields	45	{"id":45,"collection":"ddb_idea","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"id","sort":1,"group":null}	\N
347	665	directus_fields	60	{"id":60,"collection":"ddb_idea","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"title","sort":2,"group":null}	\N
348	666	directus_fields	61	{"id":61,"collection":"ddb_idea","field":"body","special":null,"interface":"input-rich-text-html","options":{"trim":true,"softLength":null},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"body","sort":3,"group":null}	\N
349	667	directus_fields	62	{"id":62,"collection":"ddb_idea","field":"t2","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"t2","sort":4,"group":null}	\N
350	668	directus_fields	46	{"id":46,"collection":"ddb_idea","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"status","sort":5,"group":null}	\N
351	669	directus_fields	47	{"id":47,"collection":"ddb_idea","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"sort","sort":6,"group":null}	\N
352	670	directus_fields	48	{"id":48,"collection":"ddb_idea","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_created","sort":7,"group":null}	\N
353	671	directus_fields	49	{"id":49,"collection":"ddb_idea","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_created","sort":8,"group":null}	\N
712	1064	ddb_vote	11	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
355	673	directus_fields	51	{"id":51,"collection":"ddb_idea","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_updated","sort":10,"group":null}	\N
356	674	directus_fields	45	{"id":45,"collection":"ddb_idea","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"id","sort":1,"group":null}	\N
357	675	directus_fields	60	{"id":60,"collection":"ddb_idea","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"title","sort":2,"group":null}	\N
358	676	directus_fields	62	{"id":62,"collection":"ddb_idea","field":"t2","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"t2","sort":3,"group":null}	\N
359	677	directus_fields	61	{"id":61,"collection":"ddb_idea","field":"body","special":null,"interface":"input-rich-text-html","options":{"trim":true,"softLength":null},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"body","sort":4,"group":null}	\N
360	678	directus_fields	46	{"id":46,"collection":"ddb_idea","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"status","sort":5,"group":null}	\N
361	679	directus_fields	47	{"id":47,"collection":"ddb_idea","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"sort","sort":6,"group":null}	\N
362	680	directus_fields	48	{"id":48,"collection":"ddb_idea","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_created","sort":7,"group":null}	\N
363	681	directus_fields	49	{"id":49,"collection":"ddb_idea","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_created","sort":8,"group":null}	\N
364	682	directus_fields	50	{"id":50,"collection":"ddb_idea","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_updated","sort":9,"group":null}	\N
365	683	directus_fields	51	{"id":51,"collection":"ddb_idea","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_updated","sort":10,"group":null}	\N
367	685	directus_fields	45	{"id":45,"collection":"ddb_idea","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"id","sort":1,"group":null}	\N
368	686	directus_fields	63	{"id":63,"collection":"ddb_idea","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"title","sort":2,"group":null}	\N
369	687	directus_fields	61	{"id":61,"collection":"ddb_idea","field":"body","special":null,"interface":"input-rich-text-html","options":{"trim":true,"softLength":null},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"body","sort":3,"group":null}	\N
370	688	directus_fields	46	{"id":46,"collection":"ddb_idea","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"status","sort":4,"group":null}	\N
371	689	directus_fields	47	{"id":47,"collection":"ddb_idea","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"sort","sort":5,"group":null}	\N
372	690	directus_fields	48	{"id":48,"collection":"ddb_idea","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_created","sort":6,"group":null}	\N
373	691	directus_fields	49	{"id":49,"collection":"ddb_idea","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_created","sort":7,"group":null}	\N
374	692	directus_fields	50	{"id":50,"collection":"ddb_idea","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_updated","sort":8,"group":null}	\N
375	693	directus_fields	51	{"id":51,"collection":"ddb_idea","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_updated","sort":9,"group":null}	\N
376	694	directus_fields	64	{"interface":"select-dropdown-m2o","special":["m2o"],"options":{"template":"{{first_name}}{{last_name}}"},"required":true,"collection":"ddb_idea","field":"author"}	{"interface":"select-dropdown-m2o","special":["m2o"],"options":{"template":"{{first_name}}{{last_name}}"},"required":true,"collection":"ddb_idea","field":"author"}	\N
377	695	directus_fields	45	{"id":45,"collection":"ddb_idea","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"id","sort":1,"group":null}	\N
378	696	directus_fields	63	{"id":63,"collection":"ddb_idea","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"title","sort":2,"group":null}	\N
379	697	directus_fields	61	{"id":61,"collection":"ddb_idea","field":"body","special":null,"interface":"input-rich-text-html","options":{"trim":true,"softLength":null},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"body","sort":3,"group":null}	\N
380	698	directus_fields	64	{"id":64,"collection":"ddb_idea","field":"author","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}}{{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"author","sort":4,"group":null}	\N
381	699	directus_fields	46	{"id":46,"collection":"ddb_idea","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"status","sort":5,"group":null}	\N
382	700	directus_fields	47	{"id":47,"collection":"ddb_idea","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"sort","sort":6,"group":null}	\N
383	701	directus_fields	48	{"id":48,"collection":"ddb_idea","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_created","sort":7,"group":null}	\N
384	702	directus_fields	49	{"id":49,"collection":"ddb_idea","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_created","sort":8,"group":null}	\N
385	703	directus_fields	50	{"id":50,"collection":"ddb_idea","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"user_updated","sort":9,"group":null}	\N
386	704	directus_fields	51	{"id":51,"collection":"ddb_idea","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_idea","field":"date_updated","sort":10,"group":null}	\N
387	705	directus_fields	65	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_feedback"}	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_feedback"}	\N
388	706	directus_fields	66	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_feedback"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_feedback"}	\N
389	707	directus_fields	67	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_feedback"}	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_feedback"}	\N
390	708	directus_fields	68	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_feedback"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_feedback"}	\N
391	709	directus_fields	69	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_feedback"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_feedback"}	\N
392	710	directus_fields	70	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_feedback"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_feedback"}	\N
393	711	directus_fields	71	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_feedback"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_feedback"}	\N
394	712	directus_collections	ddb_feedback	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_feedback"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_feedback"}	\N
395	713	directus_fields	72	{"interface":"input","special":null,"required":true,"collection":"ddb_feedback","field":"title"}	{"interface":"input","special":null,"required":true,"collection":"ddb_feedback","field":"title"}	\N
396	714	directus_fields	73	{"interface":"input-rich-text-md","special":null,"required":true,"collection":"ddb_feedback","field":"body2"}	{"interface":"input-rich-text-md","special":null,"required":true,"collection":"ddb_feedback","field":"body2"}	\N
397	715	directus_fields	74	{"interface":"input-rich-text-html","special":null,"required":true,"collection":"ddb_feedback","field":"body"}	{"interface":"input-rich-text-html","special":null,"required":true,"collection":"ddb_feedback","field":"body"}	\N
398	716	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
399	717	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
400	718	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":3,"group":null}	\N
401	719	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":4,"group":null}	\N
402	720	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":5,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":5,"group":null}	\N
403	721	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":6,"group":null}	\N
404	722	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":7,"group":null}	\N
405	723	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":8,"group":null}	\N
406	724	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":9,"group":null}	\N
407	725	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":10,"group":null}	\N
408	726	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
409	727	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
410	728	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":3,"group":null}	\N
411	729	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":4,"group":null}	\N
412	730	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":5,"group":null}	\N
413	731	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":6,"group":null}	\N
414	732	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":7,"group":null}	\N
415	733	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":8,"group":null}	\N
416	734	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":9,"group":null}	\N
417	735	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":10,"group":null}	\N
418	736	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
419	737	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
420	738	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":3,"group":null}	\N
421	739	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":4,"group":null}	\N
422	740	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":5,"group":null}	\N
423	741	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":6,"group":null}	\N
424	742	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":7,"group":null}	\N
425	743	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":8,"group":null}	\N
426	744	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":9,"group":null}	\N
427	745	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":10,"group":null}	\N
428	746	directus_fields	75	{"interface":"select-dropdown-m2o","special":["m2o"],"options":{"template":"{{first_name}} {{last_name}}"},"collection":"ddb_feedback","field":"author"}	{"interface":"select-dropdown-m2o","special":["m2o"],"options":{"template":"{{first_name}} {{last_name}}"},"collection":"ddb_feedback","field":"author"}	\N
429	747	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
430	748	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
431	749	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":3,"group":null}	\N
432	750	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":4,"group":null}	\N
433	751	directus_fields	75	{"id":75,"collection":"ddb_feedback","field":"author","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author","sort":5,"group":null}	\N
434	752	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":6,"group":null}	\N
435	753	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":7,"group":null}	\N
436	754	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":8,"group":null}	\N
437	755	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":9,"group":null}	\N
469	788	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
438	756	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":10,"group":null}	\N
439	757	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":11,"group":null}	\N
440	758	ddb_feedback	7054d44a-1ab0-4738-a634-c5982913d256	{"body2":"[http://googlr.com](url)","body":"<p>ok</p>\\n<p><a href=\\"http://oo.hhjj.pp/\\" target=\\"_blank\\" rel=\\"noopener\\">http://oo.hhjj.pp/</a></p>","title":"t1"}	{"body2":"[http://googlr.com](url)","body":"<p>ok</p>\\n<p><a href=\\"http://oo.hhjj.pp/\\" target=\\"_blank\\" rel=\\"noopener\\">http://oo.hhjj.pp/</a></p>","title":"t1"}	\N
441	759	directus_fields	76	{"interface":"select-dropdown-m2o","special":["m2o"],"options":{"template":"{{name}}"},"collection":"ddb_feedback","field":"company_id"}	{"interface":"select-dropdown-m2o","special":["m2o"],"options":{"template":"{{name}}"},"collection":"ddb_feedback","field":"company_id"}	\N
442	760	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
443	761	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
444	762	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":3,"group":null}	\N
445	763	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":4,"group":null}	\N
446	764	directus_fields	75	{"id":75,"collection":"ddb_feedback","field":"author","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author","sort":5,"group":null}	\N
447	765	directus_fields	76	{"id":76,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":6,"group":null}	\N
448	766	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":7,"group":null}	\N
449	767	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":8,"group":null}	\N
450	768	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":9,"group":null}	\N
451	769	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":10,"group":null}	\N
452	770	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":11,"group":null}	\N
453	771	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":12,"group":null}	\N
454	773	directus_fields	76	{"id":76,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
455	774	directus_fields	77	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{first_name}} {{last_name}}"},"collection":"ddb_feedback","field":"author_id"}	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{first_name}} {{last_name}}"},"collection":"ddb_feedback","field":"author_id"}	\N
456	775	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
457	776	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
458	777	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":3,"group":null}	\N
459	778	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":4,"group":null}	\N
460	779	directus_fields	77	{"id":77,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":5,"group":null}	\N
461	780	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":6,"group":null}	\N
462	781	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":7,"group":null}	\N
463	782	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":8,"group":null}	\N
464	783	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":9,"group":null}	\N
465	784	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":10,"group":null}	\N
466	785	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":11,"group":null}	\N
467	786	directus_fields	78	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{name}}"},"collection":"ddb_feedback","field":"company_id"}	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{name}}"},"collection":"ddb_feedback","field":"company_id"}	\N
468	787	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
713	1066	ddb_vote	12	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
470	789	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":3,"group":null}	\N
471	790	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":4,"group":null}	\N
472	791	directus_fields	77	{"id":77,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":5,"group":null}	\N
473	792	directus_fields	78	{"id":78,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":6,"group":null}	\N
474	793	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":7,"group":null}	\N
475	794	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":8,"group":null}	\N
476	795	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":9,"group":null}	\N
477	796	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":10,"group":null}	\N
478	797	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":11,"group":null}	\N
479	798	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":12,"group":null}	\N
480	799	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
481	800	directus_fields	78	{"id":78,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
482	801	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
483	802	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":4,"group":null}	\N
484	803	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":5,"group":null}	\N
492	811	directus_fields	79	{"interface":"input-multiline","special":null,"required":true,"options":{"trim":true},"collection":"ddb_feedback","field":"body3"}	{"interface":"input-multiline","special":null,"required":true,"options":{"trim":true},"collection":"ddb_feedback","field":"body3"}	\N
485	804	directus_fields	77	{"id":77,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":6,"group":null}	\N
486	805	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":7,"group":null}	\N
487	806	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":8,"group":null}	\N
488	807	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":9,"group":null}	\N
489	808	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":10,"group":null}	\N
490	809	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":11,"group":null}	\N
491	810	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":12,"group":null}	\N
493	813	directus_fields	80	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_comment"}	{"hidden":true,"readonly":true,"interface":"input","special":["uuid"],"field":"id","collection":"ddb_comment"}	\N
494	814	directus_fields	81	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_comment"}	{"width":"full","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"interface":"select-dropdown","display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"field":"status","collection":"ddb_comment"}	\N
495	815	directus_fields	82	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_comment"}	{"interface":"input","hidden":true,"field":"sort","collection":"ddb_comment"}	\N
496	816	directus_fields	83	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_comment"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_comment"}	\N
497	817	directus_fields	84	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_comment"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_comment"}	\N
498	818	directus_fields	85	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_comment"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_comment"}	\N
499	819	directus_fields	86	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_comment"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_comment"}	\N
714	1068	ddb_vote	13	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
500	820	directus_collections	ddb_comment	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_comment"}	{"sort_field":"sort","archive_field":"status","archive_value":"archived","unarchive_value":"draft","singleton":false,"collection":"ddb_comment"}	\N
501	821	directus_fields	87	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{first_name}} {{last_name}}"},"collection":"ddb_comment","field":"author_id"}	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{first_name}} {{last_name}}"},"collection":"ddb_comment","field":"author_id"}	\N
502	822	directus_fields	80	{"id":80,"collection":"ddb_comment","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"id","sort":1,"group":null}	\N
503	823	directus_fields	87	{"id":87,"collection":"ddb_comment","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"author_id","sort":2,"group":null}	\N
504	824	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","sort":3,"group":null}	\N
505	825	directus_fields	82	{"id":82,"collection":"ddb_comment","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"sort","sort":4,"group":null}	\N
506	826	directus_fields	83	{"id":83,"collection":"ddb_comment","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":5,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"user_created","sort":5,"group":null}	\N
507	827	directus_fields	84	{"id":84,"collection":"ddb_comment","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"date_created","sort":6,"group":null}	\N
508	828	directus_fields	85	{"id":85,"collection":"ddb_comment","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"user_updated","sort":7,"group":null}	\N
509	829	directus_fields	86	{"id":86,"collection":"ddb_comment","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"date_updated","sort":8,"group":null}	\N
510	830	directus_fields	78	{"id":78,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
511	831	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
512	832	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
513	833	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
514	834	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
515	835	directus_fields	78	{"id":78,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
516	836	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
517	837	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":4,"group":null}	\N
518	838	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":5,"group":null}	\N
519	839	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":6,"group":null}	\N
520	840	directus_fields	77	{"id":77,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":7,"group":null}	\N
521	841	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":8,"group":null}	\N
522	842	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":9,"group":null}	\N
523	843	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":10,"group":null}	\N
524	844	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":11,"group":null}	\N
525	845	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":12,"group":null}	\N
526	846	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":13,"group":null}	\N
527	847	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
528	848	directus_fields	77	{"id":77,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
529	849	directus_fields	59	{"id":59,"collection":"ddb_company","field":"name","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"name","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
530	850	directus_fields	87	{"id":87,"collection":"ddb_comment","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
531	851	directus_fields	88	{"interface":"list-o2m","special":["o2m"],"collection":"ddb_company","field":"feedback_id"}	{"interface":"list-o2m","special":["o2m"],"collection":"ddb_company","field":"feedback_id"}	\N
532	852	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
533	853	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
534	854	ddb_company	1bb4b697-845f-4d31-a352-2945cba97978	{"name":"Tesco"}	{"name":"Tesco"}	\N
535	855	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
536	856	ddb_company	fe46d89a-d7d8-4276-9542-aed168d130ec	{"name":"ASDA"}	{"name":"ASDA"}	\N
552	872	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":13,"group":null}	\N
715	1070	ddb_vote	14	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
537	857	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
538	858	directus_fields	89	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{name}}"},"collection":"ddb_feedback","field":"company_id"}	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{name}}"},"collection":"ddb_feedback","field":"company_id"}	\N
539	859	directus_fields	90	{"special":["o2m"],"interface":"list-o2m","collection":"ddb_company","field":"ddb_feedback"}	{"special":["o2m"],"interface":"list-o2m","collection":"ddb_company","field":"ddb_feedback"}	\N
540	860	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
541	861	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":2,"group":null}	\N
542	862	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":3,"group":null}	\N
543	863	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":4,"group":null}	\N
544	864	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":5,"group":null}	\N
545	865	directus_fields	89	{"id":89,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":6,"group":null}	\N
546	866	directus_fields	77	{"id":77,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":7,"group":null}	\N
547	867	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":8,"group":null}	\N
548	868	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":9,"group":null}	\N
549	869	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":10,"group":null}	\N
550	870	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":11,"group":null}	\N
551	871	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":12,"group":null}	\N
662	983	directus_fields	95	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"ddb_vote"}	{"hidden":true,"interface":"input","readonly":true,"field":"id","collection":"ddb_vote"}	\N
553	873	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
554	874	directus_fields	89	{"id":89,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
555	875	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
556	876	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":4,"group":null}	\N
557	877	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":5,"group":null}	\N
558	878	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":6,"group":null}	\N
559	879	directus_fields	77	{"id":77,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":7,"group":null}	\N
560	880	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":8,"group":null}	\N
561	881	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":9,"group":null}	\N
562	882	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":10,"group":null}	\N
563	883	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":11,"group":null}	\N
564	884	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":12,"group":null}	\N
565	885	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":13,"group":null}	\N
566	886	ddb_feedback	6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5","title":"More pet snacks","body":"<p>We <strong>LOVE </strong>pets!!!</p>","body2":"We **LOVE** pets!!!","body3":"We LOVE pets!!!"}	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5","title":"More pet snacks","body":"<p>We <strong>LOVE </strong>pets!!!</p>","body2":"We **LOVE** pets!!!","body3":"We LOVE pets!!!"}	\N
567	887	ddb_feedback	2b423a4f-f127-4b85-8225-90ed99d2c33f	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"Longer opening hours","body":"<p>Please open 24 hours everyday!</p>","body2":"Please open 24 hours everyday!","body3":"Please open 24 hours everyday!"}	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"Longer opening hours","body":"<p>Please open 24 hours everyday!</p>","body2":"Please open 24 hours everyday!","body3":"Please open 24 hours everyday!"}	\N
716	1072	ddb_vote	15	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
568	888	ddb_feedback	55e79a9c-9f06-439d-9a70-af0876bdbd39	{"company_id":"fe46d89a-d7d8-4276-9542-aed168d130ec","title":"More ready meals","body":"<p>Cannot live without ready meals!!</p>","body2":"Cannot live without ready meals!!","body3":"Cannot live without ready meals!!"}	{"company_id":"fe46d89a-d7d8-4276-9542-aed168d130ec","title":"More ready meals","body":"<p>Cannot live without ready meals!!</p>","body2":"Cannot live without ready meals!!","body3":"Cannot live without ready meals!!"}	\N
569	889	directus_permissions	153	{"role":null,"collection":"ddb_comment","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"ddb_comment","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
570	890	directus_permissions	154	{"role":null,"collection":"ddb_company","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"ddb_company","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
571	891	directus_permissions	155	{"role":null,"collection":"ddb_feedback","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"ddb_feedback","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
572	892	directus_fields	91	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{first_name}} {{last_name}}","enableCreate":false},"collection":"ddb_feedback","field":"author_id"}	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"template":"{{first_name}} {{last_name}}","enableCreate":false},"collection":"ddb_feedback","field":"author_id"}	\N
573	893	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
574	894	directus_fields	89	{"id":89,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
575	895	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
576	896	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":4,"group":null}	\N
577	897	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":5,"group":null}	\N
578	898	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":6,"group":null}	\N
579	899	directus_fields	91	{"id":91,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}","enableCreate":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":7,"group":null}	\N
580	900	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":8,"group":null}	\N
581	901	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":9,"group":null}	\N
582	902	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":10,"group":null}	\N
583	903	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":11,"group":null}	\N
584	904	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":12,"group":null}	\N
585	905	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":13,"group":null}	\N
586	906	ddb_feedback	6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	{"id":"6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf","status":"draft","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-21T01:59:44.472Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-21T02:22:25.284Z","title":"More pet snacks","body2":"We **LOVE** pets!!!","body":"<p>We <strong>LOVE </strong>pets!!!</p>","body3":"We LOVE pets!!!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-21T02:22:25.284Z"}	\N
587	907	ddb_feedback	2b423a4f-f127-4b85-8225-90ed99d2c33f	{"id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","status":"draft","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-21T02:07:37.770Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-21T02:23:58.196Z","title":"Longer opening hours","body2":"Please open 24 hours everyday!","body":"<p>Please open 24 hours everyday!</p>","body3":"Please open 24 hours everyday!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-21T02:23:58.196Z"}	\N
588	908	ddb_feedback	55e79a9c-9f06-439d-9a70-af0876bdbd39	{"id":"55e79a9c-9f06-439d-9a70-af0876bdbd39","status":"draft","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-21T02:09:32.685Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-21T02:24:06.826Z","title":"More ready meals","body2":"Cannot live without ready meals!!","body":"<p>Cannot live without ready meals!!</p>","body3":"Cannot live without ready meals!!","company_id":"fe46d89a-d7d8-4276-9542-aed168d130ec","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-21T02:24:06.826Z"}	\N
589	909	directus_permissions	156	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_feedback","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_feedback","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
590	910	directus_permissions	157	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_comment","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_comment","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
591	911	directus_permissions	158	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_company","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_company","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
592	912	directus_permissions	159	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_feedback","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_feedback","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
593	913	ddb_feedback	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	{"company_id":"fe46d89a-d7d8-4276-9542-aed168d130ec","title":"more ice-cream during winter","body":"<p>we need ice-cream all the time</p>","body2":"we need ice-cream all the time","body3":"we need ice-cream all the time","author_id":"6aefe5e6-a952-429a-aad9-690ceb487bee"}	{"company_id":"fe46d89a-d7d8-4276-9542-aed168d130ec","title":"more ice-cream during winter","body":"<p>we need ice-cream all the time</p>","body2":"we need ice-cream all the time","body3":"we need ice-cream all the time","author_id":"6aefe5e6-a952-429a-aad9-690ceb487bee"}	\N
594	914	ddb_company	ae6c2f43-d315-4223-a869-07720a5288e0	{"name":"Ocado"}	{"name":"Ocado"}	\N
595	915	directus_fields	90	{"id":90,"collection":"ddb_company","field":"ddb_feedback","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":null,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"ddb_feedback","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":null,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
596	916	ddb_feedback	2a099a4b-f5ba-4fd5-addf-debe4972b6c3	{"company_id":"ae6c2f43-d315-4223-a869-07720a5288e0","title":"Free membership for students","body":"<p>Yes please</p>","body2":"Yes please","body3":"Yes please","author_id":"6aefe5e6-a952-429a-aad9-690ceb487bee"}	{"company_id":"ae6c2f43-d315-4223-a869-07720a5288e0","title":"Free membership for students","body":"<p>Yes please</p>","body2":"Yes please","body3":"Yes please","author_id":"6aefe5e6-a952-429a-aad9-690ceb487bee"}	\N
597	917	ddb_feedback	2604d2c1-4929-4d69-84d9-cd13972e4321	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"Bigger shopping trolley in shops","body":"<p>Existing ones are too small!</p>","body2":"Existing ones are too small!","body3":"Existing ones are too small!","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"Bigger shopping trolley in shops","body":"<p>Existing ones are too small!</p>","body2":"Existing ones are too small!","body3":"Existing ones are too small!","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	\N
598	918	ddb_company	a821325f-9b2a-4539-928d-451d8dfca2e3	{"name":"Sainsbury's"}	{"name":"Sainsbury's"}	\N
599	919	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
600	920	ddb_feedback	6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf	{"id":"6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-21T01:59:44.472Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T02:57:31.919Z","title":"More pet snacks","body2":"We **LOVE** pets!!!","body":"<p>We <strong>LOVE </strong>pets!!!</p>","body3":"We LOVE pets!!!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"status":"public","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T02:57:31.919Z"}	\N
601	921	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":{"_and":[{"status":{"_eq":"public"}},{"_or":[]},{"status":{"_eq":"private"}}]},"validation_message":null}	{"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":{"_and":[{"status":{"_eq":"public"}},{"_or":[]},{"status":{"_eq":"private"}}]},"validation_message":null}	\N
602	922	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":{"_and":[{"status":{"_eq":"public"}},{"_or":[]},{"status":{"_eq":"private"}}]},"validation_message":null}	{"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":{"_and":[{"status":{"_eq":"public"}},{"_or":[]},{"status":{"_eq":"private"}}]},"validation_message":null}	\N
603	923	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"showAsDot":true,"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
604	924	ddb_feedback	55e79a9c-9f06-439d-9a70-af0876bdbd39	{"id":"55e79a9c-9f06-439d-9a70-af0876bdbd39","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-21T02:09:32.685Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:01:28.910Z","title":"More ready meals","body2":"Cannot live without ready meals!!","body":"<p>Cannot live without ready meals!!</p>","body3":"Cannot live without ready meals!!","company_id":"fe46d89a-d7d8-4276-9542-aed168d130ec","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"status":"public","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:01:28.910Z"}	\N
605	925	ddb_feedback	2a099a4b-f5ba-4fd5-addf-debe4972b6c3	{"id":"2a099a4b-f5ba-4fd5-addf-debe4972b6c3","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-22T00:14:48.217Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:01:34.881Z","title":"Free membership for students","body2":"Yes please","body":"<p>Yes please</p>","body3":"Yes please","company_id":"ae6c2f43-d315-4223-a869-07720a5288e0","author_id":"6aefe5e6-a952-429a-aad9-690ceb487bee"}	{"status":"public","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:01:34.881Z"}	\N
606	926	ddb_feedback	2604d2c1-4929-4d69-84d9-cd13972e4321	{"id":"2604d2c1-4929-4d69-84d9-cd13972e4321","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-22T00:20:13.798Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:04:20.963Z","title":"Bigger shopping trolley in shops","body2":"Existing ones are too small!","body":"<p>Existing ones are too small!</p>","body3":"Existing ones are too small!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	{"status":"public","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:04:20.963Z"}	\N
607	927	ddb_feedback	2b423a4f-f127-4b85-8225-90ed99d2c33f	{"id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-21T02:07:37.770Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:04:37.806Z","title":"Longer opening hours","body2":"Please open 24 hours everyday!","body":"<p>Please open 24 hours everyday!</p>","body3":"Please open 24 hours everyday!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"status":"public","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:04:37.806Z"}	\N
608	928	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
709	1059	directus_permissions	166	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
609	929	ddb_feedback	9fb18710-f1d5-4cf4-8130-bf4ab399b2c5	{"id":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-22T00:11:07.267Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:05:42.838Z","title":"more ice-cream during winter","body2":"we need ice-cream all the time","body":"<p>we need ice-cream all the time</p>","body3":"we need ice-cream all the time","company_id":"fe46d89a-d7d8-4276-9542-aed168d130ec","author_id":"6aefe5e6-a952-429a-aad9-690ceb487bee"}	{"status":"public","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-22T03:05:42.838Z"}	\N
610	931	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"More doughnuts!","body":"<p>def need more doughnuts!</p>","body2":"def need more doughnuts!","body3":"def need more doughnuts!","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"More doughnuts!","body":"<p>def need more doughnuts!</p>","body2":"def need more doughnuts!","body3":"def need more doughnuts!","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	\N
611	932	ddb_feedback	5899bcf3-b9e9-4c49-8410-ad9cea183a8c	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"Please offer free car washing service....","body":"<p>... for everyone driving a white car/van!</p>","body2":"... for everyone driving a white car/van!","body3":"... for everyone driving a white car/van!","author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"company_id":"1bb4b697-845f-4d31-a352-2945cba97978","title":"Please offer free car washing service....","body":"<p>... for everyone driving a white car/van!</p>","body2":"... for everyone driving a white car/van!","body3":"... for everyone driving a white car/van!","author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
612	933	directus_fields	92	{"interface":"input","special":null,"required":true,"validation":null,"options":{"slug":true},"collection":"ddb_company","field":"slug"}	{"interface":"input","special":null,"required":true,"validation":null,"options":{"slug":true},"collection":"ddb_company","field":"slug"}	\N
613	934	directus_fields	52	{"id":52,"collection":"ddb_company","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"id","sort":1,"group":null}	\N
614	935	directus_fields	59	{"id":59,"collection":"ddb_company","field":"name","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"name","sort":2,"group":null}	\N
615	936	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","sort":3,"group":null}	\N
616	937	directus_fields	92	{"id":92,"collection":"ddb_company","field":"slug","special":null,"interface":"input","options":{"slug":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"slug","sort":4,"group":null}	\N
617	938	directus_fields	54	{"id":54,"collection":"ddb_company","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"sort","sort":5,"group":null}	\N
618	939	directus_fields	55	{"id":55,"collection":"ddb_company","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_created","sort":6,"group":null}	\N
619	940	directus_fields	56	{"id":56,"collection":"ddb_company","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_created","sort":7,"group":null}	\N
620	941	directus_fields	57	{"id":57,"collection":"ddb_company","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_updated","sort":8,"group":null}	\N
621	942	directus_fields	58	{"id":58,"collection":"ddb_company","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_updated","sort":9,"group":null}	\N
622	943	directus_fields	90	{"id":90,"collection":"ddb_company","field":"ddb_feedback","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"ddb_feedback","sort":10,"group":null}	\N
623	944	directus_fields	52	{"id":52,"collection":"ddb_company","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"id","sort":1,"group":null}	\N
710	1060	ddb_vote	9	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
624	945	directus_fields	59	{"id":59,"collection":"ddb_company","field":"name","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"name","sort":2,"group":null}	\N
625	946	directus_fields	92	{"id":92,"collection":"ddb_company","field":"slug","special":null,"interface":"input","options":{"slug":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"slug","sort":3,"group":null}	\N
626	947	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","sort":4,"group":null}	\N
627	948	directus_fields	54	{"id":54,"collection":"ddb_company","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"sort","sort":5,"group":null}	\N
628	949	directus_fields	55	{"id":55,"collection":"ddb_company","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_created","sort":6,"group":null}	\N
629	950	directus_fields	56	{"id":56,"collection":"ddb_company","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_created","sort":7,"group":null}	\N
630	951	directus_fields	57	{"id":57,"collection":"ddb_company","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_updated","sort":8,"group":null}	\N
631	952	directus_fields	58	{"id":58,"collection":"ddb_company","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_updated","sort":9,"group":null}	\N
632	953	directus_fields	90	{"id":90,"collection":"ddb_company","field":"ddb_feedback","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"ddb_feedback","sort":10,"group":null}	\N
633	954	ddb_company	1bb4b697-845f-4d31-a352-2945cba97978	{"id":"1bb4b697-845f-4d31-a352-2945cba97978","status":"active","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-20T22:54:45.769Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:01:50.084Z","name":"Tesco","slug":"tesco","ddb_feedback":["2604d2c1-4929-4d69-84d9-cd13972e4321","2b423a4f-f127-4b85-8225-90ed99d2c33f","5899bcf3-b9e9-4c49-8410-ad9cea183a8c","6bec83d0-adb0-4294-990f-4fea685d2488","6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf"]}	{"slug":"tesco","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:01:50.084Z"}	\N
634	955	ddb_company	fe46d89a-d7d8-4276-9542-aed168d130ec	{"id":"fe46d89a-d7d8-4276-9542-aed168d130ec","status":"active","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-20T22:57:02.750Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:01:55.844Z","name":"ASDA","slug":"asda","ddb_feedback":["55e79a9c-9f06-439d-9a70-af0876bdbd39","9fb18710-f1d5-4cf4-8130-bf4ab399b2c5"]}	{"slug":"asda","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:01:55.844Z"}	\N
635	956	ddb_company	a821325f-9b2a-4539-928d-451d8dfca2e3	{"id":"a821325f-9b2a-4539-928d-451d8dfca2e3","status":"active","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-22T00:52:56.713Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:02:07.562Z","name":"Sainsbury's","slug":"sainsburys","ddb_feedback":[]}	{"slug":"sainsburys","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:02:07.562Z"}	\N
636	957	ddb_company	ae6c2f43-d315-4223-a869-07720a5288e0	{"id":"ae6c2f43-d315-4223-a869-07720a5288e0","status":"active","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-22T00:12:28.073Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:02:12.762Z","name":"Ocado","slug":"ocado","ddb_feedback":["2a099a4b-f5ba-4fd5-addf-debe4972b6c3"]}	{"slug":"ocado","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-23T18:02:12.762Z"}	\N
637	958	directus_fields	93	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"enableCreate":false},"collection":"ddb_comment","field":"feedback_id"}	{"interface":"select-dropdown-m2o","special":["m2o"],"required":true,"options":{"enableCreate":false},"collection":"ddb_comment","field":"feedback_id"}	\N
638	959	directus_fields	94	{"special":["o2m"],"interface":"list-o2m","collection":"ddb_feedback","field":"o2m_comment"}	{"special":["o2m"],"interface":"list-o2m","collection":"ddb_feedback","field":"o2m_comment"}	\N
639	960	directus_fields	80	{"id":80,"collection":"ddb_comment","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"id","sort":1,"group":null}	\N
640	961	directus_fields	87	{"id":87,"collection":"ddb_comment","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"author_id","sort":2,"group":null}	\N
641	962	directus_fields	93	{"id":93,"collection":"ddb_comment","field":"feedback_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"enableCreate":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"feedback_id","sort":3,"group":null}	\N
642	963	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","sort":4,"group":null}	\N
643	964	directus_fields	82	{"id":82,"collection":"ddb_comment","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"sort","sort":5,"group":null}	\N
644	965	directus_fields	83	{"id":83,"collection":"ddb_comment","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"user_created","sort":6,"group":null}	\N
645	966	directus_fields	84	{"id":84,"collection":"ddb_comment","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"date_created","sort":7,"group":null}	\N
646	967	directus_fields	85	{"id":85,"collection":"ddb_comment","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"user_updated","sort":8,"group":null}	\N
647	968	directus_fields	86	{"id":86,"collection":"ddb_comment","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"date_updated","sort":9,"group":null}	\N
648	969	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
649	970	directus_fields	89	{"id":89,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
650	971	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
651	972	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":4,"group":null}	\N
652	973	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":5,"group":null}	\N
653	974	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":6,"group":null}	\N
654	975	directus_fields	91	{"id":91,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}","enableCreate":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":7,"group":null}	\N
711	1062	ddb_vote	10	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
655	976	directus_fields	94	{"id":94,"collection":"ddb_feedback","field":"o2m_comment","special":["o2m"],"interface":"list-o2m","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"o2m_comment","sort":8,"group":null}	\N
656	977	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":9,"group":null}	\N
657	978	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":10,"group":null}	\N
658	979	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":11,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":11,"group":null}	\N
659	980	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":12,"group":null}	\N
660	981	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":13,"group":null}	\N
661	982	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":14,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":14,"group":null}	\N
663	984	directus_fields	96	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_vote"}	{"special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_created","collection":"ddb_vote"}	\N
664	985	directus_fields	97	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_vote"}	{"special":["date-created"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_created","collection":"ddb_vote"}	\N
665	986	directus_fields	98	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_vote"}	{"special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","readonly":true,"hidden":true,"width":"half","field":"user_updated","collection":"ddb_vote"}	\N
666	987	directus_fields	99	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_vote"}	{"special":["date-updated"],"interface":"datetime","readonly":true,"hidden":true,"width":"half","display":"datetime","display_options":{"relative":true},"field":"date_updated","collection":"ddb_vote"}	\N
667	988	directus_collections	ddb_vote	{"singleton":false,"collection":"ddb_vote"}	{"singleton":false,"collection":"ddb_vote"}	\N
668	991	directus_fields	100	{"special":["m2m"],"collection":"directus_users","field":"m2m_vote"}	{"special":["m2m"],"collection":"directus_users","field":"m2m_vote"}	\N
669	992	directus_fields	101	{"hidden":true,"collection":"ddb_vote","field":"directus_users_id"}	{"hidden":true,"collection":"ddb_vote","field":"directus_users_id"}	\N
670	993	directus_fields	102	{"hidden":true,"collection":"ddb_vote","field":"ddb_feedback_id"}	{"hidden":true,"collection":"ddb_vote","field":"ddb_feedback_id"}	\N
671	994	directus_fields	103	{"special":["m2m"],"collection":"directus_users","field":"m2m_feedback"}	{"special":["m2m"],"collection":"directus_users","field":"m2m_feedback"}	\N
672	995	directus_fields	104	{"special":["m2m"],"interface":"list-m2m","collection":"ddb_feedback","field":"m2m_user"}	{"special":["m2m"],"interface":"list-m2m","collection":"ddb_feedback","field":"m2m_user"}	\N
673	996	directus_fields	105	{"special":["m2m"],"hidden":true,"collection":"ddb_feedback","field":"m2m_voted_by"}	{"special":["m2m"],"hidden":true,"collection":"ddb_feedback","field":"m2m_voted_by"}	\N
674	997	directus_fields	106	{"special":["m2m"],"interface":"list-m2m","collection":"directus_users","field":"m2m_voted_for"}	{"special":["m2m"],"interface":"list-m2m","collection":"directus_users","field":"m2m_voted_for"}	\N
675	998	directus_fields	107	{"hidden":true,"collection":"ddb_vote","field":"voted_for"}	{"hidden":true,"collection":"ddb_vote","field":"voted_for"}	\N
676	999	directus_fields	108	{"hidden":true,"collection":"ddb_vote","field":"voted_by"}	{"hidden":true,"collection":"ddb_vote","field":"voted_by"}	\N
677	1000	ddb_vote	1	\N	\N	\N
678	1001	ddb_vote	2	\N	\N	\N
679	1004	directus_fields	95	{"id":95,"collection":"ddb_vote","field":"id","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"id","sort":1,"group":null}	\N
680	1005	directus_fields	107	{"id":107,"collection":"ddb_vote","field":"voted_for","special":null,"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"voted_for","sort":2,"group":null}	\N
681	1006	directus_fields	96	{"id":96,"collection":"ddb_vote","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":3,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"user_created","sort":3,"group":null}	\N
682	1007	directus_fields	97	{"id":97,"collection":"ddb_vote","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":4,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"date_created","sort":4,"group":null}	\N
683	1008	directus_fields	98	{"id":98,"collection":"ddb_vote","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":5,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"user_updated","sort":5,"group":null}	\N
684	1009	directus_fields	99	{"id":99,"collection":"ddb_vote","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"date_updated","sort":6,"group":null}	\N
685	1010	directus_fields	108	{"id":108,"collection":"ddb_vote","field":"voted_by","special":null,"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"voted_by","sort":7,"group":null}	\N
686	1011	directus_fields	95	{"id":95,"collection":"ddb_vote","field":"id","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"id","sort":1,"group":null}	\N
687	1012	directus_fields	107	{"id":107,"collection":"ddb_vote","field":"voted_for","special":null,"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"voted_for","sort":2,"group":null}	\N
688	1013	directus_fields	108	{"id":108,"collection":"ddb_vote","field":"voted_by","special":null,"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"voted_by","sort":3,"group":null}	\N
689	1014	directus_fields	96	{"id":96,"collection":"ddb_vote","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":4,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"user_created","sort":4,"group":null}	\N
690	1015	directus_fields	97	{"id":97,"collection":"ddb_vote","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":5,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"date_created","sort":5,"group":null}	\N
691	1016	directus_fields	98	{"id":98,"collection":"ddb_vote","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":6,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"user_updated","sort":6,"group":null}	\N
692	1017	directus_fields	99	{"id":99,"collection":"ddb_vote","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"date_updated","sort":7,"group":null}	\N
693	1018	directus_fields	107	{"id":107,"collection":"ddb_vote","field":"voted_for","special":null,"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"voted_for","hidden":false}	\N
694	1019	directus_fields	108	{"id":108,"collection":"ddb_vote","field":"voted_by","special":null,"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_vote","field":"voted_by","hidden":false}	\N
695	1020	directus_permissions	160	{"role":null,"collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":null,"collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
696	1022	ddb_vote	3	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	\N
697	1023	ddb_vote	3	{"id":"3","user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-25T02:28:12.588Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-25T02:29:21.106Z","voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	{"voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-02-25T02:29:21.106Z"}	\N
698	1024	directus_permissions	161	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a2a22e06-e905-4a8e-a3a2-4abf257469e9","collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
699	1039	ddb_vote	4	{"voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5"}	{"voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5"}	\N
700	1041	ddb_vote	5	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a"}	\N
701	1043	ddb_vote	6	{"voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5"}	{"voted_by":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5"}	\N
702	1049	directus_permissions	162	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
703	1050	directus_permissions	163	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_comment","action":"create","fields":["*"],"permissions":{},"validation":{}}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_comment","action":"create","fields":["*"],"permissions":{},"validation":{}}	\N
704	1051	ddb_vote	7	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
705	1052	directus_permissions	164	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"delete"}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"delete"}	\N
706	1053	directus_permissions	164	{"id":164,"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"delete","permissions":{},"validation":{},"presets":null,"fields":["*"]}	{"permissions":{},"validation":{},"fields":["*"]}	\N
707	1054	directus_permissions	165	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	{"role":"a257a32a-b4d2-4782-a145-0200d277d527","collection":"ddb_vote","action":"read","fields":["*"],"permissions":{},"validation":{}}	\N
708	1056	ddb_vote	8	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
717	1074	ddb_vote	16	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
718	1076	ddb_vote	17	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
719	1078	ddb_vote	18	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
720	1080	ddb_vote	19	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
721	1082	ddb_vote	20	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
722	1084	ddb_vote	21	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
723	1086	ddb_vote	22	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
724	1088	ddb_vote	23	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
725	1090	ddb_vote	24	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
726	1092	ddb_vote	25	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
727	1094	ddb_vote	26	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
728	1096	ddb_vote	27	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
729	1098	ddb_vote	28	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
730	1100	ddb_vote	29	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
731	1102	ddb_vote	30	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
732	1104	ddb_vote	31	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
733	1106	ddb_vote	32	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2604d2c1-4929-4d69-84d9-cd13972e4321","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
734	1107	ddb_vote	33	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
735	1110	ddb_vote	34	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
736	1118	ddb_vote	35	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
737	1120	ddb_vote	36	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
738	1121	ddb_vote	37	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
739	1123	ddb_vote	38	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
740	1124	ddb_vote	39	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
741	1130	directus_fields	109	{"interface":"input-rich-text-html","special":null,"required":true,"collection":"ddb_comment","field":"content"}	{"interface":"input-rich-text-html","special":null,"required":true,"collection":"ddb_comment","field":"content"}	\N
742	1131	directus_fields	80	{"id":80,"collection":"ddb_comment","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"id","sort":1,"group":null}	\N
743	1132	directus_fields	87	{"id":87,"collection":"ddb_comment","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"author_id","sort":2,"group":null}	\N
744	1133	directus_fields	93	{"id":93,"collection":"ddb_comment","field":"feedback_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"enableCreate":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"feedback_id","sort":3,"group":null}	\N
745	1134	directus_fields	109	{"id":109,"collection":"ddb_comment","field":"content","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"content","sort":4,"group":null}	\N
746	1135	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"$t:published","value":"published"},{"text":"$t:draft","value":"draft"},{"text":"$t:archived","value":"archived"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","sort":5,"group":null}	\N
747	1136	directus_fields	82	{"id":82,"collection":"ddb_comment","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"sort","sort":6,"group":null}	\N
748	1137	directus_fields	83	{"id":83,"collection":"ddb_comment","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"user_created","sort":7,"group":null}	\N
749	1138	directus_fields	84	{"id":84,"collection":"ddb_comment","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"date_created","sort":8,"group":null}	\N
750	1139	directus_fields	85	{"id":85,"collection":"ddb_comment","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"user_updated","sort":9,"group":null}	\N
751	1140	directus_fields	86	{"id":86,"collection":"ddb_comment","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"date_updated","sort":10,"group":null}	\N
752	1141	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
753	1142	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
771	1169	directus_fields	90	{"id":90,"collection":"ddb_company","field":"ddb_feedback","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"ddb_feedback","sort":3,"group":null}	\N
772	1170	directus_fields	92	{"id":92,"collection":"ddb_company","field":"slug","special":null,"interface":"input","options":{"slug":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"slug","sort":4,"group":null}	\N
754	1143	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"$t:published","value":"published","foreground":"#FFFFFF","background":"var(--primary)"},{"text":"$t:draft","value":"draft","foreground":"#18222F","background":"#D3DAE4"},{"text":"$t:archived","value":"archived","foreground":"#FFFFFF","background":"var(--warning)"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
755	1144	ddb_comment	e5279992-8fb4-463d-add6-e5822c64452b	{"author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5","feedback_id":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","content":"<p>Great idea!</p>"}	{"author_id":"15b505d3-5248-4766-b271-fcdf176a5ef5","feedback_id":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","content":"<p>Great idea!</p>"}	\N
756	1146	ddb_comment	3dd9f793-0980-4847-9747-7d4a45c2a207	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"yes please, i can go anytime"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"yes please, i can go anytime"}	\N
757	1147	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"showAsDot":true,"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
758	1148	directus_fields	81	{"id":81,"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_comment","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
759	1150	ddb_comment	b751b9d6-86d9-45e6-a1b1-80bf3d5c2afa	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"i'd love that!"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"i'd love that!"}	\N
760	1152	ddb_vote	40	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
761	1153	ddb_comment	17d9c74d-61e5-4553-8dd4-aed87611c0aa	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"Thumbs up!"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"Thumbs up!"}	\N
762	1155	ddb_vote	41	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
763	1157	ddb_vote	42	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
764	1159	ddb_vote	43	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
765	1161	ddb_vote	44	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
766	1163	ddb_vote	45	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2b423a4f-f127-4b85-8225-90ed99d2c33f","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
767	1164	ddb_vote	46	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
768	1166	ddb_vote	47	{"voted_for":"6bec83d0-adb0-4294-990f-4fea685d2488","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"6bec83d0-adb0-4294-990f-4fea685d2488","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
769	1167	directus_fields	52	{"id":52,"collection":"ddb_company","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"id","sort":1,"group":null}	\N
770	1168	directus_fields	59	{"id":59,"collection":"ddb_company","field":"name","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"name","sort":2,"group":null}	\N
773	1171	directus_fields	53	{"id":53,"collection":"ddb_company","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"active","value":"active"},{"text":"suspended","value":"suspended"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"status","sort":5,"group":null}	\N
774	1172	directus_fields	54	{"id":54,"collection":"ddb_company","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"sort","sort":6,"group":null}	\N
775	1173	directus_fields	55	{"id":55,"collection":"ddb_company","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":7,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_created","sort":7,"group":null}	\N
776	1174	directus_fields	56	{"id":56,"collection":"ddb_company","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":8,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_created","sort":8,"group":null}	\N
777	1175	directus_fields	57	{"id":57,"collection":"ddb_company","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"user_updated","sort":9,"group":null}	\N
778	1176	directus_fields	58	{"id":58,"collection":"ddb_company","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":10,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"date_updated","sort":10,"group":null}	\N
779	1177	ddb_comment	8fce529f-a30c-4d18-b70e-0b8cb3c22bea	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"dfsdf"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2b423a4f-f127-4b85-8225-90ed99d2c33f","content":"dfsdf"}	\N
780	1179	directus_fields	94	{"id":94,"collection":"ddb_feedback","field":"o2m_comment","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"o2m_comment","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
781	1180	directus_fields	92	{"id":92,"collection":"ddb_company","field":"slug","special":null,"interface":"input","options":{"slug":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_company","field":"slug","special":null,"interface":"input","options":{"slug":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	\N
782	1185	ddb_vote	48	{"voted_for":"6bec83d0-adb0-4294-990f-4fea685d2488","voted_by":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"voted_for":"6bec83d0-adb0-4294-990f-4fea685d2488","voted_by":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	\N
783	1186	ddb_vote	49	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	{"voted_for":"9fb18710-f1d5-4cf4-8130-bf4ab399b2c5","voted_by":"15b505d3-5248-4766-b271-fcdf176a5ef5"}	\N
784	1187	ddb_feedback	5899bcf3-b9e9-4c49-8410-ad9cea183a8c	{"id":"5899bcf3-b9e9-4c49-8410-ad9cea183a8c","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-23T02:46:46.516Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-02T00:45:42.550Z","title":"Please offer free car washing service while shopping","body2":"... for everyone driving a white car/van!","body":"<p>... for everyone driving a white car/van!</p>","body3":"... for everyone driving a white car/van!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","o2m_comment":[],"m2m_voted_by":[]}	{"title":"Please offer free car washing service while shopping","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-02T00:45:42.550Z"}	\N
785	1190	directus_fields	110	{"interface":"input-rich-text-html","special":null,"required":true,"collection":"ddb_feedback","field":"content"}	{"interface":"input-rich-text-html","special":null,"required":true,"collection":"ddb_feedback","field":"content"}	\N
786	1191	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
787	1192	directus_fields	89	{"id":89,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
788	1193	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
789	1194	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":4,"group":null}	\N
790	1195	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":5,"group":null}	\N
791	1196	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":6,"group":null}	\N
792	1197	directus_fields	91	{"id":91,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}","enableCreate":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":7,"group":null}	\N
793	1198	directus_fields	110	{"id":110,"collection":"ddb_feedback","field":"content","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"content","sort":8,"group":null}	\N
794	1199	directus_fields	94	{"id":94,"collection":"ddb_feedback","field":"o2m_comment","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"o2m_comment","sort":9,"group":null}	\N
795	1200	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":10,"group":null}	\N
796	1201	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":11,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":11,"group":null}	\N
797	1202	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":12,"group":null}	\N
798	1203	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":13,"group":null}	\N
799	1204	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":14,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":14,"group":null}	\N
800	1205	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":15,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":15,"group":null}	\N
801	1206	directus_fields	105	{"id":105,"collection":"ddb_feedback","field":"m2m_voted_by","special":["m2m"],"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":16,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"m2m_voted_by","sort":16,"group":null}	\N
802	1207	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
803	1208	directus_fields	89	{"id":89,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
804	1209	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
805	1210	directus_fields	110	{"id":110,"collection":"ddb_feedback","field":"content","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"content","sort":4,"group":null}	\N
806	1211	directus_fields	74	{"id":74,"collection":"ddb_feedback","field":"body","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body","sort":5,"group":null}	\N
807	1212	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":6,"group":null}	\N
808	1213	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":7,"group":null}	\N
809	1214	directus_fields	91	{"id":91,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}","enableCreate":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":8,"group":null}	\N
810	1215	directus_fields	94	{"id":94,"collection":"ddb_feedback","field":"o2m_comment","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"o2m_comment","sort":9,"group":null}	\N
811	1216	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":10,"group":null}	\N
812	1217	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":11,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":11,"group":null}	\N
813	1218	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":12,"group":null}	\N
814	1219	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":13,"group":null}	\N
815	1220	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":14,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":14,"group":null}	\N
816	1221	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":15,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":15,"group":null}	\N
817	1222	directus_fields	105	{"id":105,"collection":"ddb_feedback","field":"m2m_voted_by","special":["m2m"],"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":16,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"m2m_voted_by","sort":16,"group":null}	\N
818	1223	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	{"id":"6bec83d0-adb0-4294-990f-4fea685d2488","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-23T02:39:24.188Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-02T03:11:33.289Z","title":"More doughnuts!","body2":"def need more doughnuts!\\n<script>alert('fortunately, this will not work!')</script>","body":"<p>def need more doughnuts!</p>","body3":"def need more doughnuts!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","content":"<p>def need more doughnuts!</p>\\n<p><code>&lt;script&gt;alert('fortunately, this will not work!')&lt;/script&gt;</code></p>","o2m_comment":[],"m2m_voted_by":["47","48"]}	{"body2":"def need more doughnuts!\\n<script>alert('fortunately, this will not work!')</script>","content":"<p>def need more doughnuts!</p>\\n<p><code>&lt;script&gt;alert('fortunately, this will not work!')&lt;/script&gt;</code></p>","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-02T03:11:33.289Z"}	\N
819	1224	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	{"id":"6bec83d0-adb0-4294-990f-4fea685d2488","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-23T02:39:24.188Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-02T03:12:13.772Z","title":"More doughnuts!","body2":"def need more doughnuts!\\n<script>alert('fortunately, this will not work!')</script>","body":"<p>def need more doughnuts!</p>","body3":"def need more doughnuts!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","content":"<p>def need more doughnuts!</p>\\n<p><code></code></p>","o2m_comment":[],"m2m_voted_by":["47","48"]}	{"content":"<p>def need more doughnuts!</p>\\n<p><code></code></p>","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-02T03:12:13.772Z"}	\N
820	1229	ddb_comment	1cfd0c59-5bc8-4793-b434-4c52b199357b	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2604d2c1-4929-4d69-84d9-cd13972e4321","content":"more shopping yay!"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2604d2c1-4929-4d69-84d9-cd13972e4321","content":"more shopping yay!"}	\N
821	1230	ddb_comment	5a941db1-d769-4053-b169-1d3b9752be43	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2604d2c1-4929-4d69-84d9-cd13972e4321","content":"i like it!"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","feedback_id":"2604d2c1-4929-4d69-84d9-cd13972e4321","content":"i like it!"}	\N
822	1231	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
823	1232	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	\N
824	1233	ddb_feedback	c9888177-d211-46b1-ab0f-dd85b5ae34aa	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","title":"Birthday discounts","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","content":"for all under 18s"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","title":"Birthday discounts","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","content":"for all under 18s"}	\N
825	1234	ddb_feedback	f2cc582f-5303-42f3-bc02-c7c09897be25	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","title":"test","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","content":"tttttt"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","title":"test","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","content":"tttttt"}	\N
826	1235	ddb_feedback	a6e26ad4-d06c-42d0-9c03-220a42645c5c	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","title":"t2","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","content":"ttttsdfdsffds"}	{"author_id":"cab90e35-563a-4aea-a129-bb7d3d149f9f","title":"t2","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","content":"ttttsdfdsffds"}	\N
827	1239	ddb_vote	50	{"voted_for":"6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"6e9ebc85-05c0-4c68-9ed5-9b0d53c12eaf","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
828	1240	ddb_vote	51	{"voted_for":"2a099a4b-f5ba-4fd5-addf-debe4972b6c3","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"2a099a4b-f5ba-4fd5-addf-debe4972b6c3","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
829	1242	directus_fields	65	{"id":65,"collection":"ddb_feedback","field":"id","special":["uuid"],"interface":"input","options":null,"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":1,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"id","sort":1,"group":null}	\N
830	1243	directus_fields	89	{"id":89,"collection":"ddb_feedback","field":"company_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{name}}"},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":2,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"company_id","sort":2,"group":null}	\N
831	1244	directus_fields	72	{"id":72,"collection":"ddb_feedback","field":"title","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":3,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"title","sort":3,"group":null}	\N
832	1245	directus_fields	110	{"id":110,"collection":"ddb_feedback","field":"content","special":null,"interface":"input-rich-text-html","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":4,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"content","sort":4,"group":null}	\N
833	1246	directus_fields	73	{"id":73,"collection":"ddb_feedback","field":"body2","special":null,"interface":"input-rich-text-md","options":null,"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":5,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body2","sort":5,"group":null}	\N
834	1247	directus_fields	79	{"id":79,"collection":"ddb_feedback","field":"body3","special":null,"interface":"input-multiline","options":{"trim":true},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":6,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"body3","sort":6,"group":null}	\N
835	1248	directus_fields	91	{"id":91,"collection":"ddb_feedback","field":"author_id","special":["m2o"],"interface":"select-dropdown-m2o","options":{"template":"{{first_name}} {{last_name}}","enableCreate":false},"display":null,"display_options":null,"readonly":false,"hidden":false,"sort":7,"width":"full","translations":null,"note":null,"conditions":null,"required":true,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"author_id","sort":7,"group":null}	\N
836	1249	directus_fields	94	{"id":94,"collection":"ddb_feedback","field":"o2m_comment","special":["o2m"],"interface":"list-o2m","options":{"enableCreate":false,"enableSelect":false},"display":null,"display_options":null,"readonly":true,"hidden":true,"sort":8,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"o2m_comment","sort":8,"group":null}	\N
837	1250	directus_fields	105	{"id":105,"collection":"ddb_feedback","field":"m2m_voted_by","special":["m2m"],"interface":null,"options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":9,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"m2m_voted_by","sort":9,"group":null}	\N
838	1251	directus_fields	66	{"id":66,"collection":"ddb_feedback","field":"status","special":null,"interface":"select-dropdown","options":{"choices":[{"text":"public","value":"public"},{"text":"private","value":"private"}]},"display":"labels","display_options":{"choices":null},"readonly":false,"hidden":false,"sort":10,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"status","sort":10,"group":null}	\N
839	1252	directus_fields	67	{"id":67,"collection":"ddb_feedback","field":"sort","special":null,"interface":"input","options":null,"display":null,"display_options":null,"readonly":false,"hidden":true,"sort":11,"width":"full","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"sort","sort":11,"group":null}	\N
840	1253	directus_fields	68	{"id":68,"collection":"ddb_feedback","field":"user_created","special":["user-created"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":12,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_created","sort":12,"group":null}	\N
841	1254	directus_fields	69	{"id":69,"collection":"ddb_feedback","field":"date_created","special":["date-created"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":13,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_created","sort":13,"group":null}	\N
842	1255	directus_fields	70	{"id":70,"collection":"ddb_feedback","field":"user_updated","special":["user-updated"],"interface":"select-dropdown-m2o","options":{"template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"},"display":"user","display_options":null,"readonly":true,"hidden":true,"sort":14,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"user_updated","sort":14,"group":null}	\N
843	1256	directus_fields	71	{"id":71,"collection":"ddb_feedback","field":"date_updated","special":["date-updated"],"interface":"datetime","options":null,"display":"datetime","display_options":{"relative":true},"readonly":true,"hidden":true,"sort":15,"width":"half","translations":null,"note":null,"conditions":null,"required":false,"group":null,"validation":null,"validation_message":null}	{"collection":"ddb_feedback","field":"date_updated","sort":15,"group":null}	\N
844	1259	ddb_vote	52	{"voted_for":"55e79a9c-9f06-439d-9a70-af0876bdbd39","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"55e79a9c-9f06-439d-9a70-af0876bdbd39","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
845	1260	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	{"id":"6bec83d0-adb0-4294-990f-4fea685d2488","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-23T02:39:24.188Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-05T15:27:13.346Z","title":"More doughnuts!","body2":"def need more doughnuts!\\n<script>alert('fortunately, this will not work!')</script>","body3":"def need more doughnuts!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","content":"<p>defo need more doughnuts!</p>\\n<p>and gingerbread biscuits!</p>","o2m_comment":[],"m2m_voted_by":["47","48"]}	{"content":"<p>defo need more doughnuts!</p>\\n<p>and gingerbread biscuits!</p>","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-05T15:27:13.346Z"}	\N
846	1261	ddb_feedback	6bec83d0-adb0-4294-990f-4fea685d2488	{"id":"6bec83d0-adb0-4294-990f-4fea685d2488","status":"public","sort":null,"user_created":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_created":"2023-02-23T02:39:24.188Z","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-05T15:28:28.021Z","title":"More doughnuts!","body2":"def need more doughnuts!\\n<script>alert('fortunately, this will not work!')</script>","body3":"def need more doughnuts!","company_id":"1bb4b697-845f-4d31-a352-2945cba97978","author_id":"aad86e98-7c2e-4157-a7bc-3828ef1a705a","content":"<p>defo need more doughnuts!</p>\\n<p>and gingerbread biscuits!</p>\\n<p>and cookies!</p>","o2m_comment":[],"m2m_voted_by":["47","48"]}	{"content":"<p>defo need more doughnuts!</p>\\n<p>and gingerbread biscuits!</p>\\n<p>and cookies!</p>","user_updated":"96b1e708-8f8d-4d52-aed9-d46577cc6fa1","date_updated":"2023-03-05T15:28:28.021Z"}	\N
847	1263	ddb_vote	53	{"voted_for":"c9888177-d211-46b1-ab0f-dd85b5ae34aa","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	{"voted_for":"c9888177-d211-46b1-ab0f-dd85b5ae34aa","voted_by":"cab90e35-563a-4aea-a129-bb7d3d149f9f"}	\N
\.


--
-- Data for Name: directus_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_roles (id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access) FROM stdin;
e9cc001b-b4f1-4096-bf59-b7572b19d012	Administrator	verified	$t:admin_description	\N	f	t	t
a2a22e06-e905-4a8e-a3a2-4abf257469e9	API user	supervised_user_circle	\N	\N	f	f	t
a257a32a-b4d2-4782-a145-0200d277d527	webuser	supervised_user_circle	\N	\N	f	f	t
\.


--
-- Data for Name: directus_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_sessions (token, "user", expires, ip, user_agent, share, origin) FROM stdin;
mdqfQOKo5KFgTffMqVvKYOmXC9HwntjbtJ1yYW-k2Jss8A9YJJFhn6Sxp8tz_GDV	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-09 05:07:59.388+00	172.22.0.1	axios/0.27.2	\N	\N
YhifiM5XrKHCGicMc_QqQFKWBs_OGPGknef6TnkBeCuSqtbsH2efTFG1i4rcoBUI	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-08 22:12:28.959+00	172.22.0.1	axios/0.27.2	\N	\N
bB_QoxlLOCrPeo_Y4YVrl4E505g4g7CYorf8Ep3WyqGo9PbAWSiPPK9YSe133vla	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-07 04:31:40.337+00	172.22.0.1	axios/0.27.2	\N	\N
LDJUf6jWr7GEMe2lMGCaYyyym8BBnV3LwlJtb_E2MqT9OBqcmqExSuDrAwTp2dmT	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-07 06:40:37.905+00	172.22.0.1	axios/0.27.2	\N	\N
3Tfp6j1KR4uAqqiKsJlX0SGMGkmOs-AH9rgQPYIaVeBvLoMrqEvSQcLegF_UCzTU	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-09 16:17:43.924+00	172.22.0.1	axios/0.27.2	\N	\N
xKzWeQsqTkotZ6EnWdl_7iGOmH-w_P7JFuVedWdRnagksal4fakFjjEW8sJvRBYj	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-13 00:08:41.005+00	172.24.0.1	axios/0.27.2	\N	\N
gW_y5l_9TK8TY34YC_sz4830Mx-JGe71SplI74aFr1T1x0STSFXpEQI56av4l3l1	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-11 15:34:04.231+00	172.24.0.1	axios/0.27.2	\N	\N
sxHjsZqgyjBWHt4tVHZOeTkwBtJQ0Zlz5Ys-VlKZ1zsX8rSuOeOUogmcXul1FjBA	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-07 01:30:03.202+00	172.22.0.1	axios/0.27.2	\N	\N
V-X5fG8adWm8eM3DfcuJwx-jHf3PyS3RTQ-dUy97yqUmv91921Yt-cJIEHkvqkBy	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-06 00:28:43.709+00	81.92.200.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	\N	http://uk1.descafe.com:8055
kA_TO345fVmTqK8dvAGZBCMvKqgrVzJ457AywNpKxbONvuLKkMeAO-sArTT4iXIw	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-09 02:00:33.42+00	172.22.0.1	axios/0.27.2	\N	\N
Bf7L3sqMssyQYwW0Fx61OW-cueKUnxbGoNZNHKXGAJ_sdBgyA_fprJpxX3rBolwJ	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-10 02:21:38.122+00	172.22.0.1	axios/0.27.2	\N	\N
9yPBd9zbSMJaLtGZmEl-N_NHXXFKBlN0Ux5xj4X54xpqXaX8_qTYPFzyMbyJ3gj4	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-12 05:15:04.269+00	172.24.0.1	axios/0.27.2	\N	\N
Jz5cU_evM3Wcp5MQjb5sRc_lh6oaLivdJu2W9Qk6mdB2iqGTZIWOk4p7TSM8zWvb	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-06 19:22:37.892+00	172.22.0.1	axios/0.27.2	\N	\N
bCAtcp_Vgam25vzM9sJcSzLjEFmCuw6fXmodJPEUxfE3BqMcycqHZCGGfTOIiZ0D	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-08 03:39:33.883+00	172.22.0.1	axios/0.27.2	\N	\N
16aC6T9SM7AlkXIvbRIYcamUcXDlKa4s9EteXvBq2ECAk3IFDAE2I6-CJGSjpTQj	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-08 05:02:33.495+00	172.22.0.1	axios/0.27.2	\N	\N
XcZufpbH4KKSaRG9Dcflt0CS8tGBUKXfL_Pw61LoShgVbEcp4inQqOMHpIqZszQj	96b1e708-8f8d-4d52-aed9-d46577cc6fa1	2023-03-13 21:03:08.396+00	81.92.200.59	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/110.0	\N	http://uk1.descafe.com:8055
7c_5sDVzB_lEZTXKuYZbftjdFIvFAXD-lEmtoCKBCFO_N4-GbuqybitXF972CpT-	cab90e35-563a-4aea-a129-bb7d3d149f9f	2023-03-10 19:41:16.092+00	172.22.0.1	axios/0.27.2	\N	\N
uMoA88iZKlBeIohFz0UHNc191OAc6o0CaTQ3UZJtJm6eCl6I2jh8m1kUxTDNdfiy	15b505d3-5248-4766-b271-fcdf176a5ef5	2023-03-09 00:15:53.871+00	172.22.0.1	axios/0.27.2	\N	\N
\.


--
-- Data for Name: directus_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_settings (id, project_name, project_url, project_color, project_logo, public_foreground, public_background, public_note, auth_login_attempts, auth_password_policy, storage_asset_transform, storage_asset_presets, custom_css, storage_default_folder, basemaps, mapbox_key, module_bar, project_descriptor, translation_strings, default_language, custom_aspect_ratios) FROM stdin;
1	GetMAS	\N	\N	\N	\N	\N	\N	25	\N	all	\N	\N	\N	\N	\N	[{"type":"module","id":"content","enabled":true},{"type":"module","id":"users","enabled":true},{"type":"module","id":"files","enabled":true},{"type":"module","id":"insights","enabled":true},{"type":"module","id":"docs","enabled":true},{"type":"module","id":"settings","enabled":true,"locked":true},{"type":"module","id":"generate-types","enabled":true}]	\N	\N	en-US	\N
\.


--
-- Data for Name: directus_shares; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_shares (id, name, collection, item, role, password, user_created, date_created, date_start, date_end, times_used, max_uses) FROM stdin;
\.


--
-- Data for Name: directus_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_users (id, first_name, last_name, email, password, location, title, description, tags, avatar, language, theme, tfa_secret, status, role, token, last_access, last_page, provider, external_identifier, auth_data, email_notifications) FROM stdin;
6aefe5e6-a952-429a-aad9-690ceb487bee	Eve	webuser 5	eve@test.com	$argon2id$v=19$m=65536,t=3,p=4$RiCYvF7loFe/cyUam3uSMw$H1t/cYvqWwaTyeCoaco1SyHYrLHoMOxRkBuWABu8LTI	\N	\N	\N	\N	\N	\N	auto	\N	active	a257a32a-b4d2-4782-a145-0200d277d527	\N	2023-02-20 03:56:15.878+00	\N	default	\N	\N	t
aad86e98-7c2e-4157-a7bc-3828ef1a705a	Bob	WebUser1	bob@test.com	$argon2id$v=19$m=65536,t=3,p=4$FbwG24iKN0GqX8VlRy1lbw$bL6yXfM3pOiZAMTQbnt2EZRrWnq36rG7JTvCjCJYK+A	\N	\N	\N	\N	\N	\N	auto	\N	active	a257a32a-b4d2-4782-a145-0200d277d527	\N	2023-02-27 18:34:51.813+00	\N	default	\N	\N	f
6a85a60f-5e1e-443a-b698-f7dc396583b9	cat	webuser3	cat@test.com	$argon2id$v=19$m=65536,t=3,p=4$xUmP0oYaY6zLae8JrKX5aA$KIALU3gEPkCvprUE3c991O7G7J2SJGsV1sgc4krBIu0	\N	\N	\N	\N	\N	\N	auto	\N	suspended	a257a32a-b4d2-4782-a145-0200d277d527	\N	2023-01-29 21:19:23.474+00	\N	default	\N	\N	t
aaa1b7cb-2f23-4e92-828a-a90946b50992	remix_api	\N	remix_api@test.com	$argon2id$v=19$m=65536,t=3,p=4$i+NMaIsGt7QZFJVHsUJOSA$gW2aeHqiZ32rXxpmeL2gAA0HzVQL19QcXdPYzqtzzB4	\N	\N	\N	\N	\N	\N	auto	\N	active	a2a22e06-e905-4a8e-a3a2-4abf257469e9	aiQs8IOwDEaHCGYVP4aGO85tM4LJgsSI	\N	\N	default	\N	\N	t
96b1e708-8f8d-4d52-aed9-d46577cc6fa1	Admin	User	admin@test.com	$argon2id$v=19$m=65536,t=3,p=4$isLA7/isD3A3DBzg82t0uw$48ZMfDMcGM889AQS5oPgjrlCszLrR9ve5yUCzCle0gg	\N	\N	\N	\N	\N	\N	auto	\N	active	e9cc001b-b4f1-4096-bf59-b7572b19d012	\N	2023-03-06 21:03:08.437+00	/content/ddb_feedback	default	\N	\N	t
b53e2997-c47d-4507-88b6-b742652db504	API User 1	\N	apiuser1@test.com	$argon2id$v=19$m=65536,t=3,p=4$pHDsSATOjhSSHcpUcnXZ6w$Ed9RQtSR8Qyp4jj2m9QBBNHpwQfH/8K4219baUSuli8	\N	\N	\N	\N	\N	\N	auto	\N	active	a2a22e06-e905-4a8e-a3a2-4abf257469e9	h5nAp5r7MzWkL4OjhhDpamlK8ozfjGxJ	2023-01-27 03:04:00.78+00	/users	default	\N	\N	f
15b505d3-5248-4766-b271-fcdf176a5ef5	dave	webuser4	dave@test.com	$argon2id$v=19$m=65536,t=3,p=4$4FGRw8Nbusf9ytVea6GGsA$HDUrqpPSbQEBi9v/JhGjMlCpENTHInWd04VMmadlDPk	\N	\N	\N	\N	\N	\N	auto	\N	active	a257a32a-b4d2-4782-a145-0200d277d527	\N	2023-03-02 02:00:33.504+00	\N	default	\N	\N	t
cab90e35-563a-4aea-a129-bb7d3d149f9f	Amy	WebUser2	amy@test.com	$argon2id$v=19$m=65536,t=3,p=4$L4IVHzLJW2p3K+n94Vhk4w$HIKvrzfFVviLCeC76HL0RE3i7vnorl+izyUDubejPmk	\N	\N	\N	\N	\N	\N	auto	\N	active	a257a32a-b4d2-4782-a145-0200d277d527	\N	2023-03-06 00:08:41.04+00	\N	default	\N	\N	f
\.


--
-- Data for Name: directus_webhooks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.directus_webhooks (id, name, method, url, status, data, actions, collections, headers) FROM stdin;
\.


--
-- Name: ddb_vote_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ddb_vote_id_seq', 53, true);


--
-- Name: directus_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_activity_id_seq', 1264, true);


--
-- Name: directus_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_fields_id_seq', 110, true);


--
-- Name: directus_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_notifications_id_seq', 1, false);


--
-- Name: directus_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_permissions_id_seq', 166, true);


--
-- Name: directus_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_presets_id_seq', 9, true);


--
-- Name: directus_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_relations_id_seq', 35, true);


--
-- Name: directus_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_revisions_id_seq', 847, true);


--
-- Name: directus_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_settings_id_seq', 1, true);


--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.directus_webhooks_id_seq', 1, false);


--
-- Name: ddb_comment ddb_comment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_comment
    ADD CONSTRAINT ddb_comment_pkey PRIMARY KEY (id);


--
-- Name: ddb_company ddb_company_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_company
    ADD CONSTRAINT ddb_company_pkey PRIMARY KEY (id);


--
-- Name: ddb_company ddb_company_slug_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_company
    ADD CONSTRAINT ddb_company_slug_unique UNIQUE (slug);


--
-- Name: ddb_feedback ddb_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_feedback
    ADD CONSTRAINT ddb_feedback_pkey PRIMARY KEY (id);


--
-- Name: ddb_vote ddb_vote_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_vote
    ADD CONSTRAINT ddb_vote_pkey PRIMARY KEY (id);


--
-- Name: directus_activity directus_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_activity
    ADD CONSTRAINT directus_activity_pkey PRIMARY KEY (id);


--
-- Name: directus_collections directus_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_collections
    ADD CONSTRAINT directus_collections_pkey PRIMARY KEY (collection);


--
-- Name: directus_dashboards directus_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_dashboards
    ADD CONSTRAINT directus_dashboards_pkey PRIMARY KEY (id);


--
-- Name: directus_fields directus_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_fields
    ADD CONSTRAINT directus_fields_pkey PRIMARY KEY (id);


--
-- Name: directus_files directus_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_pkey PRIMARY KEY (id);


--
-- Name: directus_flows directus_flows_operation_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_flows
    ADD CONSTRAINT directus_flows_operation_unique UNIQUE (operation);


--
-- Name: directus_flows directus_flows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_flows
    ADD CONSTRAINT directus_flows_pkey PRIMARY KEY (id);


--
-- Name: directus_folders directus_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_folders
    ADD CONSTRAINT directus_folders_pkey PRIMARY KEY (id);


--
-- Name: directus_migrations directus_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_migrations
    ADD CONSTRAINT directus_migrations_pkey PRIMARY KEY (version);


--
-- Name: directus_notifications directus_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications
    ADD CONSTRAINT directus_notifications_pkey PRIMARY KEY (id);


--
-- Name: directus_operations directus_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_pkey PRIMARY KEY (id);


--
-- Name: directus_operations directus_operations_reject_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_reject_unique UNIQUE (reject);


--
-- Name: directus_operations directus_operations_resolve_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_resolve_unique UNIQUE (resolve);


--
-- Name: directus_panels directus_panels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_panels
    ADD CONSTRAINT directus_panels_pkey PRIMARY KEY (id);


--
-- Name: directus_permissions directus_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_permissions
    ADD CONSTRAINT directus_permissions_pkey PRIMARY KEY (id);


--
-- Name: directus_presets directus_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_pkey PRIMARY KEY (id);


--
-- Name: directus_relations directus_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_relations
    ADD CONSTRAINT directus_relations_pkey PRIMARY KEY (id);


--
-- Name: directus_revisions directus_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_pkey PRIMARY KEY (id);


--
-- Name: directus_roles directus_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_roles
    ADD CONSTRAINT directus_roles_pkey PRIMARY KEY (id);


--
-- Name: directus_sessions directus_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_pkey PRIMARY KEY (token);


--
-- Name: directus_settings directus_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_pkey PRIMARY KEY (id);


--
-- Name: directus_shares directus_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_pkey PRIMARY KEY (id);


--
-- Name: directus_users directus_users_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_email_unique UNIQUE (email);


--
-- Name: directus_users directus_users_external_identifier_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_external_identifier_unique UNIQUE (external_identifier);


--
-- Name: directus_users directus_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_pkey PRIMARY KEY (id);


--
-- Name: directus_users directus_users_token_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_token_unique UNIQUE (token);


--
-- Name: directus_webhooks directus_webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_webhooks
    ADD CONSTRAINT directus_webhooks_pkey PRIMARY KEY (id);


--
-- Name: ddb_comment ddb_comment_author_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_comment
    ADD CONSTRAINT ddb_comment_author_id_foreign FOREIGN KEY (author_id) REFERENCES public.directus_users(id);


--
-- Name: ddb_comment ddb_comment_feedback_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_comment
    ADD CONSTRAINT ddb_comment_feedback_id_foreign FOREIGN KEY (feedback_id) REFERENCES public.ddb_feedback(id);


--
-- Name: ddb_comment ddb_comment_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_comment
    ADD CONSTRAINT ddb_comment_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id);


--
-- Name: ddb_comment ddb_comment_user_updated_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_comment
    ADD CONSTRAINT ddb_comment_user_updated_foreign FOREIGN KEY (user_updated) REFERENCES public.directus_users(id);


--
-- Name: ddb_company ddb_company_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_company
    ADD CONSTRAINT ddb_company_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id);


--
-- Name: ddb_company ddb_company_user_updated_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_company
    ADD CONSTRAINT ddb_company_user_updated_foreign FOREIGN KEY (user_updated) REFERENCES public.directus_users(id);


--
-- Name: ddb_feedback ddb_feedback_author_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_feedback
    ADD CONSTRAINT ddb_feedback_author_id_foreign FOREIGN KEY (author_id) REFERENCES public.directus_users(id);


--
-- Name: ddb_feedback ddb_feedback_company_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_feedback
    ADD CONSTRAINT ddb_feedback_company_id_foreign FOREIGN KEY (company_id) REFERENCES public.ddb_company(id);


--
-- Name: ddb_feedback ddb_feedback_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_feedback
    ADD CONSTRAINT ddb_feedback_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id);


--
-- Name: ddb_feedback ddb_feedback_user_updated_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_feedback
    ADD CONSTRAINT ddb_feedback_user_updated_foreign FOREIGN KEY (user_updated) REFERENCES public.directus_users(id);


--
-- Name: ddb_vote ddb_vote_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_vote
    ADD CONSTRAINT ddb_vote_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id);


--
-- Name: ddb_vote ddb_vote_user_updated_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_vote
    ADD CONSTRAINT ddb_vote_user_updated_foreign FOREIGN KEY (user_updated) REFERENCES public.directus_users(id);


--
-- Name: ddb_vote ddb_vote_voted_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_vote
    ADD CONSTRAINT ddb_vote_voted_by_foreign FOREIGN KEY (voted_by) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: ddb_vote ddb_vote_voted_for_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ddb_vote
    ADD CONSTRAINT ddb_vote_voted_for_foreign FOREIGN KEY (voted_for) REFERENCES public.ddb_feedback(id) ON DELETE SET NULL;


--
-- Name: directus_collections directus_collections_group_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_collections
    ADD CONSTRAINT directus_collections_group_foreign FOREIGN KEY ("group") REFERENCES public.directus_collections(collection);


--
-- Name: directus_dashboards directus_dashboards_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_dashboards
    ADD CONSTRAINT directus_dashboards_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_files directus_files_folder_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_folder_foreign FOREIGN KEY (folder) REFERENCES public.directus_folders(id) ON DELETE SET NULL;


--
-- Name: directus_files directus_files_modified_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_modified_by_foreign FOREIGN KEY (modified_by) REFERENCES public.directus_users(id);


--
-- Name: directus_files directus_files_uploaded_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_uploaded_by_foreign FOREIGN KEY (uploaded_by) REFERENCES public.directus_users(id);


--
-- Name: directus_flows directus_flows_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_flows
    ADD CONSTRAINT directus_flows_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_folders directus_folders_parent_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_folders
    ADD CONSTRAINT directus_folders_parent_foreign FOREIGN KEY (parent) REFERENCES public.directus_folders(id);


--
-- Name: directus_notifications directus_notifications_recipient_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications
    ADD CONSTRAINT directus_notifications_recipient_foreign FOREIGN KEY (recipient) REFERENCES public.directus_users(id) ON DELETE CASCADE;


--
-- Name: directus_notifications directus_notifications_sender_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_notifications
    ADD CONSTRAINT directus_notifications_sender_foreign FOREIGN KEY (sender) REFERENCES public.directus_users(id);


--
-- Name: directus_operations directus_operations_flow_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_flow_foreign FOREIGN KEY (flow) REFERENCES public.directus_flows(id) ON DELETE CASCADE;


--
-- Name: directus_operations directus_operations_reject_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_reject_foreign FOREIGN KEY (reject) REFERENCES public.directus_operations(id);


--
-- Name: directus_operations directus_operations_resolve_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_resolve_foreign FOREIGN KEY (resolve) REFERENCES public.directus_operations(id);


--
-- Name: directus_operations directus_operations_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_operations
    ADD CONSTRAINT directus_operations_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_panels directus_panels_dashboard_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_panels
    ADD CONSTRAINT directus_panels_dashboard_foreign FOREIGN KEY (dashboard) REFERENCES public.directus_dashboards(id) ON DELETE CASCADE;


--
-- Name: directus_panels directus_panels_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_panels
    ADD CONSTRAINT directus_panels_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_permissions directus_permissions_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_permissions
    ADD CONSTRAINT directus_permissions_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE CASCADE;


--
-- Name: directus_presets directus_presets_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE CASCADE;


--
-- Name: directus_presets directus_presets_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_user_foreign FOREIGN KEY ("user") REFERENCES public.directus_users(id) ON DELETE CASCADE;


--
-- Name: directus_revisions directus_revisions_activity_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_activity_foreign FOREIGN KEY (activity) REFERENCES public.directus_activity(id) ON DELETE CASCADE;


--
-- Name: directus_revisions directus_revisions_parent_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_parent_foreign FOREIGN KEY (parent) REFERENCES public.directus_revisions(id);


--
-- Name: directus_sessions directus_sessions_share_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_share_foreign FOREIGN KEY (share) REFERENCES public.directus_shares(id) ON DELETE CASCADE;


--
-- Name: directus_sessions directus_sessions_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_user_foreign FOREIGN KEY ("user") REFERENCES public.directus_users(id) ON DELETE CASCADE;


--
-- Name: directus_settings directus_settings_project_logo_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_project_logo_foreign FOREIGN KEY (project_logo) REFERENCES public.directus_files(id);


--
-- Name: directus_settings directus_settings_public_background_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_background_foreign FOREIGN KEY (public_background) REFERENCES public.directus_files(id);


--
-- Name: directus_settings directus_settings_public_foreground_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_foreground_foreign FOREIGN KEY (public_foreground) REFERENCES public.directus_files(id);


--
-- Name: directus_settings directus_settings_storage_default_folder_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_storage_default_folder_foreign FOREIGN KEY (storage_default_folder) REFERENCES public.directus_folders(id) ON DELETE SET NULL;


--
-- Name: directus_shares directus_shares_collection_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_collection_foreign FOREIGN KEY (collection) REFERENCES public.directus_collections(collection) ON DELETE CASCADE;


--
-- Name: directus_shares directus_shares_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE CASCADE;


--
-- Name: directus_shares directus_shares_user_created_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_shares
    ADD CONSTRAINT directus_shares_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id) ON DELETE SET NULL;


--
-- Name: directus_users directus_users_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON DELETE SET NULL;


--
-- Name: TABLE ddb_comment; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ddb_comment TO ddb_user;


--
-- Name: TABLE ddb_company; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ddb_company TO ddb_user;


--
-- Name: TABLE ddb_feedback; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ddb_feedback TO ddb_user;


--
-- Name: TABLE ddb_vote; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ddb_vote TO ddb_user;


--
-- Name: TABLE directus_activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_activity TO ddb_user;


--
-- Name: TABLE directus_collections; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_collections TO ddb_user;


--
-- Name: TABLE directus_dashboards; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_dashboards TO ddb_user;


--
-- Name: TABLE directus_fields; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_fields TO ddb_user;


--
-- Name: TABLE directus_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_files TO ddb_user;


--
-- Name: TABLE directus_flows; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_flows TO ddb_user;


--
-- Name: TABLE directus_folders; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_folders TO ddb_user;


--
-- Name: TABLE directus_migrations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_migrations TO ddb_user;


--
-- Name: TABLE directus_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_notifications TO ddb_user;


--
-- Name: TABLE directus_operations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_operations TO ddb_user;


--
-- Name: TABLE directus_panels; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_panels TO ddb_user;


--
-- Name: TABLE directus_permissions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_permissions TO ddb_user;


--
-- Name: TABLE directus_presets; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_presets TO ddb_user;


--
-- Name: TABLE directus_relations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_relations TO ddb_user;


--
-- Name: TABLE directus_revisions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_revisions TO ddb_user;


--
-- Name: TABLE directus_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_roles TO ddb_user;


--
-- Name: TABLE directus_sessions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_sessions TO ddb_user;


--
-- Name: TABLE directus_settings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_settings TO ddb_user;


--
-- Name: TABLE directus_shares; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_shares TO ddb_user;


--
-- Name: TABLE directus_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_users TO ddb_user;


--
-- Name: TABLE directus_webhooks; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.directus_webhooks TO ddb_user;


-- 
-- Fix for missing GRANT after pg_dump and restore
--
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ddb_user;

--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 15.2 (Debian 15.2-1.pgdg110+1)
-- Dumped by pg_dump version 15.2 (Debian 15.2-1.pgdg110+1)

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

DROP DATABASE postgres;
--
-- Name: postgres; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE postgres OWNER TO postgres;

\connect postgres

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

--
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- Name: postgres; Type: DATABASE PROPERTIES; Schema: -; Owner: postgres
--

ALTER DATABASE postgres SET search_path TO '$user', 'public', 'topology', 'tiger';


\connect postgres

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

--
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger;


ALTER SCHEMA tiger OWNER TO postgres;

--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger_data;


ALTER SCHEMA tiger_data OWNER TO postgres;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: geocode_settings; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.geocode_settings (name, setting, unit, category, short_desc) FROM stdin;
\.


--
-- Data for Name: pagc_gaz; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_gaz (id, seq, word, stdword, token, is_custom) FROM stdin;
\.


--
-- Data for Name: pagc_lex; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_lex (id, seq, word, stdword, token, is_custom) FROM stdin;
\.


--
-- Data for Name: pagc_rules; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_rules (id, rule, is_custom) FROM stdin;
\.


--
-- Data for Name: topology; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.topology (id, name, srid, "precision", hasz) FROM stdin;
\.


--
-- Data for Name: layer; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.layer (topology_id, layer_id, schema_name, table_name, feature_column, feature_type, level, child_id) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

--
-- Database "template_postgis" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 15.2 (Debian 15.2-1.pgdg110+1)
-- Dumped by pg_dump version 15.2 (Debian 15.2-1.pgdg110+1)

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

--
-- Name: template_postgis; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE template_postgis WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE template_postgis OWNER TO postgres;

\connect template_postgis

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

--
-- Name: template_postgis; Type: DATABASE PROPERTIES; Schema: -; Owner: postgres
--

ALTER DATABASE template_postgis IS_TEMPLATE = true;
ALTER DATABASE template_postgis SET search_path TO '$user', 'public', 'topology', 'tiger';


\connect template_postgis

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

--
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger;


ALTER SCHEMA tiger OWNER TO postgres;

--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger_data;


ALTER SCHEMA tiger_data OWNER TO postgres;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: geocode_settings; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.geocode_settings (name, setting, unit, category, short_desc) FROM stdin;
\.


--
-- Data for Name: pagc_gaz; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_gaz (id, seq, word, stdword, token, is_custom) FROM stdin;
\.


--
-- Data for Name: pagc_lex; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_lex (id, seq, word, stdword, token, is_custom) FROM stdin;
\.


--
-- Data for Name: pagc_rules; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_rules (id, rule, is_custom) FROM stdin;
\.


--
-- Data for Name: topology; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.topology (id, name, srid, "precision", hasz) FROM stdin;
\.


--
-- Data for Name: layer; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.layer (topology_id, layer_id, schema_name, table_name, feature_column, feature_type, level, child_id) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

