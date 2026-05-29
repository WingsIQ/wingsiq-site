# Run this on your Windows PC in PowerShell:
#   Set-ExecutionPolicy -Scope Process Bypass
#   cd path\to\wingsiq-site\scripts
#   .\install-simulator-files.ps1
#
# Creates ATC simulator files in wingsiq-app.

$Root = "C:\Users\Chris London\Documents\wingsiq-app"

$dirs = @(
  "$Root\app\api\transcribe",
  "$Root\app\api\atc",
  "$Root\app\api\speak",
  "$Root\app\simulator"
)
foreach ($d in $dirs) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}

@'
import { NextResponse } from "next/server";
import OpenAI from "openai";

export async function POST(request: Request) {
  try {
    const formData = await request.formData();
    const audio = formData.get("audio");

    if (!audio || !(audio instanceof Blob)) {
      return NextResponse.json(
        { error: "Missing audio file. Send multipart field 'audio'." },
        { status: 400 },
      );
    }

    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    const file = new File([audio], "recording.webm", {
      type: audio.type || "audio/webm",
    });

    const transcription = await openai.audio.transcriptions.create({
      file,
      model: "whisper-1",
      language: "en",
    });

    return NextResponse.json({ transcript: transcription.text });
  } catch (error) {
    console.error("Transcribe error:", error);
    return NextResponse.json(
      { error: "Failed to transcribe audio" },
      { status: 500 },
    );
  }
}
'@ | Set-Content -Path "$Root\app\api\transcribe\route.ts" -Encoding utf8NoBOM

@'
import Anthropic from "@anthropic-ai/sdk";
import { NextResponse } from "next/server";

const SYSTEM_PROMPT =
  "You are an ATC controller at Phoenix Sky Harbor (KPHX). Respond exactly as a real controller would using standard phraseology, brevity codes, callsigns, altitudes, headings, frequencies and squawk codes. Stay in character. If the pilot readback is incorrect, correct them. Keep responses concise and realistic.";

type HistoryMessage = {
  role: "pilot" | "atc";
  content: string;
};

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const transcript =
      typeof body.transcript === "string" ? body.transcript.trim() : "";
    const history: HistoryMessage[] = Array.isArray(body.history)
      ? body.history
      : [];

    if (!transcript) {
      return NextResponse.json(
        { error: "Missing transcript text" },
        { status: 400 },
      );
    }

    const messages: Anthropic.MessageParam[] = [
      ...history.map((msg) => ({
        role: msg.role === "atc" ? ("assistant" as const) : ("user" as const),
        content: msg.content,
      })),
      { role: "user", content: transcript },
    ];

    const anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });

    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 300,
      system: SYSTEM_PROMPT,
      messages,
    });

    const text = response.content
      .filter((block) => block.type === "text")
      .map((block) => block.text)
      .join("")
      .trim();

    return NextResponse.json({ response: text });
  } catch (error) {
    console.error("ATC error:", error);
    return NextResponse.json(
      { error: "Failed to generate ATC response" },
      { status: 500 },
    );
  }
}
'@ | Set-Content -Path "$Root\app\api\atc\route.ts" -Encoding utf8NoBOM

@'
import { ElevenLabsClient } from "elevenlabs";
import { NextResponse } from "next/server";
import type { Readable } from "stream";

const ATC_VOICE_ID = "pNInz6obpgDQGcFmaJgB";

async function readableToBuffer(stream: Readable): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const text = typeof body.text === "string" ? body.text.trim() : "";

    if (!text) {
      return NextResponse.json({ error: "Missing text" }, { status: 400 });
    }

    const elevenlabs = new ElevenLabsClient({
      apiKey: process.env.ELEVENLABS_API_KEY,
    });

    const audioStream = await elevenlabs.textToSpeech.convert(ATC_VOICE_ID, {
      text,
      model_id: "eleven_turbo_v2_5",
    });

    const audioBuffer = await readableToBuffer(audioStream);
    const audioBytes = new Uint8Array(audioBuffer);

    return new NextResponse(audioBytes, {
      headers: {
        "Content-Type": "audio/mpeg",
        "Content-Length": String(audioBytes.length),
      },
    });
  } catch (error) {
    console.error("Speak error:", error);
    return NextResponse.json(
      { error: "Failed to synthesize speech" },
      { status: 500 },
    );
  }
}
'@ | Set-Content -Path "$Root\app\api\speak\route.ts" -Encoding utf8NoBOM

# simulator.module.css — required by page.tsx (includes theme variables)
@'
:global(:root) {
  --navy: #060910;
  --deep: #0b1120;
  --card: #0f1829;
  --accent: #3b7bf7;
  --accent-bright: #5b9bff;
  --white: #eef4ff;
  --dim: #5b7ba8;
  --dimmer: #3a4e6a;
  --border: rgba(59, 123, 247, 0.15);
  --border-bright: rgba(59, 123, 247, 0.35);
  --danger: #f87171;
}

.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--navy);
}

.header {
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--border);
  backdrop-filter: blur(20px);
  background: rgba(6, 9, 16, 0.85);
}

.headerTop {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}

.logo {
  font-size: 1.25rem;
  font-weight: 700;
  letter-spacing: -0.02em;
}

.logo span {
  color: var(--accent);
}

.backLink {
  font-size: 0.875rem;
  color: var(--dim);
  text-decoration: none;
}

.backLink:hover {
  color: var(--white);
}

.title {
  margin-top: 0.5rem;
  font-family: ui-monospace, "SF Mono", monospace;
  font-size: 0.75rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--accent);
}

.main {
  flex: 1;
  display: flex;
  flex-direction: column;
  max-width: 720px;
  width: 100%;
  margin: 0 auto;
  padding: 1.5rem;
  gap: 1.25rem;
}

.radioPanel {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  min-height: 280px;
}

.message {
  border-radius: 12px;
  padding: 1rem 1.25rem;
  border: 1px solid var(--border);
}

.messagePilot {
  background: rgba(59, 123, 247, 0.08);
  border-color: var(--border-bright);
}

.messageAtc {
  background: var(--card);
}

.messageLabel {
  font-family: ui-monospace, "SF Mono", monospace;
  font-size: 0.7rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--dim);
  margin-bottom: 0.5rem;
}

.messageText {
  font-size: 1.05rem;
  line-height: 1.55;
  color: var(--white);
}

.messagePlaceholder {
  color: var(--dimmer);
  font-style: italic;
}

.statusBar {
  text-align: center;
  font-size: 0.875rem;
  color: var(--dim);
  min-height: 1.25rem;
}

.statusBarActive {
  color: var(--accent-bright);
}

.statusBarError {
  color: var(--danger);
}

.pttSection {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 0 0.5rem;
}

.pttButton {
  width: 140px;
  height: 140px;
  border-radius: 50%;
  border: 3px solid var(--border-bright);
  background: linear-gradient(145deg, var(--card) 0%, var(--deep) 100%);
  color: var(--white);
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  touch-action: none;
  user-select: none;
  transition:
    transform 0.1s ease,
    box-shadow 0.15s ease,
    border-color 0.15s ease,
    background 0.15s ease;
  box-shadow: 0 8px 32px rgba(59, 123, 247, 0.15);
}

.pttButton:hover:not(:disabled) {
  border-color: var(--accent);
}

.pttButton:active:not(:disabled),
.pttButtonRecording {
  transform: scale(0.96);
  border-color: var(--danger);
  background: linear-gradient(145deg, #2a1520 0%, var(--deep) 100%);
  box-shadow: 0 0 24px rgba(248, 113, 113, 0.35);
}

.pttButton:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pttHint {
  font-size: 0.8rem;
  color: var(--dimmer);
  text-align: center;
}

.history {
  border-top: 1px solid var(--border);
  padding-top: 1rem;
}

.historyTitle {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--dim);
  margin-bottom: 0.75rem;
}

.historyItem {
  font-size: 0.85rem;
  color: var(--dim);
  padding: 0.35rem 0;
  border-bottom: 1px solid rgba(59, 123, 247, 0.06);
}

.historyItem strong {
  color: var(--accent-bright);
  font-weight: 600;
}
'@ | Set-Content -Path "$Root\app\simulator\simulator.module.css" -Encoding utf8NoBOM

@'
"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import styles from "./simulator.module.css";

type HistoryMessage = { role: "pilot" | "atc"; content: string };
type Status = "idle" | "recording" | "processing";

export default function SimulatorPage() {
  const [status, setStatus] = useState<Status>("idle");
  const [pilotText, setPilotText] = useState("");
  const [atcText, setAtcText] = useState("");
  const [history, setHistory] = useState<HistoryMessage[]>([]);
  const [statusMessage, setStatusMessage] = useState(
    "Hold the button and transmit",
  );
  const [error, setError] = useState<string | null>(null);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const streamRef = useRef<MediaStream | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const ensureMic = useCallback(async () => {
    if (streamRef.current) return streamRef.current;
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    streamRef.current = stream;
    return stream;
  }, []);

  useEffect(() => {
    return () => {
      streamRef.current?.getTracks().forEach((t) => t.stop());
      if (audioRef.current) {
        audioRef.current.pause();
        URL.revokeObjectURL(audioRef.current.src);
      }
    };
  }, []);

  const playAtcAudio = async (text: string) => {
    const res = await fetch("/api/speak", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.error || "Failed to play ATC audio");
    }
    const blob = await res.blob();
    if (audioRef.current) {
      audioRef.current.pause();
      URL.revokeObjectURL(audioRef.current.src);
    }
    const url = URL.createObjectURL(blob);
    const audio = new Audio(url);
    audioRef.current = audio;
    await audio.play();
  };

  const processRecording = async (blob: Blob) => {
    setStatus("processing");
    setError(null);
    setStatusMessage("Transcribing…");

    const formData = new FormData();
    formData.append("audio", blob, "recording.webm");

    const transcribeRes = await fetch("/api/transcribe", {
      method: "POST",
      body: formData,
    });
    if (!transcribeRes.ok) {
      const data = await transcribeRes.json().catch(() => ({}));
      throw new Error(data.error || "Transcription failed");
    }
    const { transcript } = await transcribeRes.json();
    const pilotTranscript = (transcript as string).trim();
    if (!pilotTranscript) {
      throw new Error("No speech detected. Try again.");
    }

    setPilotText(pilotTranscript);
    setStatusMessage("Contacting tower…");

    const atcRes = await fetch("/api/atc", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ transcript: pilotTranscript, history }),
    });
    if (!atcRes.ok) {
      const data = await atcRes.json().catch(() => ({}));
      throw new Error(data.error || "ATC response failed");
    }
    const { response } = await atcRes.json();
    const atcResponse = (response as string).trim();

    setAtcText(atcResponse);
    setHistory((prev) => [
      ...prev,
      { role: "pilot", content: pilotTranscript },
      { role: "atc", content: atcResponse },
    ]);

    setStatusMessage("Tower responding…");
    await playAtcAudio(atcResponse);
    setStatusMessage("Hold the button and transmit");
  };

  const startRecording = async () => {
    if (status !== "idle") return;
    try {
      setError(null);
      const stream = await ensureMic();
      const mimeType = MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
        ? "audio/webm;codecs=opus"
        : "audio/webm";
      const recorder = new MediaRecorder(stream, { mimeType });
      chunksRef.current = [];
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };
      recorder.onstop = async () => {
        const blob = new Blob(chunksRef.current, { type: mimeType });
        if (blob.size < 1000) {
          setStatus("idle");
          setStatusMessage("Hold the button and transmit");
          setError("Recording too short. Hold longer and speak clearly.");
          return;
        }
        try {
          await processRecording(blob);
        } catch (err) {
          setError(err instanceof Error ? err.message : "Something went wrong");
          setStatusMessage("Hold the button and transmit");
        } finally {
          setStatus("idle");
        }
      };
      mediaRecorderRef.current = recorder;
      recorder.start();
      setStatus("recording");
      setStatusMessage("Transmitting…");
    } catch {
      setError("Microphone access denied or unavailable.");
    }
  };

  const stopRecording = () => {
    if (
      status !== "recording" ||
      !mediaRecorderRef.current ||
      mediaRecorderRef.current.state === "inactive"
    ) {
      return;
    }
    mediaRecorderRef.current.stop();
  };

  const isBusy = status === "processing";

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <div className={styles.headerTop}>
          <div className={styles.logo}>
            Wings<span>IQ</span>
          </div>
          <Link href="/" className={styles.backLink}>
            ← Home
          </Link>
        </div>
        <p className={styles.title}>KPHX — Phoenix Sky Harbor · Ground / Tower</p>
      </header>

      <main className={styles.main}>
        <div className={styles.radioPanel}>
          <div className={`${styles.message} ${styles.messagePilot}`}>
            <div className={styles.messageLabel}>Pilot (you)</div>
            <p className={styles.messageText}>
              {pilotText || (
                <span className={styles.messagePlaceholder}>
                  Your transmission will appear here…
                </span>
              )}
            </p>
          </div>

          <div className={`${styles.message} ${styles.messageAtc}`}>
            <div className={styles.messageLabel}>ATC — KPHX</div>
            <p className={styles.messageText}>
              {atcText || (
                <span className={styles.messagePlaceholder}>
                  Controller response will appear here…
                </span>
              )}
            </p>
          </div>
        </div>

        <p
          className={`${styles.statusBar} ${
            status === "recording" ? styles.statusBarActive : ""
          } ${error ? styles.statusBarError : ""}`}
        >
          {error || statusMessage}
        </p>

        <section className={styles.pttSection}>
          <button
            type="button"
            className={`${styles.pttButton} ${
              status === "recording" ? styles.pttButtonRecording : ""
            }`}
            disabled={isBusy}
            onMouseDown={(e) => {
              e.preventDefault();
              void startRecording();
            }}
            onMouseUp={(e) => {
              e.preventDefault();
              stopRecording();
            }}
            onMouseLeave={() => {
              if (status === "recording") stopRecording();
            }}
            onTouchStart={(e) => {
              e.preventDefault();
              void startRecording();
            }}
            onTouchEnd={(e) => {
              e.preventDefault();
              stopRecording();
            }}
          >
            {status === "recording"
              ? "TX"
              : isBusy
                ? "…"
                : "PTT"}
          </button>
          <p className={styles.pttHint}>
            Hold to transmit · Release to send · Mic required
          </p>
        </section>

        {history.length > 0 && (
          <div className={styles.history}>
            <p className={styles.historyTitle}>Session log</p>
            {history.map((msg, i) => (
              <p key={i} className={styles.historyItem}>
                <strong>{msg.role === "pilot" ? "Pilot" : "ATC"}:</strong>{" "}
                {msg.content}
              </p>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
'@ | Set-Content -Path "$Root\app\simulator\page.tsx" -Encoding utf8NoBOM

Write-Host "Created simulator files in: $Root"
Write-Host "  app\api\transcribe\route.ts"
Write-Host "  app\api\atc\route.ts"
Write-Host "  app\api\speak\route.ts"
Write-Host "  app\simulator\page.tsx"
Write-Host "  app\simulator\simulator.module.css  (required by page.tsx)"
Write-Host ""
Write-Host "Next: ensure .env.local has API keys, then run: npm run dev"
Write-Host "Open: http://localhost:3000/simulator"
