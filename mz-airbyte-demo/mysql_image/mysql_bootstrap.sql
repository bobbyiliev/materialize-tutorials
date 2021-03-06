CREATE TABLE IF NOT EXISTS shop.orders
    (
        id SERIAL PRIMARY KEY,
        user_id BIGINT UNSIGNED,
        order_status TINYINT UNSIGNED DEFAULT 1,
        price DECIMAL(12,2),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'airbyte'@'%';