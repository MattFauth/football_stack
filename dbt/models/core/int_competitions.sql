WITH competitions AS (
    SELECT *
    FROM {{ ref('stg_competitions') }}
),

overrides AS (
    SELECT *
    FROM {{ ref('competition_overrides') }}
),

game_competitions AS (
    SELECT
        competition_id,
        MAX(NULLIF(competition_type, '')) AS observed_competition_type
    FROM {{ ref('stg_games') }}
    WHERE competition_id IS NOT NULL
    GROUP BY competition_id
),

inferred_competitions AS (
    SELECT
        gc.competition_id,
        gc.competition_id AS competition_code,
        COALESCE(
            o.competition_name,
            'Unmapped competition ' || gc.competition_id
        ) AS competition_name,
        o.sub_type,
        COALESCE(
            o.competition_type,
            gc.observed_competition_type
        ) AS competition_type,
        CAST(o.country_id AS TEXT) AS country_id,
        o.country_name,
        o.domestic_league_code,
        o.confederation,
        CAST(NULL AS TEXT) AS total_clubs,
        CAST(NULL AS TEXT) AS url,
        TRUE AS is_inferred
    FROM game_competitions gc
    LEFT JOIN competitions c
        ON gc.competition_id = c.competition_id
    LEFT JOIN overrides o
        ON gc.competition_id = o.competition_id
    WHERE c.competition_id IS NULL
),

registered_competitions AS (
    SELECT
        competition_id,
        competition_code,
        competition_name,
        sub_type,
        competition_type,
        country_id,
        country_name,
        domestic_league_code,
        confederation,
        total_clubs,
        url,
        FALSE AS is_inferred
    FROM competitions
)

SELECT *
FROM registered_competitions

UNION ALL

SELECT *
FROM inferred_competitions