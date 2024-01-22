create type "public"."vault_entity_types" as enum ('activity_reward', 'treasury', 'vault', 'custodian', 'kyc_provider');

alter table "public"."vault_distribution_entities" alter column "type" set data type vault_entity_types using "type"::text::vault_entity_types;

drop type "public"."vault_distribution_entity_types";


