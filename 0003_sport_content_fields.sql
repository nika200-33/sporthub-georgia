-- ============================================================================
-- SportHub Georgia — 0003: sports ცხრილს აკლდა ველები, რომლებსაც აპლიკაცია
-- უკვე იყენებდა (Step 13-ის აღმოჩენა)
-- ============================================================================
-- Step 8-ში აშენდა Sport-ის გვერდი "About the sport" სექციით და SEO
-- მეტადატით, რომლებიც იყენებენ description_ka/description_en/
-- cover_image_url ველებს — მაგრამ 0001_init.sql-ის sports ცხრილს ეს
-- სვეტები არასდროს ჰქონია (mock მონაცემთა ფენა ამ განსხვავებას მალავდა,
-- რადგან TypeScript ტიპები ხელით იყო დაწერილი და არა რეალურ სქემასთან
-- დაკავშირებული). Step 13-ში, რეალურ სქემასთან დაკავშირებისას, ეს
-- შეუსაბამობა გამოჩნდა — ეს არის ზუსტად ის, რისთვისაც ღირს mock-იდან
-- რეალურ DB-ზე გადასვლა ადრეულ ეტაპზე.

alter table sports
  add column if not exists description_ka text,
  add column if not exists description_en text,
  add column if not exists cover_image_url text;
