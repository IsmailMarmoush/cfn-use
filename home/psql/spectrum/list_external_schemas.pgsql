SELECT * FROM pg_external_schema pe JOIN pg_namespace pn ON pe.esoid = pn.oid;
