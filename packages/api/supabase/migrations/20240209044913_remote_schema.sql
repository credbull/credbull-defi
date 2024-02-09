alter table "public"."contracts_addresses" drop constraint "contracts_addresses_pkey";

drop index if exists "public"."contracts_addresses_pkey";

CREATE UNIQUE INDEX contracts_addresses_contract_name_key ON public.contracts_addresses USING btree (contract_name);

CREATE UNIQUE INDEX contracts_addresses_pkey ON public.contracts_addresses USING btree (id, contract_name);

alter table "public"."contracts_addresses" add constraint "contracts_addresses_pkey" PRIMARY KEY using index "contracts_addresses_pkey";

alter table "public"."contracts_addresses" add constraint "contracts_addresses_contract_name_key" UNIQUE using index "contracts_addresses_contract_name_key";


