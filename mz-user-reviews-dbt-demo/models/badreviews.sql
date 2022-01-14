{{ config(materialized='materializedview') }}

SELECT
    reviews_raw.user_id,
    reviews_raw.review_text,
    reviews_raw.review_rating,
    reviews_raw.created_at,
    reviews_raw.updated_at
FROM {{ ref('reviews_raw') }}
WHERE reviews_raw.review_rating < 3