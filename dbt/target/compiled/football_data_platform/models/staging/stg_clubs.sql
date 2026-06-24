with source as (
    select * from "football"."raw"."clubs"
),

renamed as (
    select
        -- IDs
        cast(club_id as integer) as club_id,
        
        -- Strings
        club_code,
        name,
        domestic_competition_id,
        stadium_name,
        coach_name,
        net_transfer_record,
        filename,
        url,
        
        -- Numerics
        cast(nullif(squad_size, '') as integer) as squad_size,
        cast(nullif(average_age, '') as numeric) as average_age,
        cast(nullif(foreigners_number, '') as integer) as foreigners_number,
        cast(nullif(foreigners_percentage, '') as numeric) as foreigners_percentage,
        cast(nullif(national_team_players, '') as integer) as national_team_players,
        cast(nullif(stadium_seats, '') as integer) as stadium_seats,
        cast(nullif(total_market_value, '') as numeric) as total_market_value,
        cast(nullif(last_season, '') as integer) as last_season

    from source
)

select * from renamed