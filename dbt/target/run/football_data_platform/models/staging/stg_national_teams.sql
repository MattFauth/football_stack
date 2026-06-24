
  create view "football"."staging"."stg_national_teams__dbt_tmp"
    
    
  as (
    with source as (
    select * from "football"."raw"."national_teams"
),

renamed as (
    select
        -- IDs
        cast(national_team_id as integer) as national_team_id,
        cast(country_id as integer) as country_id,
        
        -- Strings
        name,
        team_code,
        country_name,
        country_code,
        confederation,
        team_image_url,
        coach_name,
        url,
        
        -- Numerics
        cast(nullif(squad_size, '') as integer) as squad_size,
        cast(nullif(average_age, '') as numeric) as average_age,
        cast(nullif(foreigners_number, '') as integer) as foreigners_number,
        cast(nullif(foreigners_percentage, '') as numeric) as foreigners_percentage,
        cast(nullif(total_market_value, '') as numeric) as total_market_value,
        cast(nullif(fifa_ranking, '') as integer) as fifa_ranking,
        cast(nullif(last_season, '') as integer) as last_season

    from source
)

select * from renamed
  );