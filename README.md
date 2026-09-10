# Ultimate Defence 🛡️

> A native macOS first-person tactical defence game: hold Site A, stop the plant, or defuse under pressure.

[![Report Bug](https://img.shields.io/badge/Report-Bug-red)](https://github.com/VidiPT89/UltimateDefence/issues)
[![Request Feature](https://img.shields.io/badge/Request-Feature-blue)](https://github.com/VidiPT89/UltimateDefence/issues)

## ✨ Features

- ✅ First-person combat with mouse look, WASD movement and hitscan weapons
- ✅ Round-based defence: eliminate attackers, run down the clock, or defuse the artefact
- ✅ Maps built on a 2 m grid so rooms, halls and doors share the same edges
- ✅ Match sizes from 1v1 to 6v6 with allied defender bots versus terrorist bots
- ✅ Dying ends the round immediately
- ✅ Humanoid CT and T models, crates, barrels and indoor/outdoor compounds
- ✅ Walk (Shift), crouch (Ctrl), jump, aim-down-sights, recoil punch and distance-based bot accuracy
- ✅ Two weapons (carbine and sidearm), magazine reloads and headshot damage
- ✅ One designated attacker plants on Site A; the others take mid, long or tunnel
- ✅ HUD: health, ammo, round timer and defuse progress
- ✅ Bilingual PT-PT / English language switch
- ✅ Dark, Light and System appearance, with iVidi.dev orange, burnt yellow and black
- ✅ Animated splash with developer credits, then the main menu
- ✅ Sound effects for gunfire, footsteps, reloads, hits, plant beeps and round results
- ✅ Native macOS window with pointer lock while you play

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| 3D | SceneKit |
| Project | XcodeGen |
| Audio | AVFoundation |
| Tests | XCTest |
| Min. macOS | 13.0 |

## 🚀 Quick Start

### Prerequisites

- macOS 13+ with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you change the file structure (`brew install xcodegen`)

### Installation

```bash
git clone https://github.com/VidiPT89/UltimateDefence.git
cd UltimateDefence
open UltimateDefence.xcodeproj
```

Select the `UltimateDefence` scheme and run on My Mac (`⌘R`).

> The Xcode project is generated with XcodeGen from `project.yml`. If you add or move Swift files, regenerate it with `xcodegen generate`.

## 📖 Usage

1. Pick a map (Dust II, Aztec, Office, Mill) and a match size (1v1 to 6v6), then click **INICIAR RONDA**
2. You are on the defence. Allied CT bots hold with you. One terrorist plants on Site A while the others push the routes
3. Use **WASD** to move (default run), **Shift** to walk, **Ctrl** to crouch, **Space** to jump, the mouse to look, left click to fire and right click to aim
4. **1** / **2** or the scroll wheel switch weapons, **R** reloads, **E** defuses while standing on the site
5. Toggle sound, language and theme from the main menu. **Esc** returns to the menu and releases the pointer

Win by eliminating every attacker before they plant, by surviving until the round timer ends, or by defusing after a plant. You lose if you are downed or if the artefact detonates.

## 🧪 Testing

```bash
xcodebuild -project UltimateDefence.xcodeproj -scheme UltimateDefence -destination 'platform=macOS' test
```

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**

- 🌐 Website: [ividi.dev](https://ividi.dev)
- 🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89)

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check the [issues page](https://github.com/VidiPT89/UltimateDefence/issues).

---

<p align="center">Developed by <a href="https://ividi.dev">David Arsénio Martins</a></p>
<p align="center">⭐ If you like this project, give it a star!</p>
