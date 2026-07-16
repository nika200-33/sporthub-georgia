-- ============================================================================
-- SportHub Georgia — Storage Buckets & RLS (Step 13)
-- ============================================================================
-- გაუშვით ეს mvp-schema.sql-ის შემდეგ. საბოლოო production migration-ში
-- ეს უბრალოდ იქნება 0002_storage.sql supabase/migrations/ საქაღალდეში.
--
-- ᲛᲜᲘᲨᲕᲜᲔᲚᲝᲕᲐᲜᲘ: Storage-ს აქვს საკუთარი RLS storage.objects ცხრილზე —
-- ცალკე იმ RLS-ისგან, რომელიც ჩვენს public.* ცხრილებზე დავწერეთ. ეს
-- ხშირად დავიწყებული ნაბიჯია: ბაკეტის შექმნა თავისთავად არ იცავს
-- ფაილებს — policy-ების გარეშე ან ყველაფერი ღიაა, ან ყველაფერი დაკეტილი.

-- ----------------------------------------------------------------------------
-- BUCKETS
-- ----------------------------------------------------------------------------

-- images: publicly readable — ყდის სურათები, ლოგოები, აიქონები.
-- საჯარო, ქეშირებადი URL სჭირდება სისწრაფისა და SEO-სთვის (Open Graph
-- სურათები საძიებო/სოციალური გაზიარებისთვის).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('images', 'images', true, 5242880, array['image/png', 'image/jpeg', 'image/webp', 'image/gif'])
on conflict (id) do nothing;

-- documents: NOT public — PDF რეგლამენტები და მსგავსი დოკუმენტები.
-- ბაკეტი დაკეტილია პირდაპირი public URL-ისთვის, მაგრამ readable არის
-- ნებისმიერისთვის (მათ შორის ანონიმური ვიზიტორისთვისაც) მხოლოდ signed
-- URL-ის მეშვეობით (იხ. lib/supabase/storage.ts) — ეს არჩევანია
-- "controlled access" და "public content" შორის: დოკუმენტი თავისუფლად
-- გადმოსაწერია ვისაც ბმული ექნება, მაგრამ ბაკეტი არ არის პირდაპირ
-- დათვალიერებადი/გამოსაცნობი URL-ებით.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documents', 'documents', false, 10485760, array['application/pdf'])
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- RLS: images ბაკეტი
-- ----------------------------------------------------------------------------

create policy "images: საჯარო წაკითხვა"
  on storage.objects for select
  to public
  using (bucket_id = 'images');

create policy "images: ადმინებს შეუძლიათ ატვირთვა"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'images'
    and exists (select 1 from public.profiles where id = auth.uid())
  );

create policy "images: ადმინებს შეუძლიათ განახლება"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'images'
    and exists (select 1 from public.profiles where id = auth.uid())
  );

create policy "images: ადმინებს შეუძლიათ წაშლა"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'images'
    and exists (select 1 from public.profiles where id = auth.uid())
  );

-- ----------------------------------------------------------------------------
-- RLS: documents ბაკეტი
-- ----------------------------------------------------------------------------

-- წაკითხვა (signed URL-ის გენერირებისთვის საჭირო) ღიაა ყველასთვის,
-- ანონიმური ვიზიტორის ჩათვლით — თავად დოკუმენტები საჯარო კონტენტია
-- (ღონისძიების რეგლამენტი), უბრალოდ ბაკეტი არ არის პირდაპირ სახელით
-- დათვალიერებადი.
create policy "documents: წაკითხვა signed URL-ისთვის"
  on storage.objects for select
  to public
  using (bucket_id = 'documents');

create policy "documents: ადმინებს შეუძლიათ ატვირთვა"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'documents'
    and exists (select 1 from public.profiles where id = auth.uid())
  );

create policy "documents: ადმინებს შეუძლიათ წაშლა"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'documents'
    and exists (select 1 from public.profiles where id = auth.uid())
  );
