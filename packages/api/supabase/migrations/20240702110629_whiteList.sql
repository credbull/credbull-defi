create type "public"."whitelist_event" as enum ('processing', 'accepted', 'rejected');

drop policy "Only users based on user_id" on "public"."kyc_events";

revoke delete on table "public"."kyc_events" from "anon";

revoke insert on table "public"."kyc_events" from "anon";

revoke references on table "public"."kyc_events" from "anon";

revoke select on table "public"."kyc_events" from "anon";

revoke trigger on table "public"."kyc_events" from "anon";

revoke truncate on table "public"."kyc_events" from "anon";

revoke update on table "public"."kyc_events" from "anon";

revoke delete on table "public"."kyc_events" from "authenticated";

revoke insert on table "public"."kyc_events" from "authenticated";

revoke references on table "public"."kyc_events" from "authenticated";

revoke select on table "public"."kyc_events" from "authenticated";

revoke trigger on table "public"."kyc_events" from "authenticated";

revoke truncate on table "public"."kyc_events" from "authenticated";

revoke update on table "public"."kyc_events" from "authenticated";

revoke delete on table "public"."kyc_events" from "service_role";

revoke insert on table "public"."kyc_events" from "service_role";

revoke references on table "public"."kyc_events" from "service_role";

revoke select on table "public"."kyc_events" from "service_role";

revoke trigger on table "public"."kyc_events" from "service_role";

revoke truncate on table "public"."kyc_events" from "service_role";

revoke update on table "public"."kyc_events" from "service_role";

alter table "public"."kyc_events" drop constraint "kyc_events_user_id_fkey";

alter table "public"."kyc_events" drop constraint "kyc_events_pkey";

drop index if exists "public"."kyc_events_pkey";

drop table "public"."kyc_events";

alter type "public"."vault_entity_types" rename to "vault_entity_types__old_version_to_be_dropped";

create type "public"."vault_entity_types" as enum ('activity_reward', 'treasury', 'vault', 'custodian', 'whitelist_provider');

create table "public"."whitelist_events" (
    "id" bigint generated by default as identity not null,
    "user_id" uuid not null,
    "address" text not null,
    "event_name" whitelist_event not null,
    "created_at" timestamp with time zone not null default now()
);


alter table "public"."whitelist_events" enable row level security;

alter table "public"."vault_entities" alter column type type "public"."vault_entity_types" using type::text::"public"."vault_entity_types";

drop type "public"."vault_entity_types__old_version_to_be_dropped";

drop type "public"."kyc_event";

CREATE UNIQUE INDEX whitelist_events_pkey ON public.whitelist_events USING btree (id);

alter table "public"."whitelist_events" add constraint "whitelist_events_pkey" PRIMARY KEY using index "whitelist_events_pkey";

alter table "public"."whitelist_events" add constraint "whitelist_events_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."whitelist_events" validate constraint "whitelist_events_user_id_fkey";

grant delete on table "public"."whitelist_events" to "anon";

grant insert on table "public"."whitelist_events" to "anon";

grant references on table "public"."whitelist_events" to "anon";

grant select on table "public"."whitelist_events" to "anon";

grant trigger on table "public"."whitelist_events" to "anon";

grant truncate on table "public"."whitelist_events" to "anon";

grant update on table "public"."whitelist_events" to "anon";

grant delete on table "public"."whitelist_events" to "authenticated";

grant insert on table "public"."whitelist_events" to "authenticated";

grant references on table "public"."whitelist_events" to "authenticated";

grant select on table "public"."whitelist_events" to "authenticated";

grant trigger on table "public"."whitelist_events" to "authenticated";

grant truncate on table "public"."whitelist_events" to "authenticated";

grant update on table "public"."whitelist_events" to "authenticated";

grant delete on table "public"."whitelist_events" to "service_role";

grant insert on table "public"."whitelist_events" to "service_role";

grant references on table "public"."whitelist_events" to "service_role";

grant select on table "public"."whitelist_events" to "service_role";

grant trigger on table "public"."whitelist_events" to "service_role";

grant truncate on table "public"."whitelist_events" to "service_role";

grant update on table "public"."whitelist_events" to "service_role";

create policy "Only users based on user_id"
on "public"."whitelist_events"
as permissive
for all
to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



