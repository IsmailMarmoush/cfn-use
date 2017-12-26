-------------------------------------------------------------------------------
-- Purpose: Create Database Objects for testing cell level security 
-- Includes Schemas, Tables, View, and functions
-- 
-- note that table does not include compression.  This is intentional as even 
-- with 600 million rows the queries can be too fast to easily measure 
-- performance differences.
--
-- Author: Michael West
-- Date: 2017-MAR-14
--
-------------------------------------------------------------------------------

-- create database and connect
CREATE DATABASE cell_level_security;

\c cell_level_security

-------------------------------------------------------------------------------
-- create schemas
-------------------------------------------------------------------------------

-- create schema for data
CREATE SCHEMA IF NOT EXISTS data AUTHORIZATION dataowner;

-- let views schema owner see data schema
GRANT USAGE ON SCHEMA data TO viewowner;

-- grant viewonly users usage on data schema
GRANT USAGE ON SCHEMA data TO GROUP viewonly;

-- create schema to hold views
CREATE SCHEMA IF NOT EXISTS views AUTHORIZATION viewowner;

-- grant viewonly users usage on view schema
GRANT USAGE ON SCHEMA views TO GROUP viewonly;

-- create schema for security config
CREATE SCHEMA IF NOT EXISTS secure AUTHORIZATION secureowner;

-- grant viewonly users usage on view schema
GRANT USAGE ON SCHEMA secure TO GROUP viewonly;

-- view schemas and ownership
select nspname as schema, usename as owner
from pg_namespace inner join pg_user
on pg_namespace.nspowner = pg_user.usesysid
where pg_namespace.nspname in ( 'data', 'views', 'secure');

-- SET DEFAULT SCHEMA PRIVILEGES

-- views schema owner can select tables in data schema
ALTER DEFAULT PRIVILEGES IN SCHEMA data
GRANT SELECT ON TABLES TO viewowner;

-- views schema owner can select tables in secure schema
ALTER DEFAULT PRIVILEGES IN SCHEMA secure
GRANT SELECT ON TABLES TO viewowner;

-- members of group viewonly have privlege SELECT to views in schema views
ALTER DEFAULT PRIVILEGES IN SCHEMA views
GRANT SELECT ON TABLES TO GROUP viewonly;


-------------------------------------------------------------------------------
-- create secure tables
-------------------------------------------------------------------------------

-- create users table with binary tags 
CREATE TABLE IF NOT EXISTS
secure.usertag (
  usename VARCHAR(255) NOT NULL PRIMARY KEY,
  binary_tags BIGINT NOT NULL
)
DISTSTYLE ALL;


-- create tag reference table
CREATE TABLE IF NOT EXISTS
secure.tags (
  tag_position INTEGER NOT NULL PRIMARY KEY,
  binary_tag BIGINT NOT NULL,
  tag_name VARCHAR(255) NOT NULL
)
DISTSTYLE ALL;

-------------------------------------------------------------------------------
-- create data tables
-------------------------------------------------------------------------------

-- create line order table
-- from the tutorial
-- http://docs.aws.amazon.com/redshift/latest/dg/tutorial-tuning-tables-create-test-data.html
-- need to add compression

CREATE TABLE data.lineorder 
(
      lo_orderkey          INTEGER NOT NULL,
      lo_linenumber        INTEGER NOT NULL,
      lo_custkey           INTEGER NOT NULL,
      lo_partkey           INTEGER NOT NULL DISTKEY,
      lo_suppkey           INTEGER NOT NULL,
      lo_orderdate         INTEGER NOT NULL SORTKEY,
      lo_orderpriority     VARCHAR(15) NOT NULL,
      lo_shippriority      VARCHAR(1) NOT NULL,
      lo_quantity          INTEGER NOT NULL,
      lo_extendedprice     INTEGER NOT NULL,
      lo_ordertotalprice   INTEGER NOT NULL,
      lo_discount          INTEGER NOT NULL,
      lo_revenue           INTEGER NOT NULL,
      lo_supplycost        INTEGER NOT NULL,
      lo_tax               INTEGER NOT NULL,
      lo_commitdate        INTEGER NOT NULL,
      lo_shipmode          VARCHAR(10) NOT NULL
);


-- Create performance test table for cell level filtering
-- DDL from AWS provided doc
-- 'Restricting access to subset of rows'
-- for performance comparison to that work
-- need to add compression
CREATE TABLE data.sample_lineorder (
      sample_orderkey           integer       not null,
      sample_linenumber         integer       not null,
      sample_custkey            integer       not null,
      sample_partkey            integer       not null distkey,
      sample_suppkey            integer       not null,
      sample_orderdate          integer       not null sortkey,
      sample_orderpriority      varchar(15)     not null,
      sample_shippriority       varchar(1)      not null,
      sample_quantity           integer       not null,
      sample_extendedprice      integer       not null,
      sample_ordertotalprice    integer       not null,
      sample_discount           integer       not null,
      sample_revenue            integer       not null,
      sample_supplycost         integer       not null,
      sample_tax                integer       not null,
      sample_commitdate         integer         not null,
      sample_shipmode           varchar(10)     not null,
      sample_rowsecurity        integer);


-------------------------------------------------------------------------------
-- create views
-------------------------------------------------------------------------------



CREATE OR REPLACE VIEW views.sample_lineorder_row_and_col_v AS (
    SELECT
        is_row_permitted
    ,   sample_rowsecurity
    ,	CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 0 = 0
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_orderkey
            ELSE NULL
        END AS orderkey_notag
    ,   -- sample_linenumber tagged PHI
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 1 = 1
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_linenumber
            ELSE NULL
        END AS linenumber_phi
    ,   -- sample_custkey tagged PII
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 2 = 2
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_custkey
            ELSE NULL
        END AS custkey_pii
    ,   -- sample_partkey tagged PHI and PII
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 3 = 3
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_partkey
            ELSE NULL
        END AS custkey_partkey_phi_pii
    ,   -- sample_suppkey tagged FEP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 4 = 4
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_suppkey
            ELSE NULL
        END AS suppkey_fep
    ,   -- sample_orderdate tagged PHI and FEP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 5 = 5
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_orderdate
            ELSE NULL
        END AS orderdate_phi_fep
    ,   -- sample_orderpriority tagged PII and FEP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 6 = 6
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_orderpriority
            ELSE NULL
        END AS orderpriority_pii_fep
    ,   -- sample_shippriority tagged PHI, PII and FEP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 7 = 7
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_shippriority
            ELSE NULL
        END AS shippriority_phi_pii_fep
    ,   -- sample_quantity tagged VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 8 = 8
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_quantity
            ELSE NULL
        END AS quantity_vip
    ,   -- sample_extendedprice tagged PHI, VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 9 = 9
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_extendedprice
            ELSE NULL
        END AS extendedprice_phi_vip
    ,   -- sample_ordertotalprice tagged PII, VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 10 = 10
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_ordertotalprice
            ELSE NULL
        END AS ordertotalprice_pii_vip
    ,   -- sample_discount tagged PHI, PII, VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 11 = 11
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_discount
            ELSE NULL
        END AS discount_phi_pii_vip
    ,   -- sample_revenue tagged FEP, VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 12 = 12
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_revenue
            ELSE NULL
        END AS revenue_fep_vip
    ,   -- sample_supplycost tagged PHI,FEP, VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 13 = 13
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_supplycost
            ELSE NULL
        END AS supplycost_phi_fep_vip
    ,   -- sample_tax tagged PII,FEP, VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 14 = 14
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_tax
            ELSE NULL
        END AS tax_pii_fep_vip
    ,   -- sample_commitdate tagged PHI,PII,FEP, VIP
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 15 = 15
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_commitdate
            ELSE NULL
        END AS commitdate_phi_pii_fep_vip
    ,   -- sample_shipmode tagged EMPL
        CASE
            WHEN is_row_permitted IS true AND ( 
                SELECT binary_tags & 16 = 16
                FROM secure.usertag
                WHERE usename = CURRENT_USER
            ) 
            THEN sample_shipmode
            ELSE NULL
        END AS shipmode_empl
    FROM (
        SELECT
        sample_rowsecurity & usersecurity = sample_rowsecurity AS is_row_permitted
        ,addusersecurity.*
        FROM (
            SELECT  
                ( SELECT binary_tags
                FROM secure.usertag
                WHERE usename = CURRENT_USER ) AS usersecurity
                , sample_lineorder.*
            FROM data.sample_lineorder
        ) AS addusersecurity
    ) 
);


-------------------------------------------------------------------------------
-- create nice scalar functions from awslabs that display binary values 
-------------------------------------------------------------------------------

/* f_bitwise_to_string.sql

Purpose: Bitwise operations are very fast in Redshift and are invaluable when dealing 
         with many thousands of BOOLEAN columns. This function, most useful for reporting, 
         creates a VARCHAR representation of an INT column containing bit-wise encoded
         BOOLEAN values, e.g. 281 => '100011001'

Arguments:
    • `bitwise_column` - column containing bit-wise encoded BOOLEAN values
    • `bits_in_column` - number of bits encoded in the column

Internal dependencies: none

External dependencies: none

2015-10-15: created by Joe Harris (https://github.com/joeharris76)
*/
CREATE OR REPLACE FUNCTION f_bitwise_to_string(bitwise_column BIGINT, bits_in_column INT)
    RETURNS VARCHAR(255)
STABLE
AS $$
  # Convert column to binary, strip "0b" prefix, pad out with zeroes
  b = bin(bitwise_column)[2:].zfill(bits_in_column)
  return b
$$ LANGUAGE plpythonu;

/* Example usage:

udf=# CREATE TEMP TABLE bitwise_example (id INT, packed_bools BIGINT, packed_count INT);
CREATE TABLE

udf=# INSERT INTO bitwise_example 
udf-# VALUES (1, B'100011001'::integer, 9),
udf-#        (2, B'000011010'::integer, 9),
udf-#        (3, B'100011101'::integer, 9),
udf-#        (4, B'000110001'::integer, 9);
INSERT 0 4

udf=# SELECT id, packed_bools, f_bitwise_to_string(packed_bools,packed_count) FROM bitwise_example;
 id | packed_bools | f_bitwise_to_string 
----+--------------+--------------------
  2 |           26 | 000011010
  3 |          285 | 100011101
  4 |           49 | 000110001
  1 |          281 | 100011001
(4 rows)

*/


-------------------------------------------------------------------------------

/* f_bitwise_to_delimited.sql

Purpose: Bitwise operations are very fast in Redshift and are invaluable when dealing
         with many thousands of BOOLEAN columns. This function, most useful for exports,
         creates a VARCHAR, delimited by a specified character, from an INT column 
         containing bit-wise encoded BOOLEAN values, e.g. 281 => '1,0,0,0,1,1,0,0,1'

Arguments:
    • `bitwise_column` - column containing bit-wise encoded BOOLEAN values
    • `bits_in_column` - number of bits encoded in the column
    • `delimiter`      - character that will delimit the output

Internal dependencies: none

External dependencies: none

2015-10-15: created by Joe Harris (https://github.com/joeharris76)
*/
CREATE OR REPLACE FUNCTION f_bitwise_to_delimited(bitwise_column BIGINT, bits_in_column INT, delimter CHAR(1))
    RETURNS VARCHAR(512)
STABLE
AS $$
  # Convert column to binary, strip "0b" prefix, pad out with zeroes
  b = bin(bitwise_column)[2:].zfill(bits_in_column)
  # Convert each character to a member of an array, join array into string using delimiter
  o = delimter.join([b[i:i+1] for i in range(0, len(b), 1)])
  return o
$$ LANGUAGE plpythonu;

/* Example usage:

udf=# CREATE TEMP TABLE bitwise_example (id INT, packed_bools BIGINT, packed_count INT);
CREATE TABLE

udf=# INSERT INTO bitwise_example 
udf-# VALUES (1, B'100011001'::integer, 9),
udf-#        (2, B'000011010'::integer, 9),
udf-#        (3, B'100011101'::integer, 9),
udf-#        (4, B'000110001'::integer, 9);
INSERT 0 4

udf=# SELECT id, packed_bools, f_bitwise_to_delimited(packed_bools, packed_count, ',') FROM bitwise_example;
 id | packed_bools | f_bitwise_to_delimited 
----+--------------+----------------------- 
  1 |          281 | 1,0,0,0,1,1,0,0,1
  2 |           26 | 0,0,0,0,1,1,0,1,0
  3 |          285 | 1,0,0,0,1,1,1,0,1
  4 |           49 | 0,0,0,1,1,0,0,0,1
(4 rows)

*/

--END
