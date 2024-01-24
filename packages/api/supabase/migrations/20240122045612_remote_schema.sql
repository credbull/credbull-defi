drop policy "Segregate vaults by tenants" on "public"."vault_distribution_configs";

drop policy "Segregate vaults by tenants" on "public"."vault_distribution_entities";

drop policy "Segregate vaults by tenants" on "public"."vaults";

create policy "Segregate vaults by tenants"
on "public"."vault_distribution_configs"
as permissive
for all
to public
using ((((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) = 'channel'::text) AND (tenant = auth.uid()))))
with check ((((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) = 'channel'::text) AND (tenant = auth.uid()))));


create policy "Segregate vaults by tenants"
on "public"."vault_distribution_entities"
as permissive
for all
to public
using ((((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) = 'channel'::text) AND (tenant = auth.uid()))))
with check ((((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) = 'channel'::text) AND (tenant = auth.uid()))));


create policy "Segregate vaults by tenants"
on "public"."vaults"
as permissive
for all
to authenticated
using ((((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) = 'channel'::text) AND (tenant = auth.uid()))))
with check ((((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'partner_type'::text) = 'channel'::text) AND (tenant = auth.uid()))));



