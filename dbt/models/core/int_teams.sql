with clubs as (
    select
        club_id as team_id,
        name as team_name,
        club_code as team_code,
        'club' as team_type,
        total_market_value,
        squad_size,
        average_age,
        foreigners_number,
        foreigners_percentage,
        coach_name,
        last_season,
        url
    from {{ ref('stg_clubs') }}
),

national_teams as (
    select
        national_team_id as team_id,
        name as team_name,
        team_code,
        'national_team' as team_type,
        total_market_value,
        squad_size,
        average_age,
        foreigners_number,
        foreigners_percentage,
        coach_name,
        last_season,
        url
    from {{ ref('stg_national_teams') }}
)

select * from clubs
union all
select * from national_teams
