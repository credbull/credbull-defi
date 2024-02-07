alter table "public"."vaults" alter column "type" drop default;

alter type "public"."vault_type" rename to "vault_type__old_version_to_be_dropped";

create type "public"."vault_type" as enum ('fixed_yield', 'fixed_yield_upside');

alter table "public"."vaults" alter column type type "public"."vault_type" using type::text::"public"."vault_type";

alter table "public"."vaults" alter column "type" set default 'fixed_yield'::vault_type;

drop type "public"."vault_type__old_version_to_be_dropped";


