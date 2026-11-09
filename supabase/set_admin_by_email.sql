-- Run in Supabase SQL Editor after replacing the email below.
-- This only changes the role for the matching authenticated account.

do $$
declare
	target_email text := lower('ntx.duos0069@gmail.com');
	affected_rows integer;
begin
	update public.profiles as profile
	set role = 'admin'
	from auth.users as auth_user
	where profile.id = auth_user.id
		and lower(auth_user.email) = target_email;

	get diagnostics affected_rows = row_count;

	if affected_rows = 0 then
		raise exception 'No matching profile found. Check Authentication > Users and public.profiles first.';
	elsif affected_rows > 1 then
		raise exception 'More than one profile matched. No unique account was selected.';
	end if;
end $$;
