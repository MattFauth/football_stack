
    
    

select
    national_team_id as unique_field,
    count(*) as n_records

from "football"."staging"."stg_national_teams"
where national_team_id is not null
group by national_team_id
having count(*) > 1


