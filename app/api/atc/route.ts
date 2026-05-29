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
