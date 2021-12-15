{{ config(materialized='materializedview') }}

SELECT
    reviews.user_id,
    reviews.review_text,
    reviews.review_rating,
    reviews.created_at,
    reviews.updated_at
FROM reviews
WHERE reviews.review_rating < 3