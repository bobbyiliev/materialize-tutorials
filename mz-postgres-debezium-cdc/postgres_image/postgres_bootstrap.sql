-- Create a schema and set the search path
CREATE SCHEMA shop;
SET search_path TO shop;

-- Set the wal_level to logical and andd replication role to the postgres user
ALTER SYSTEM SET wal_level = logical;
ALTER ROLE postgres WITH REPLICATION;

-- Create the table
CREATE TABLE IF NOT EXISTS towns (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL,
    article VARCHAR(32) NOT NULL,
    name VARCHAR(32) NOT NULL,
    department VARCHAR(4) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE towns REPLICA IDENTITY FULL;

CREATE PUBLICATION mz_source FOR TABLE towns;

-- Insert 1 million rows
INSERT INTO towns ( code, article, name, department )
    SELECT
        left(md5(i::text), 10),
        md5(random()::text),
        md5(random()::text),
        left(md5(random()::text), 4)
    FROM generate_series(1, 10000000) s(i);

