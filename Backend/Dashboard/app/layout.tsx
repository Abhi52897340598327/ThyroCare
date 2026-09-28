import type { Metadata } from "next";
import "./globals.css";
import LiveFoodAnalysisSummary from "@/components/LiveFoodAnalysisSummary";

export const metadata: Metadata = {
  title: "ThyroCare Dashboard",
  description: "Diet, thyroid health, and connected family care.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-slate-100 text-slate-900 antialiased font-sans">
        <LiveFoodAnalysisSummary />
        {children}
      </body>
    </html>
  );
}
