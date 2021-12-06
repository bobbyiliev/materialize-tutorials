CREATE SCHEMA iot;
SET search_path TO iot;

ALTER SYSTEM SET wal_level = logical;
ALTER ROLE postgres WITH REPLICATION;

/* TABLES */

CREATE TABLE sensors (
	id SERIAL PRIMARY KEY,
    name VARCHAR,
    timestamp VARCHAR,
    temperature VARCHAR
);

ALTER TABLE sensors REPLICA IDENTITY FULL;

CREATE PUBLICATION mz_source FOR TABLE sensors;
