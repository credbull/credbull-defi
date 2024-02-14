alter table "public"."contracts_addresses" drop constraint "contracts_addresses_pkey";

drop index if exists "public"."contracts_addresses_pkey";

alter table "public"."contracts_addresses" add column "outdated" boolean;

CREATE UNIQUE INDEX contracts_addresses_pkey ON public.contracts_addresses USING btree (id, contract_name, chain_id);

alter table "public"."contracts_addresses" add constraint "contracts_addresses_pkey" PRIMARY KEY using index "contracts_addresses_pkey";


