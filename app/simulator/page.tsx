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
