-- Add sync_auth_to_public_user() function to match dev
CREATE OR REPLACE FUNCTION public.sync_auth_to_public_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  -- Only sync on auth.users INSERT operations
  -- This creates a corresponding public.users record when someone first authenticates
  INSERT INTO public.users (id, email, created_at, updated_at)
  VALUES (NEW.id, NEW.email, NEW.created_at, NEW.updated_at)
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = EXCLUDED.updated_at;
  
  RETURN NEW;
END;
$function$; 