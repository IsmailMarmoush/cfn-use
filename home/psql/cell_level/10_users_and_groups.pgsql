-------------------------------------------------------------------------------
-- Purpose: Create USERS and GROUPS for testing cell level security
--
-- Author: Michael West
-- Date: 2017-MAR-14
-------------------------------------------------------------------------------
-- create data schema owner
CREATE USER dataowner NOCREATEDB NOCREATEUSER PASSWORD 'Datapass01';

-- create views schema owner
CREATE USER viewowner NOCREATEDB NOCREATEUSER PASSWORD 'Viewspass01';

-- create secure schema owner
CREATE USER secureowner NOCREATEDB NOCREATEUSER PASSWORD 'Securepass01';

-- create user that can only select views
CREATE USER viewer NOCREATEDB NOCREATEUSER PASSWORD 'Viewerpass01';

CREATE GROUP viewonly WITH USER viewer;
