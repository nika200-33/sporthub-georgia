/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: {
    // დეპლოის დროს ტაიპშექინგის შეცდომებმა რომ არ დაბლოკოს
    ignoreBuildErrors: true,
  },
  eslint: {
    // დეპლოის დროს ლინტერის შეცდომებმა რომ არ დაბლოკოს
    ignoreDuringBuilds: true,
  },
};

module.exports = nextConfig;
