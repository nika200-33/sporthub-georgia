import type { NextConfig } from "next";

const SUPABASE_HOSTNAME_WILDCARD = "*.supabase.co";

/**
 * Content-Security-Policy — პრაგმატულად მკაცრი (არა nonce-based, რაც
 * მოითხოვდა middleware-ის მნიშვნელოვან გართულებას ყოველ request-ზე
 * nonce-ის გენერირებისთვის). 'unsafe-inline' script/style-ისთვის
 * საჭიროა Next.js-ის hydration-ის ჩაშენებული inline script-ებისთვის —
 * ეს არის სტანდარტული, ფართოდ მიღებული კომპრომისი production Next.js
 * აპებში nonce-ის ინფრასტრუქტურის გარეშე.
 */
const contentSecurityPolicy = `
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: blob: https://*.supabase.co;
  font-src 'self' data:;
  connect-src 'self' https://*.supabase.co wss://*.supabase.co;
  frame-src 'self' https://www.google.com;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
`
  .replace(/\s{2,}/g, " ")
  .trim();

const securityHeaders = [
  { key: "Content-Security-Policy", value: contentSecurityPolicy },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(self), interest-cohort=()",
  },
  // HSTS — მხოლოდ production-ისთვის აზრი აქვს (localhost-ზე HTTPS არ გვაქვს)
  ...(process.env.NODE_ENV === "production"
    ? [{ key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" }]
    : []),
];

const nextConfig: NextConfig = {
  images: {
    // ატვირთული სურათები (ლოგოები, cover images) ინახება Supabase Storage-ში.
    remotePatterns: [
      {
        protocol: "https",
        hostname: SUPABASE_HOSTNAME_WILDCARD,
        pathname: "/storage/v1/object/public/**",
      },
    ],
    // თანამედროვე ფორმატები — უფრო მცირე ფაილის ზომა იმავე ხარისხზე.
    // Next.js ავტომატურად აბრუნებს ბრაუზერისთვის საუკეთესო მხარდაჭერილს.
    formats: ["image/avif", "image/webp"],
  },

  // ტიპის შემოწმების შეცდომები ააფეთქოს build-ი — production-ისთვის
  // მნიშვნელოვანია არასწორი ტიპების დეპლოიმენტში არ გაშვება.
  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: false,
  },

  // მკაცრი რეჟიმი დეველოპმენტში აჩვენებს პოტენციურ პრობლემებს ადრეულად.
  reactStrictMode: true,

  // "X-Powered-By: Next.js" header-ის მოხსნა — უსაფრთხოების მცირე, მაგრამ
  // ფასიანი გაუმჯობესება (ტექნოლოგიის ვერსიის არ გაცხადება საჯაროდ).
  poweredByHeader: false,

  // Bundle ოპტიმიზაცია: lucide-react-ის მსგავს დიდ icon ბიბლიოთეკებს
  // Next.js ავტომატურად "tree-shake"-ავს ამ პარამეტრით — მხოლოდ
  // რეალურად გამოყენებული აიქონები შედის საბოლოო bundle-ში.
  experimental: {
    optimizePackageImports: ["lucide-react", "date-fns"],
  },

  async headers() {
    return [
      {
        // ყველა route-ზე ვრცელდება უსაფრთხოების header-ები.
        source: "/:path*",
        headers: securityHeaders,
      },
      {
        // Storage-ის public სურათებზე დიდი ხნით ქეშირება — ეს ფაილები
        // არასდროს იცვლება ერთი და იმავე ბილიკზე (ახალი ატვირთვა =
        // ახალი, უნიკალური ბილიკი, იხ. lib/storage-client.ts).
        source: "/_next/image(.*)",
        headers: [{ key: "Cache-Control", value: "public, max-age=31536000, immutable" }],
      },
    ];
  },
};

export default nextConfig;
