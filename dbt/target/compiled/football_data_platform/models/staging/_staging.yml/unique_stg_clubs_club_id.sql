
    
    

select
    club_id as unique_field,
    count(*) as n_records

from "football"."staging"."stg_clubs"
where club_id is not null
group by club_id
having count(*) > 1


