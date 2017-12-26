-------------------------------------------------------------------------------
-- Purpose: Test allowed and denied access for single and multitagging
-- of cell level security
--
-- Author: Michael West
-- Date: 2017-MAR-14
-------------------------------------------------------------------------------

-- connect 
\c cell_level_security

-- grant viewer access to PHI and no other tags
SELECT 'SET viewer can access PHI' as setup;

TRUNCATE TABLE secure.usertag;

INSERT INTO secure.usertag (usename , binary_tags) 
VALUES ('viewer', (
  SELECT SUM(binary_tag) 
  FROM secure.tags 
  WHERE tag_name IN ('PHI'))
);

SET SESSION AUTHORIZATION 'viewer';

-- Test user can access PHI
SELECT 'test viewer can access PHI' as test_descr,
  CASE 
    WHEN count(distinct linenumber_phi) = 7 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;


-- Test viewer cannot access PII 
SELECT 'test viewer cannot access PII' as test_descr,
  CASE 
    WHEN count(distinct custkey_pii) = 0 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;

SET SESSION AUTHORIZATION DEFAULT;

SELECT 'SET viewer can access PHI, FEP, and EMPL' as setup;

-- grant viewer access to PHI, FEP, and EMPL tagged data
UPDATE secure.usertag
SET binary_tags = ( 
  SELECT SUM(binary_tag) 
  FROM secure.tags 
  WHERE tag_name IN ('PHI', 'FEP','EMPL')
)
WHERE usename = 'viewer';


SET SESSION AUTHORIZATION 'viewer';

-- Test user can access PHI
SELECT 'test viewer can access PHI' as test_descr,
  CASE 
    WHEN count(distinct linenumber_phi) = 7 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;

-- Test user can access FEP
SELECT 'test viewer can access FEP' as test_descr,
  CASE 
    WHEN count(distinct suppkey_fep) = 1000000 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;

-- Test user can access EMPL
SELECT 'test viewer can access EMPL' as test_descr,
  CASE 
    WHEN count(distinct shipmode_empl) = 7 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;

-- Test user can access PHI and FEP 
SELECT 'test viewer can access PHI and FEP' as test_descr,
  CASE 
    WHEN count(distinct orderdate_phi_fep) = 2406 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;

-- Test viewer cannot access PII 
SELECT 'test viewer cannot access PII' as test_descr,
  CASE 
    WHEN count(distinct custkey_pii) = 0 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;

-- Test viewer cannot access PHI and PII 
SELECT 'test viewer cannot access PHI and PII' as test_descr,
  CASE 
    WHEN count(custkey_partkey_phi_pii) = 0 THEN 'success'
    ELSE 'fail'
  END AS result 
FROM views.sample_lineorder_row_and_col_v;

SET SESSION AUTHORIZATION DEFAULT;
