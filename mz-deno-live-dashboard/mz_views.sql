CREATE SOURCE score
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'score_topic'
FORMAT BYTES;

CREATE VIEW score_view AS
    SELECT
        *
    FROM (
        SELECT
            (data->>'user_id')::int AS user_id,
            (data->>'score')::int AS score,
            (data->>'created_at')::double AS created_at
        FROM (
            SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT convert_from(data, 'utf8') AS data
                FROM score
            )
        )
    );

CREATE MATERIALIZED VIEW score_view_mz AS
    SELECT
        (SUM(score))::int AS user_score,
        user_id
    FROM score_view GROUP BY user_id;