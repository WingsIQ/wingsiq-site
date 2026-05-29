import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "WingsIQ — ATC Voice Simulator",
  description:
    "Practice ATC radio calls with AI at Phoenix Sky Harbor (KPHX)",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
