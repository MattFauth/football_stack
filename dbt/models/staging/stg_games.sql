with source as (
    select * from {{ source('raw', 'games') }}
),

renamed as (
    select
        -- IDs
        cast(game_id as integer) as game_id,
        cast(nullif(home_club_id, '') as integer) as home_club_id,
        cast(nullif(away_club_id, '') as integer) as away_club_id,
        
        -- Strings
        competition_id,
        round,
        home_club_manager_name,
        away_club_manager_name,
        stadium,
        referee,
        url,
        home_club_formation,
        away_club_formation,
        home_club_name,
        away_club_name,
        aggregate,
        competition_type,
        
        -- Dates
        cast(nullif(date, '') as date) as game_date,
        
        -- Numerics
        cast(nullif(season, '') as integer) as season,
        cast(nullif(home_club_goals, '') as integer) as home_club_goals,
        cast(nullif(away_club_goals, '') as integer) as away_club_goals,
        cast(nullif(home_club_position, '') as integer) as home_club_position,
        cast(nullif(away_club_position, '') as integer) as away_club_position,
        cast(nullif(attendance, '') as integer) as attendance

    from source
)

select * from renamed
