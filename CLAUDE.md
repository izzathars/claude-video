# claude-video — video editing with Claude Code (Windows)

You are editing videos for **BTI coaching** (The Body Transformation Institute).
Most videos are ads for **Meta (Facebook / Instagram)**.

## Where the footage lives

- Raw clips:      `G:\My Drive\BTI Videos\raw`
- Finished files: `G:\My Drive\BTI Videos\final`
- Logo:           `G:\My Drive\BTI Videos\assets\logo.png`

These are Google Drive for desktop folders. Never put video files in this repo.
If the drive letter or folder is different on this machine, update `scripts\config.ps1`.

## House style for Meta ads (default unless the user says otherwise)

- Format: vertical **9:16, 1080×1920**, MP4 (H.264 + AAC), 30 fps
- Length: **under 60 seconds** — trim dead air at the start (first words within 1 second)
- Captions: burned in, bold white text with black outline, lower third, short lines
- Logo: top-right, small (about 15% of the width), slightly transparent
- Audio: loudness normalised (-14 LUFS) so ads aren't quiet next to other posts
- File name: `<original-name>_meta.mp4` in the `final` folder

## Tools

- `ffmpeg` does all editing. Check it with `ffmpeg -version`; install with `winget install ffmpeg` if missing.
- Captions are made with `scripts\transcribe.py` (faster-whisper). Install once with
  `pip install faster-whisper`. Footage may be English, Malay, or mixed — let it auto-detect
  unless the user names a language.
- Ready-made scripts are in `scripts\` (PowerShell). Use them first; write new ffmpeg
  commands only when a script doesn't cover the request.

## Scripts

| Script | What it does |
|---|---|
| `meta-ad.ps1`   | Full pipeline: 9:16 + captions + logo + loudness + 60s cap → `final` |
| `batch.ps1`     | Runs `meta-ad.ps1` on every clip in `raw` |
| `trim.ps1`      | Cut a clip between two timestamps |
| `vertical.ps1`  | Convert to 9:16 (crop centre, or blurred background) |
| `transcribe.py` | Make an `.srt` caption file from a clip |
| `captions.ps1`  | Burn an `.srt` into a clip |
| `logo.ps1`      | Put the logo top-right |
| `join.ps1`      | Join several clips into one |

## Working rules

- Never overwrite or delete anything in `raw`. Always write new files to `final`.
- Before burning captions, show the user the `.srt` text so they can fix spelling
  (names, "BTI", Malay words).
- After an export, report the output path, length and file size.
- When a new edit recipe works well, save it as a script in `scripts\` and commit it.
