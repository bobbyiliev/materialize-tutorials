{{ config(materialized='materializedview') }}

SELECT
    vipusers.name,
    vipusers.email,
    vipusers.role_name,
    badreviews.review_rating,
    badreviews.review_text
FROM {{ ref('vipusers') }}
JOIN {{ ref('badreviews') }} ON {{ ref('vipusers') }}.id = {{ ref('badreviews') }}.user_id