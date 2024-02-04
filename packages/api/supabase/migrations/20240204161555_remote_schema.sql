alter table "public"."vaults" drop column "closed_at";

alter table "public"."vaults" drop column "opened_at";

alter table "public"."vaults" add column "deposits_closed_at" timestamp with time zone not null;

alter table "public"."vaults" add column "deposits_opened_at" timestamp with time zone not null;

alter table "public"."vaults" add column "redemptions_closed_at" timestamp with time zone not null;

alter table "public"."vaults" add column "redemptions_opened_at" timestamp with time zone not null;


