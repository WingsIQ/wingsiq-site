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
