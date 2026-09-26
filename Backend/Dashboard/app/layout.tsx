import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "THYROCARE DASHBOARD",
  description: "Advanced Endocrinology & Thyroid Intelligence Platform"
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-slate-100 text-slate-900 antialiased font-sans">
        {children}
      </body>
    </html>
  );
}
