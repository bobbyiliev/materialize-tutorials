CREATE SCHEMA materialize;
SET search_path TO materialize;

ALTER SYSTEM SET wal_level = logical;
ALTER ROLE postgres WITH REPLICATION;

