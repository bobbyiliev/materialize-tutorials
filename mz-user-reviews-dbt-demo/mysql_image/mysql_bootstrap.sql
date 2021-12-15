CREATE TABLE IF NOT EXISTS db.users
    (
        id SERIAL PRIMARY KEY,
        role_id INTEGER NOT NULL,
        name VARCHAR(255),
        email VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS db.roles
    (
        id SERIAL PRIMARY KEY,
        role_name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS db.reviews
    (
        id SERIAL PRIMARY KEY,
        user_id BIGINT UNSIGNED,
        review_text TEXT,
        review_rating INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

USE db;
INSERT INTO roles (role_name) VALUES ('admin');
INSERT INTO roles (role_name) VALUES ('user');
INSERT INTO roles (role_name) VALUES ('guest');
INSERT INTO roles (role_name) VALUES ('vip');