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
