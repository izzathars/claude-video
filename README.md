# claude-video

Edit BTI coaching videos with Claude Code on Windows. Footage lives in Google Drive;
this repo holds the editing scripts and the rules Claude follows (`CLAUDE.md`).

## One-time setup

1. **Google Drive for desktop** — install it and sign in. Make these folders in your Drive:
   ```
   My Drive\BTI Videos\raw      ← put raw clips here
   My Drive\BTI Videos\final    ← finished videos appear here
   My Drive\BTI Videos\assets   ← put logo.png here (transparent PNG)
   ```
   If your Drive isn't on `G:`, change `$DriveRoot` in `scripts\config.ps1`.

2. **Install the tools** — open PowerShell and run:
   ```powershell
   winget install ffmpeg
   winget install Git.Git
   winget install Python.Python.3.12
   ```
   Close and reopen PowerShell, then:
   ```powershell
   pip install faster-whisper
   ```

3. **Get this repo**:
   ```powershell
   cd $HOME\Documents
   git clone https://github.com/izzathars/claude-video.git
   cd claude-video
   ```

4. **Allow scripts to run** (once, for your user only):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```

5. **Open the folder in Claude Code** and just ask, e.g.
   *"Make a Meta ad from clip1.mp4, cut the first 2 seconds."*

## Doing it yourself (without Claude)

```powershell
# 1. make captions (saved as clip1.srt next to the clip) - check the spelling after
python scripts\transcribe.py "G:\My Drive\BTI Videos\raw\clip1.mp4"

# 2. full Meta ad: 9:16 + captions + logo + loudness + max 60s
.\scripts\meta-ad.ps1 clip1.mp4

# every clip in raw at once
.\scripts\batch.ps1
```

| Script | Example |
|---|---|
| `meta-ad.ps1`   | `.\scripts\meta-ad.ps1 clip1.mp4 -Start 2 -Mode crop` |
| `batch.ps1`     | `.\scripts\batch.ps1 -MaxSecs 30` |
| `trim.ps1`      | `.\scripts\trim.ps1 clip1.mp4 -Start 3 -End 45` |
| `vertical.ps1`  | `.\scripts\vertical.ps1 clip1.mp4 -Mode blur` |
| `transcribe.py` | `python scripts\transcribe.py clip1.mp4 --lang ms` |
| `captions.ps1`  | `.\scripts\captions.ps1 clip1.mp4` |
| `logo.ps1`      | `.\scripts\logo.ps1 clip1.mp4 -Position bottom-right` |
| `join.ps1`      | `.\scripts\join.ps1 intro.mp4, clip1.mp4, outro.mp4` |

`-Mode blur` keeps the whole picture with a blurred background (good for landscape footage).
`-Mode crop` fills the screen by cutting the sides (good when you're centred in frame).

Video files are blocked by `.gitignore` — they stay in Google Drive, never on GitHub.
