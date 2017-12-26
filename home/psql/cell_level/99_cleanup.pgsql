-------------------------------------------------------------------------------
-- Purpose: Drop all test objects in support of cell level security 
--
-- Author: Michael West
-- Date: 2017-MAR-14
-------------------------------------------------------------------------------

-- reset cluster to inital state

-- drop database
DROP DATABASE cell_level_security;

-- drop data schema owner
DROP USER dataowner;

-- drop views schema owner
DROP USER viewowner;

-- drop secure schema owner
DROP USER secureowner;

-- drop user that can only select views
DROP USER viewer;

-- drop view only group
DROP GROUP viewonly;
