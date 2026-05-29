import Link from "next/link";

export default function Home() {
  return (
    <main
      style={{
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: "1.5rem",
        padding: "2rem",
        textAlign: "center",
      }}
    >
      <h1 style={{ fontSize: "2rem", fontWeight: 700 }}>
        Wings<span style={{ color: "var(--accent)" }}>IQ</span>
      </h1>
      <p style={{ color: "var(--dim)", maxWidth: "28rem" }}>
        AI-powered flight training — practice ATC radio calls with a live
        controller at KPHX.
      </p>
      <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
        <Link
          href="/simulator"
          style={{
            background: "var(--accent)",
            color: "#fff",
            padding: "0.75rem 1.5rem",
            borderRadius: "8px",
            fontWeight: 600,
            textDecoration: "none",
          }}
        >
          Open ATC Simulator
        </Link>
        <a
          href="/index.html"
          style={{
            border: "1px solid var(--border-bright)",
            color: "var(--white)",
            padding: "0.75rem 1.5rem",
            borderRadius: "8px",
            fontWeight: 500,
            textDecoration: "none",
          }}
        >
          Landing Page
        </a>
      </div>
    </main>
  );
}
