# Spruce POS Desktop Launcher

Quick setup to access ECI Spruce POS as a desktop app on Windows.

## Setup (One-Time)

1. **Set your Spruce URL**: Open `launch-spruce.bat` in Notepad and replace the URL on the `set SPRUCE_URL=` line with your actual Spruce login URL.

2. **Create the desktop shortcut**: Double-click `create-desktop-shortcut.bat`. This places a "Spruce POS" shortcut on your Desktop.

3. **Done!** Double-click the "Spruce POS" shortcut on your Desktop to launch Spruce in a clean app window (no browser toolbar/address bar).

## How It Works

- Opens Spruce in Microsoft Edge (or Chrome) in **app mode** — looks and feels like a native desktop application.
- No browser tabs, address bar, or toolbars — just Spruce.
- Falls back to your default browser if neither Edge nor Chrome is installed.

## Files

| File | Purpose |
|------|---------|
| `launch-spruce.bat` | Main launcher script (set your URL here) |
| `launch-spruce.vbs` | Silent wrapper so no console window flashes |
| `create-desktop-shortcut.bat` | Run once to create the Desktop shortcut |
