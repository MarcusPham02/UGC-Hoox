-- Persistent rate limiting table and check function.
-- Replaces the in-memory rate limiter in Edge Functions that resets on cold start.

create table if not exists public.rate_limits (
  user_id uuid not null,
  endpoint text not null,
  window_start timestamptz not null default now(),
  request_count int not null default 1,
  primary key (user_id, endpoint)
);

alter table public.rate_limits enable row level security;

-- No direct client access — only callable via the RPC function using service role.
-- RLS denies all by default (no policies = deny all).

-- Atomic check-and-increment function.
-- Returns true if the request is allowed, false if rate-limited.
create or replace function public.check_rate_limit(
  p_user_id uuid,
  p_endpoint text,
  p_max_requests int default 10,
  p_window_seconds int default 60
)
returns boolean
language plpgsql
security definer
as $$
declare
  v_count int;
  v_window_start timestamptz;
begin
  select request_count, window_start
    into v_count, v_window_start
    from public.rate_limits
   where user_id = p_user_id and endpoint = p_endpoint
   for update;

  if not found then
    -- First request — insert and allow.
    insert into public.rate_limits (user_id, endpoint, window_start, request_count)
    values (p_user_id, p_endpoint, now(), 1);
    return true;
  end if;

  if now() >= v_window_start + (p_window_seconds || ' seconds')::interval then
    -- Window expired — reset.
    update public.rate_limits
       set request_count = 1, window_start = now()
     where user_id = p_user_id and endpoint = p_endpoint;
    return true;
  end if;

  if v_count >= p_max_requests then
    -- Over limit.
    return false;
  end if;

  -- Increment and allow.
  update public.rate_limits
     set request_count = request_count + 1
   where user_id = p_user_id and endpoint = p_endpoint;
  return true;
end;
$$;
