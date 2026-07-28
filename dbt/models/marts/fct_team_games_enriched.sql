WITH games AS (
    SELECT *
    FROM {{ ref('fct_games') }}
),

competitions AS (
    SELECT *
    FROM {{ ref('dim_competitions') }}
),

base_games AS (
    SELECT
        g.game_id,
        g.game_date,
        g.season,
        g.competition_id,
        c.competition_name,
        c.competition_type,
        c.sub_type AS competition_sub_type,
        c.country_id AS competition_country_id,
        c.country_name AS competition_country_name,
        c.confederation,
        g.round,
        g.home_team_id,
        g.home_team_name,
        g.home_team_type,
        g.away_team_id,
        g.away_team_name,
        g.away_team_type,
        coalesce(
            g.home_team_goals_excl_shootout,
            g.home_team_goals
        ) AS home_goals,
        coalesce(
            g.away_team_goals_excl_shootout,
            g.away_team_goals
        ) AS away_goals,
        g.went_to_shootout,
        g.score_reconciled,
        g.score_format,
        g.stadium,
        g.attendance,
        g.referee,
        g.url
    FROM games g
    LEFT JOIN competitions c
        ON g.competition_id = c.competition_id
),

team_perspectives AS (
    SELECT
        game_id,
        game_date,
        season,
        competition_id,
        competition_name,
        competition_type,
        competition_sub_type,
        competition_country_id,
        competition_country_name,
        confederation,
        round,
        home_team_id AS team_id,
        home_team_name AS team_name,
        home_team_type AS team_type,
        away_team_id AS opponent_id,
        away_team_name AS opponent_name,
        away_team_type AS opponent_type,
        'home' AS venue,
        home_goals AS goals_for,
        away_goals AS goals_against,
        went_to_shootout,
        score_reconciled,
        score_format,
        stadium,
        attendance,
        referee,
        url
    FROM base_games

    UNION ALL

    SELECT
        game_id,
        game_date,
        season,
        competition_id,
        competition_name,
        competition_type,
        competition_sub_type,
        competition_country_id,
        competition_country_name,
        confederation,
        round,
        away_team_id AS team_id,
        away_team_name AS team_name,
        away_team_type AS team_type,
        home_team_id AS opponent_id,
        home_team_name AS opponent_name,
        home_team_type AS opponent_type,
        'away' AS venue,
        away_goals AS goals_for,
        home_goals AS goals_against,
        went_to_shootout,
        score_reconciled,
        score_format,
        stadium,
        attendance,
        referee,
        url
    FROM base_games
)

SELECT
    game_id,
    game_date,
    season,
    competition_id,
    competition_name,
    competition_type,
    competition_sub_type,
    competition_country_id,
    competition_country_name,
    confederation,
    round,
    team_id,
    team_name,
    team_type,
    opponent_id,
    opponent_name,
    opponent_type,
    venue,
    goals_for,
    goals_against,
    goals_for - goals_against AS goal_difference,
    goals_for + goals_against AS total_goals,
    CASE
        WHEN goals_for > goals_against THEN 'win'
        WHEN goals_for < goals_against THEN 'loss'
        ELSE 'draw'
    END AS result,
    CASE
        WHEN goals_for > goals_against THEN 3
        WHEN goals_for = goals_against THEN 1
        ELSE 0
    END AS points,
    goals_for > goals_against AS is_win,
    goals_for = goals_against AS is_draw,
    goals_for < goals_against AS is_loss,
    goals_against = 0 AS is_clean_sheet,
    goals_for = 0 AS failed_to_score,
    goals_for > 0 and goals_against > 0 AS both_teams_scored,
    goals_for + goals_against > 2 AS is_over_2_5_goals,
    CASE
        WHEN goals_for + goals_against = 0 THEN '0 goals'
        WHEN goals_for + goals_against = 1 THEN '1 goal'
        WHEN goals_for + goals_against = 2 THEN '2 goals'
        WHEN goals_for + goals_against = 3 THEN '3 goals'
        WHEN goals_for + goals_against = 4 THEN '4 goals'
        ELSE '5+ goals'
    END AS total_goals_bucket,
    went_to_shootout,
    score_reconciled,
    score_format,
    stadium,
    attendance,
    referee,
    url
FROM team_perspectives