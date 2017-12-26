-------------------------------------------------------------------------------
-- Purpose: Populate data for testing row level security
-- run time 20 minutes on two dc1 node cluster
-- can be faster with add column/update instead of copy data to new table
-- and columner compression
-- TODO
-- parameterize role
--
-- Author: Michael West
-- Date: 2017-MAR-14
-------------------------------------------------------------------------------

-- runtime 20 minutes 

-- populate test data
\c cell_level_security

-- populate tags --------------------------------------------------------------

--clear table before insert
TRUNCATE TABLE secure.tags;

-- insert tags for binary evaluation
INSERT INTO secure.tags (
  tag_position
  , binary_tag 
  , tag_name
  ) VALUES
    (1, 1, 'PHI')
    , (2, 2, 'PII')
    , (3, 4, 'FEP')
    , (4, 8, 'VIP')
    , (5, 16, 'EMPL')
    , (6, 32, 'ITS HOST');


-- copy data to lineorder ------------------------------------------------------------------

TRUNCATE data.lineorder;

COPY data.lineorder FROM 's3://awssampledbuswest2/ssbgz/lineorder'
credentials 'aws_iam_role=arn:aws:iam::117406370666:role/r619185-lab-role-VPCRole-1IIC2HCHRVAGW'
gzip compupdate off region 'us-west-2';

-- copy lineorder data to sample_lineorder adding 

-- load sample line order with row level security 
-- adding sample_rowsecurity vaules
-- this could be an update column instead of load a new table
-- for now prefer to keep a record of the orginal data
TRUNCATE TABLE data.sample_lineorder;

INSERT INTO data.sample_lineorder
SELECT lo_orderkey, lo_linenumber, lo_custkey, lo_partkey, 
  lo_suppkey, lo_orderdate, lo_orderpriority, lo_shippriority,
  lo_quantity, lo_extendedprice, lo_ordertotalprice, lo_discount,
  lo_revenue, lo_supplycost, lo_tax, lo_commitdate, lo_shipmode, 
  -- assign every tagset to some rows 
  MOD(lo_quantity, 16) sample_rowsecurity
FROM data.lineorder;

ANALYZE data.sample_lineorder;
VACUUM  data.sample_lineorder;

