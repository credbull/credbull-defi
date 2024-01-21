drop policy "Enable select for authenticated users only" on "public"."vault_distribution_configs";

drop policy "Enable select for authenticated users only" on "public"."vault_distribution_entities";

alter table "public"."vault_distribution_configs" add column "tenant" uuid;

alter table "public"."vault_distribution_entities" add column "tenant" uuid;

alter table "public"."vault_distribution_configs" add constraint "vault_distribution_configs_tenant_fkey" FOREIGN KEY (tenant) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."vault_distribution_configs" validate constraint "vault_distribution_configs_tenant_fkey";

alter table "public"."vault_distribution_entities" add constraint "vault_distribution_entities_tenant_fkey" FOREIGN KEY (tenant) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."vault_distribution_entities" validate constraint "vault_distribution_entities_tenant_fkey";

create policy "Segregate vaults by tenants"
on "public"."vault_distribution_configs"
as permissive
for all
to public
using ((((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) = 'partner'::text) AND (tenant = auth.uid()))))
with check ((((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) = 'partner'::text) AND (tenant = auth.uid()))));


create policy "Segregate vaults by tenants"
on "public"."vault_distribution_entities"
as permissive
for all
to public
using ((((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) = 'partner'::text) AND (tenant = auth.uid()))))
with check ((((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) = 'partner'::text) AND (tenant = auth.uid()))));



