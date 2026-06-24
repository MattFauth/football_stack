
  create view "football"."staging"."stg_competitions__dbt_tmp"
    
    
  as (
    with source as (
    select * from "football"."raw"."competitions"
)

select
    competition_id,
    competition_code,
    name as competition_name,
    sub_type,
    type as competition_type,
    country_id,
    country_name,
    domestic_league_code,
    confederation,
    total_clubs,
    url
from source
  );