CREATE SCHEMA app;
SET search_path TO app;

ALTER SYSTEM SET wal_level = logical;
ALTER ROLE postgres WITH REPLICATION;

-- TABLES
CREATE TABLE users (
	id SERIAL PRIMARY KEY,
    name VARCHAR,
    email VARCHAR
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    status VARCHAR,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE coordinates (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    latitude FLOAT,
    longitude FLOAT
);

-- Create demo user
INSERT INTO users (name, email) VALUES ('Demo User', 'demo@demo.com');
-- Add demo order
INSERT INTO orders (user_id, status, created_at, updated_at) VALUES (1, 1, now(), now());
-- Add user coordinates
INSERT INTO coordinates (user_id, latitude, longitude) VALUES (1, 116.54723, 39.54723);

ALTER TABLE users REPLICA IDENTITY FULL;
ALTER TABLE orders REPLICA IDENTITY FULL;
ALTER TABLE coordinates REPLICA IDENTITY FULL;

CREATE PUBLICATION mz_source FOR ALL TABLES;
