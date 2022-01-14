{{ config(materialized='materializedview') }}

SELECT
    users_raw.id,
    users_raw.name,
    users_raw.email,
    users_raw.role_id,
    roles_raw.role_name
FROM {{ ref('users_raw') }}
JOIN {{ ref('roles_raw') }} ON {{ ref('users_raw') }}.role_id = {{ ref('roles_raw') }} .id
WHERE {{ ref('users_raw') }}.role_id = 4