alter table "public"."contracts_addresses" alter column "outdated" set default false;

update "public"."contracts_addresses" set "outdated" = false;

alter table "public"."contracts_addresses" alter column "outdated" set not null;


