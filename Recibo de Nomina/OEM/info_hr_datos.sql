
select * from per_all_people_F
where 1=1
and person_id=7507

select * from per_all_assignments_f 
where 1=1
and person_id=7507

select * from hr_soft_coding_keyflex
where soft_coding_keyflex_id=4075

--informacion estatutaria>>>>>>estidada de informacion gubernamental

select * from hr_all_organization_units
where organization_id=729

-----numero de seguridad social----------
select org_information1 from hr_organization_information hoi2 
where organization_id=729
and org_information_context='MX_SOC_SEC_DETAILS'

