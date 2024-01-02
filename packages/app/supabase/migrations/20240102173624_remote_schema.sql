alter table "public"."kyc_events" add constraint "kyc_events_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."kyc_events" validate constraint "kyc_events_user_id_fkey";

create policy "Only users based on user_id"
on "public"."kyc_events"
as permissive
for all
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



