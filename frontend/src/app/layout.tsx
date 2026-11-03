import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PatentPath | Invention discovery",
  description: "Explore invention records and discover related patent ideas with semantic search.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
