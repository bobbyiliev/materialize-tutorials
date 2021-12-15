{{ config(materialized='materializedview') }}

SELECT
    users.id,
    users.name,
    users.email,
    users.role_id,
    roles.role_name
FROM users
JOIN roles ON users.role_id = roles.id
WHERE users.role_id = 4