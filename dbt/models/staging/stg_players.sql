with source as (
    select * from {{ source('raw', 'players') }}
),

full_names as (
    select * from {{ ref('player_full_names') }}
),

renamed as (
    select
        -- IDs
        cast(s.player_id as integer) as player_id,
        cast(nullif(s.current_club_id, '') as integer) as current_club_id,
        cast(nullif(s.current_national_team_id, '') as integer) as current_national_team_id,
        s.current_club_domestic_competition_id,
        
        -- Names and Info
        s.name as popular_name,
        coalesce(fn.full_name, s.name) as player_name,
        coalesce(s.first_name, split_part(fn.full_name, ' ', 1)) as first_name,
        coalesce(
            nullif(s.last_name, s.name), 
            case 
                when position(' ' in fn.full_name) > 0 
                then substring(fn.full_name from position(' ' in fn.full_name) + 1)
                else fn.full_name 
            end,
            s.last_name
        ) as last_name,
        s.player_code,
        s.country_of_birth,
        s.city_of_birth,
        s.country_of_citizenship,
        
        -- Profile
        s.sub_position,
        s.position,
        s.foot,
        cast(nullif(s.height_in_cm, '') as integer) as height_in_cm,
        s.agent_name,
        s.url,
        s.image_url,
        
        -- Dates
        cast(nullif(s.date_of_birth, '') as date) as date_of_birth,
        cast(nullif(s.contract_expiration_date, '') as date) as contract_expiration_date,
        
        -- Numerics
        cast(nullif(s.last_season, '') as integer) as last_season,
        cast(nullif(s.international_caps, '') as integer) as international_caps,
        cast(nullif(s.international_goals, '') as integer) as international_goals,
        cast(s.market_value_in_eur as numeric) as market_value_in_eur,
        cast(s.highest_market_value_in_eur as numeric) as highest_market_value_in_eur

    from source s
    left join full_names fn on cast(s.player_id as integer) = cast(fn.player_id as integer)
)

select * from renamed
