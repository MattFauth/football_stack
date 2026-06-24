
  create view "football"."staging"."stg_appearances__dbt_tmp"
    
    
  as (
    with source as (
    select * from "football"."raw"."appearances"
),

renamed as (
    select
        -- IDs
        appearance_id,
        cast(game_id as integer) as game_id,
        cast(player_id as integer) as player_id,
        cast(nullif(player_club_id, '') as integer) as player_club_id,
        cast(nullif(player_current_club_id, '') as integer) as player_current_club_id,
        
        -- Strings
        player_name,
        competition_id,
        
        -- Dates
        cast(nullif(date, '') as date) as appearance_date,
        
        -- Numerics
        cast(nullif(yellow_cards, '') as integer) as yellow_cards,
        cast(nullif(red_cards, '') as integer) as red_cards,
        cast(nullif(goals, '') as integer) as goals,
        cast(nullif(assists, '') as integer) as assists,
        cast(nullif(minutes_played, '') as integer) as minutes_played

    from source
)

select * from renamed
  );