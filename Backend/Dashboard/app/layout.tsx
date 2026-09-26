import type { Metadata } from "next";
import "./globals.css";
import { Navbar } from "@/components/Navbar";

export const metadata: Metadata = {
  title: "ThyroCare V3 — Clinical, Family & Patient Platform",
  description: "Comprehensive thyroid monitoring platform for clinicians, patients, and families"
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-slate-50 text-slate-900 antialiased">
        <Navbar />
        {children}
      </body>
    </html>
  );
}
