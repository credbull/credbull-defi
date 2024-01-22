drop policy "Enable read for authenticated users only" on "public"."vaults";

create policy "Segregate vaults by tenants"
on "public"."vaults"
as permissive
for all
to authenticated
using ((((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) = 'partner'::text) AND (tenant = auth.uid()))))
with check ((((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) IS NULL) AND (tenant IS NULL)) OR ((((auth.jwt() -> 'app_metadata'::text) ->> 'entity_type'::text) = 'partner'::text) AND (tenant = auth.uid()))));



