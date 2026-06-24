
    
    

with child as (
    select player_id as from_field
    from "football"."marts"."fct_appearances"
    where player_id is not null
),

parent as (
    select player_id as to_field
    from "football"."marts"."dim_players"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


