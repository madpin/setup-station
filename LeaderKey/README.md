## 🚀 My LeaderKey Configuration

Welcome! This folder stores my personal configuration for [LeaderKey.app](https://github.com/mikker/LeaderKey.app), the *faster than your launcher* launcher.

Inspired by apps like Raycast, Alfred, and classics like Quicksilver—but giving things a bit of a fighting-game twist (think Tekken combos, but with your keyboard). No mouse, no typing—just lightning-fast keyboard shortcuts 🚀⚡.

### 🎯 Why use LeaderKey?
- **Speed:** Instant launch with predictable, nested shortcuts (faster than typing in Spotlight or Alfred).
- **Customizable:** You define the groups and combos that fit naturally into your muscle memory.
- **Powerful & Flexible:** Not just apps! Launch terminal commands, run shortcuts, open URLs and Raycast deeplinks—possibilities are endless.

### 📦 Installation
Grab the app with Homebrew:
```bash
brew install leader-key
```

Or from the [official GitHub repo](https://github.com/mikker/LeaderKey.app).

### 🗝️ Using the config
This folder stores my JSON config for LeaderKey, structured in easy-to-manage nested groups. You can import this into your own LeaderKey setup or tweak it directly to your liking.

Here's a quick structure overview:
```json
{
  "t": {"name": "Terminal", "launch": "Terminal"},
  "b": {
    "name": "Browsers",
    "s": {"name": "Safari", "launch": "Safari"},
    "c": {"name": "Chrome", "launch": "Google Chrome"}
  },
  "w": {
    "name": "Windows",
    "f": {"name": "Fullscreen", "shortcut": "{fullscreen_shortcut_here}"},
    "l": {"name": "Left Half", "shortcut": "{left_half_shortcut_here}"}
  }
}
```

Feel free to dive into [LeaderKey Wiki](https://github.com/mikker/LeaderKey.app/wiki) for more deep-dive examples.

### 🕹️ Recommended Leader Keys
Pick a comfy key, or use advanced setups (e.g., via Karabiner):

- `F12` (simple, single key)
- `⌘ + Space`
- `Caps Lock` when tapped (Hyper when held down, F12 when tapped)
- Dual-command keys (`Left ⌘ + Right ⌘ simultaneously`)

Check [Karabiner-Elements](https://karabiner-elements.pqrs.org/) for more creative ways to set your Leader Key!

### 🌈 Theming
LeaderKey supports neat themes (including community-made ones):

- **Mystery Box** (Default)
- **Mini** (Small in-corner display)
- **Breadcrumbs** (Small nested-navigation corner display)

See the recent update video about themes [here](https://www.youtube.com/watch?v=EQYakLsYSAQ).

### 🧑‍💻 Contributing & Sharing
Got cool combos, neat themes, or unique setups? Share them with the awesome LeaderKey community through [official Discussions](https://github.com/mikker/LeaderKey.app/discussions) or the [wiki](https://github.com/mikker/LeaderKey.app/wiki)! 🍻

Thanks to awesome folks like [Chuck Harmston](https://github.com/chuckharmston), [Lennart Egbringhoff](https://github.com/LennartEgb), [ZenAngst](https://github.com/zenangst), and everyone contributing cool community PRs and feature ideas.

### 📹 Official Intro Videos
Check out these fun intro videos by the creator:
- [Intro & Explanation](https://www.youtube.com/watch?v=hzzQl5FOL-k)
- [Recent Updates (Themes, Cheat Sheets & More)](https://www.youtube.com/watch?v=EQYakLsYSAQ)