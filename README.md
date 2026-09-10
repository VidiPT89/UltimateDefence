# Ultimate Defence 🛡️

> A native macOS first-person tactical defence game: hold Site A, stop the plant, or defuse under pressure.

[![Report Bug](https://img.shields.io/badge/Report-Bug-red)](https://github.com/VidiPT89/UltimateDefence/issues)
[![Request Feature](https://img.shields.io/badge/Request-Feature-blue)](https://github.com/VidiPT89/UltimateDefence/issues)

## ✨ Features

- ✅ First-person combat with mouse look, WASD movement and hitscan weapons
- ✅ Round-based defence: eliminate attackers, run down the clock, or defuse the artefact
- ✅ Four attacker bots that push Site A, shoot on sight and plant if left unchecked
- ✅ Two weapons (carbine and sidearm), magazine reloads and headshot damage
- ✅ Industrial 3D compound with cover, lighting, particle dust and an animated bomb site
- ✅ Cinematic HUD: health, ammo, round timer and defuse progress
- ✅ Bilingual PT-PT / English language switch
- ✅ Dark, Light and System appearance, with iVidi.dev orange, burnt yellow and black
- ✅ Animated splash with developer credits, then the main menu
- ✅ Native macOS window with pointer lock while you play

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| 3D | SceneKit |
| Project | XcodeGen |
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

1. Click **INICIAR RONDA** and click the game view to capture the mouse
2. Hold Site A (the glowing ring). Attackers spawn on the far side of the compound
3. Use **WASD** to move, the mouse to look, left click to fire
4. **1** / **2** switch weapons, **R** reloads, **E** defuses while standing on the site
5. **Esc** returns to the menu and releases the pointer

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
