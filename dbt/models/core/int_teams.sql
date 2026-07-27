with clubs as (
    select
        club_id as team_id,
        name as team_name,
        club_code as team_code,
        'club' as team_type,
        false as is_inferred,
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
        false as is_inferred,
        total_market_value,
        squad_size,
        average_age,
        foreigners_number,
        foreigners_percentage,
        coach_name,
        last_season,
        url
    from {{ ref('stg_national_teams') }}
),

current_teams as (
    select * from clubs
    union all
    select * from national_teams
),

game_teams as (
    select
        home_club_id as team_id,
        nullif(home_club_name, '') as team_name,
        game_date,
        game_id
    from {{ ref('stg_games') }}

    union all

    select
        away_club_id as team_id,
        nullif(away_club_name, '') as team_name,
        game_date,
        game_id
    from {{ ref('stg_games') }}
),

ranked_historical_teams as (
    select
        team_id,
        team_name,
        row_number() over (
            partition by team_id
            order by
                case when team_name is not null then 0 else 1 end,
                game_date desc,
                game_id desc
        ) as name_priority
    from game_teams
    where team_id is not null
),

historical_teams as (
    select
        h.team_id,
        coalesce(h.team_name, 'Unknown team ' || h.team_id::text) as team_name,
        cast(null as text) as team_code,
        'club' as team_type,
        true as is_inferred,
        cast(null as numeric) as total_market_value,
        cast(null as integer) as squad_size,
        cast(null as numeric) as average_age,
        cast(null as integer) as foreigners_number,
        cast(null as numeric) as foreigners_percentage,
        cast(null as text) as coach_name,
        cast(null as integer) as last_season,
        cast(null as text) as url
    from ranked_historical_teams h
    left join current_teams c on h.team_id = c.team_id
    where h.name_priority = 1
      and c.team_id is null
)

select * from current_teams
union all
select * from historical_teams
