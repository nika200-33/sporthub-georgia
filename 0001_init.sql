-- ============================================================================
-- SportHub Georgia — MVP SCHEMA (30-day launch scope)
-- PostgreSQL (Supabase)
--
-- სცოპი: მთავარი გვერდი, კალენდარი, ღონისძიების გვერდი, ადმინ პანელი,
-- ფედერაციის ავტორიზაცია, responsive დიზაინი.
-- ამოღებულია: სპორტსმენების პროფილები, კლუბები, სიახლეები, live შედეგები,
-- შეტყობინებები — ეს ყველაფერი მოგვიანებით დაემატება საჭიროებისამებრ.
-- ============================================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm"; -- საძიებო ველისთვის

-- ----------------------------------------------------------------------------
-- ENUMS
-- ----------------------------------------------------------------------------

-- MVP-ში მხოლოდ ორი როლია: ვინც ყველაფერს მართავს (თქვენ), და ვინც
-- მხოლოდ საკუთარ ფედერაციას მართავს.
create type user_role as enum ('platform_admin', 'federation_admin');

create type competition_status as enum ('draft', 'published', 'cancelled', 'completed');

-- ----------------------------------------------------------------------------
-- 1. profiles — მხოლოდ ადმინებისთვის (ფანებს/სპორტსმენებს ანგარიში არ სჭირდებათ
--    MVP-ში, რადგან რეგისტრაცია ხდება გარე ბმულით და არა საიტიდან)
-- ----------------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null,
  full_name text not null,
  -- federation_admin-ს უკავშირდება ეს ველი; platform_admin-სთვის NULL-ია
  federation_id uuid references federations(id) on delete set null,
  created_at timestamptz not null default now()
);
comment on table profiles is
  'ანგარიშები მხოლოდ ადმინებისთვის იქმნება ხელით (platform_admin ქმნის
   federation_admin-ის ანგარიშს) — არ არის თვითრეგისტრაცია MVP-ში.';

-- ----------------------------------------------------------------------------
-- 2. sports — ჩამონათვალი ფილტრებისთვის (ადმინი ამატებს რამდენიმეს დასაწყისში)
-- ----------------------------------------------------------------------------
create table sports (
  id uuid primary key default uuid_generate_v4(),
  slug text not null unique,
  name_ka text not null,
  name_en text,
  icon_url text,
  is_featured boolean not null default false, -- მთავარ გვერდზე "featured sports"-ისთვის
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 3. federations — თითო ფედერაცია, ერთი პროფილის გვერდით
-- ----------------------------------------------------------------------------
create table federations (
  id uuid primary key default uuid_generate_v4(),
  sport_id uuid not null references sports(id) on delete restrict,
  slug text not null unique,
  name_ka text not null,
  name_en text,
  description_ka text,
  logo_url text,
  website text,
  contact_email text,
  contact_phone text,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 4. competitions — ცენტრალური ცხრილი: კალენდარი + ღონისძიების გვერდი
-- ----------------------------------------------------------------------------
create table competitions (
  id uuid primary key default uuid_generate_v4(),
  slug text not null unique,

  sport_id uuid not null references sports(id) on delete restrict,
  federation_id uuid not null references federations(id) on delete restrict,

  title_ka text not null,
  title_en text,
  description_ka text,

  start_date timestamptz not null,
  end_date timestamptz,
  registration_deadline timestamptz,

  -- ასაკობრივი კატეგორია მარტივი ტექსტური ველია MVP-ში
  -- (მაგ: "U16", "სრულწლოვანი") — ცალკე ცხრილი ჯერ არ არის საჭირო
  age_category text,

  -- ღონისძიების ტიპი — თავისუფალი ტექსტი (მაგ: "ჩემპიონატი", "ტურნირი",
  -- "საერთაშორისო შეჯიბრება"). ცალკე enum არ ვაკეთებ, რადგან სპორტების
  -- მიხედვით ტიპები ძალიან განსხვავდება.
  event_type text,

  -- სჭირდება თუ არა წინასწარი რეგისტრაცია. აისახება event გვერდზე
  -- ბეჯის სახით და გამოსადეგია კალენდრის ფილტრადაც.
  registration_required boolean not null default false,

  -- უფასოა თუ ფასიანი დასწრება/მონაწილეობა. MVP-ში ფასის ველი და
  -- გადახდის სისტემა არ გვჭირდება — დეტალები registration_link-ზეა.
  is_free boolean not null default true,

  city text not null,
  venue_name text,
  address text, -- გამოიყენება Google Maps embed iframe-ისთვის, API key საჭირო არ არის

  organizer_name text,
  registration_link text,   -- გარე ბმული რეგისტრაციისთვის
  livestream_link text,
  cover_image_url text,

  -- PDF დოკუმენტების მასივი (რეგლამენტი, განრიგი) — ცალკე ცხრილის
  -- ნაცვლად, რადგან MVP-ში იშვიათად სჭირდება მეტი ვიდრე 2-3 ფაილი
  document_urls text[] not null default '{}',

  -- მარტივი ტექსტური ველი შედეგებისთვის (არა structured ცხრილი).
  -- ფედერაცია ჩასვამს ტექსტს ან ბმულს PDF-ზე შეჯიბრის დასრულების შემდეგ.
  results_summary text,

  status competition_status not null default 'draft',

  created_by uuid not null references profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- INDEXES — კალენდრის ფილტრებისთვის (სპორტი, ქალაქი, ფედერაცია, თარიღი)
-- ----------------------------------------------------------------------------
create index idx_competitions_status_date on competitions (status, start_date);
create index idx_competitions_sport on competitions (sport_id);
create index idx_competitions_federation on competitions (federation_id);
create index idx_competitions_city on competitions (city);
create index idx_competitions_title_search on competitions using gin (title_ka gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- TRIGGER — updated_at ავტომატურად
-- ----------------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_competitions_updated_at before update on competitions
  for each row execute function set_updated_at();

-- ----------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ----------------------------------------------------------------------------
alter table profiles enable row level security;
alter table sports enable row level security;
alter table federations enable row level security;
alter table competitions enable row level security;

-- დამხმარე ფუნქციები
create or replace function is_platform_admin()
returns boolean as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'platform_admin'
  );
$$ language sql security definer stable;

create or replace function is_federation_admin(target_federation_id uuid)
returns boolean as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'federation_admin'
      and federation_id = target_federation_id
  );
$$ language sql security definer stable;

-- ---- profiles: მხოლოდ საკუთარი ჩანაწერის ნახვა, platform_admin ხედავს ყველას
create policy "profiles: საკუთარის ან admin ნახვა" on profiles
  for select using (auth.uid() = id or is_platform_admin());
create policy "profiles: admin ქმნის ანგარიშებს" on profiles
  for insert with check (is_platform_admin());
create policy "profiles: admin მართავს ყველას" on profiles
  for all using (is_platform_admin());

-- ---- sports: საჯარო წაკითხვა, მხოლოდ admin წერს
create policy "sports: საჯარო წაკითხვა" on sports for select using (true);
create policy "sports: admin მართავს" on sports for all
  using (is_platform_admin()) with check (is_platform_admin());

-- ---- federations: საჯარო წაკითხვა, admin მართავს ყველას,
--      federation_admin-ს შეუძლია მხოლოდ საკუთარი პროფილის ინფოს რედაქტირება
create policy "federations: საჯარო წაკითხვა" on federations for select using (true);
create policy "federations: admin მართავს ყველას" on federations for all
  using (is_platform_admin()) with check (is_platform_admin());
create policy "federations: federation_admin ცვლის მხოლოდ თავისას" on federations
  for update using (is_federation_admin(id)) with check (is_federation_admin(id));

-- ---- competitions: საჯაროდ ჩანს მხოლოდ published;
--      draft ჩანს მხოლოდ ავტორ ფედერაციასა და admin-ს
create policy "competitions: საჯარო წაკითხვა" on competitions
  for select using (
    status = 'published' or is_platform_admin() or is_federation_admin(federation_id)
  );
create policy "competitions: admin მართავს ყველას" on competitions for all
  using (is_platform_admin()) with check (is_platform_admin());
create policy "competitions: federation_admin მართავს თავისას" on competitions
  for all using (is_federation_admin(federation_id))
  with check (is_federation_admin(federation_id));
