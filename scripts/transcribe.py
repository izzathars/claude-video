"""
Make an .srt caption file from a video, with short punchy lines for vertical ads.

Install once:   pip install faster-whisper
Use:            python scripts\\transcribe.py "G:\\My Drive\\BTI Videos\\raw\\clip1.mp4"
Options:        --lang ms        force Malay (default: auto-detect; "en" for English)
                --model small    tiny / base / small / medium / large-v3 (bigger = more accurate, slower)
                --words 4        max words per caption line

The .srt is saved next to the video with the same name (clip1.srt),
which is where meta-ad.ps1 and captions.ps1 look for it.
"""
import argparse
import sys
from pathlib import Path


def ts(seconds: float) -> str:
    ms = int(round(seconds * 1000))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02}:{m:02}:{s:02},{ms:03}"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("--lang", default=None)
    ap.add_argument("--model", default="small")
    ap.add_argument("--words", type=int, default=4)
    ap.add_argument("--chars", type=int, default=24, help="max characters per line")
    args = ap.parse_args()

    video = Path(args.video)
    if not video.exists():
        sys.exit(f"Video not found: {video}")

    try:
        from faster_whisper import WhisperModel
    except ImportError:
        sys.exit("faster-whisper is not installed. Run:  pip install faster-whisper")

    print(f"Loading model '{args.model}' (first run downloads it)...")
    model = WhisperModel(args.model, device="auto", compute_type="int8")
    segments, info = model.transcribe(
        str(video), language=args.lang, word_timestamps=True, vad_filter=True
    )
    print(f"Detected language: {info.language} ({info.language_probability:.0%})")

    # Group words into short caption chunks.
    chunks, cur = [], []
    for seg in segments:
        for w in seg.words or []:
            word = w.word.strip()
            if not word:
                continue
            text = " ".join(x[0] for x in cur + [(word,)])
            if cur and (len(cur) >= args.words or len(text) > args.chars):
                chunks.append(cur)
                cur = []
            cur.append((word, w.start, w.end))
            if word[-1] in ".?!":
                chunks.append(cur)
                cur = []
    if cur:
        chunks.append(cur)

    if not chunks:
        sys.exit("No speech found in the video.")

    out = video.with_suffix(".srt")
    lines = []
    for i, c in enumerate(chunks, 1):
        start, end = c[0][1], c[-1][2]
        if i < len(chunks):  # don't overlap the next caption
            end = min(end + 0.15, chunks[i][0][1])
        lines += [str(i), f"{ts(start)} --> {ts(end)}", " ".join(w[0] for w in c), ""]
    out.write_text("\n".join(lines), encoding="utf-8")

    print(f"\nSaved {len(chunks)} captions to: {out}\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
