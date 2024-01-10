alter table "public"."vaults" drop constraint "vaults_owner_fkey";

alter table "public"."vaults" drop column "owner";

alter table "public"."vaults" add column "tenant" uuid;

alter table "public"."vaults" add constraint "vaults_tenant_fkey" FOREIGN KEY (tenant) REFERENCES auth.users(id) not valid;

alter table "public"."vaults" validate constraint "vaults_tenant_fkey";


