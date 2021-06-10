--
-- PostgreSQL database dump
--

-- Dumped from database version 12.7 (Ubuntu 12.7-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.7 (Ubuntu 12.7-0ubuntu0.20.04.1)

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
-- Name: after_borrow_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.after_borrow_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE book_details SET
	copies_left = copies_left-1
	WHERE id =NEW.book_id;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.after_borrow_insert() OWNER TO postgres;

--
-- Name: borrow_procedure(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.borrow_procedure() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.book_id IS NOT NULL THEN
        UPDATE book_details set copies_left = copies_left -1 where id=NEW.book_id;
		UPDATE member_details set books_borrowed = books_borrowed +1 where id=NEW.member_id;
    END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.borrow_procedure() OWNER TO postgres;

--
-- Name: borrow_returned(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.borrow_returned() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.book_id IS NOT NULL THEN
        UPDATE book_details set copies_left = copies_left + 1 where id=NEW.book_id;
		UPDATE member_details set books_borrowed = books_borrowed -1 where id=NEW.member_id;
		IF NEW.borrowed_till < CURRENT_DATE THEN
			UPDATE member_details set fine = (CURRENT_DATE - NEW.borrowed_till)*10 where id=NEW.member_id;
			DELETE FROM borrower_details where member_id=NEW.member_id;
		END IF;
    END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.borrow_returned() OWNER TO postgres;

--
-- Name: notify_fines(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_fines() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM pg_notify(
    'Due Date Passed', NEW.member_id
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.notify_fines() OWNER TO postgres;

--
-- Name: reserve_book(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reserve_book(book_id integer, member_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
   ans integer;
begin
  select id 
  into ans
  from book_details
  where id=book_id AND copies_left<=0;
  
  if not found then
     raise 'Book Already Available';
  end if;
  INSERT INTO reserve VALUES(book_id, member_id);
  return 'Reserved';
  
end;$$;


ALTER FUNCTION public.reserve_book(book_id integer, member_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: book_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_details (
    id integer NOT NULL,
    title character varying(100),
    author character varying(100),
    total_copies integer,
    copies_left integer,
    subject character varying(50),
    publication_date date,
    shelf_id integer,
    layer_no integer
);


ALTER TABLE public.book_details OWNER TO postgres;

--
-- Name: borrower_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.borrower_details (
    borrowed_from date,
    borrowed_till date,
    book_id integer,
    member_id integer,
    status character varying(15)
);


ALTER TABLE public.borrower_details OWNER TO postgres;

--
-- Name: category; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.category AS
 SELECT book_details.subject,
    book_details.title,
    book_details.id,
    book_details.copies_left,
    book_details.author
   FROM public.book_details
  GROUP BY book_details.subject, book_details.title, book_details.id, book_details.copies_left, book_details.author;


ALTER TABLE public.category OWNER TO postgres;

--
-- Name: member_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_details (
    id integer NOT NULL,
    name character varying(50),
    contact character varying(10),
    books_borrowed numeric(5,0),
    fine integer DEFAULT 0
);


ALTER TABLE public.member_details OWNER TO postgres;

--
-- Name: reserve; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserve (
    book_id integer,
    member_id integer
);


ALTER TABLE public.reserve OWNER TO postgres;

--
-- Data for Name: book_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_details (id, title, author, total_copies, copies_left, subject, publication_date, shelf_id, layer_no) FROM stdin;
3	Book3	Author2	17	16	Health	2020-05-05	1	2
2	Book2	Author2	15	14	Art	2018-04-21	1	2
1	Book1	Author1	10	0	Physics	2020-05-05	1	1
4	Book4	Author3	13	13	Craft	2012-07-10	1	4
5	Book5	Author5	19	19	Engineering	2010-07-15	1	5
\.


--
-- Data for Name: borrower_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.borrower_details (borrowed_from, borrowed_till, book_id, member_id, status) FROM stdin;
2021-05-07	2021-06-17	3	2	Pending
2021-03-07	2021-05-07	1	3	Pending
2021-05-07	2021-06-17	2	3	Pending
\.


--
-- Data for Name: member_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.member_details (id, name, contact, books_borrowed, fine) FROM stdin;
2	mem2	7658251926	1	0
3	mem3	7658251927	2	0
1	mem1	7658251925	0	340
\.


--
-- Data for Name: reserve; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reserve (book_id, member_id) FROM stdin;
1	1
\.


--
-- Name: book_details book_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_details
    ADD CONSTRAINT book_details_pkey PRIMARY KEY (id);


--
-- Name: member_details member_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_details
    ADD CONSTRAINT member_details_pkey PRIMARY KEY (id);


--
-- Name: borrower_details borrow_returned_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER borrow_returned_trigger AFTER UPDATE ON public.borrower_details FOR EACH ROW EXECUTE FUNCTION public.borrow_returned();


--
-- Name: borrower_details borrow_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER borrow_trigger AFTER INSERT ON public.borrower_details FOR EACH ROW EXECUTE FUNCTION public.borrow_procedure();


--
-- Name: borrower_details book_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrower_details
    ADD CONSTRAINT book_id FOREIGN KEY (book_id) REFERENCES public.book_details(id);


--
-- Name: borrower_details member_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrower_details
    ADD CONSTRAINT member_id FOREIGN KEY (member_id) REFERENCES public.member_details(id);


--
-- Name: reserve reserve_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserve
    ADD CONSTRAINT reserve_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.book_details(id);


--
-- Name: reserve reserve_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserve
    ADD CONSTRAINT reserve_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member_details(id);


--
-- PostgreSQL database dump complete
--
