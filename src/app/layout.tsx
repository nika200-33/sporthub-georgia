import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "SportHub Georgia",
  description: "SportHub Georgia Application",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ka">
      <body>{children}</body>
    </html>
  );
}
