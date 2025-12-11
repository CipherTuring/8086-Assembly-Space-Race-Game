# Space Race 8086 Assembly

![Language](https://img.shields.io/badge/language-Assembly%20x86-red) ![Platform](https://img.shields.io/badge/platform-DOSBox%20%7C%20MS--DOS-orange)

A competitive arcade game written entirely in **8086 Assembly** (MASM syntax). Inspired by the 1973 Atari classic *Space Race*, players must pilot their ships through a barrage of asteroids to reach the top of the screen.

Includes a **Single Player mode** with a custom AI opponent and a local **Multiplayer mode**.

<img width="442" height="248" alt="image" src="https://github.com/user-attachments/assets/0b4110dc-ccd2-415a-8a67-fb246e6573b7" />
<img width="610" height="385" alt="image" src="https://github.com/user-attachments/assets/14493274-6eb1-443d-a930-7dec2fdddd0a" />


## ✨ Features

* **CGA Graphics:** Operates in Video Mode 04h (320x200 px, 4 colors).
* **Custom Physics Engine:** Features AABB (Axis-Aligned Bounding Box) collision detection.
* **Entity Management:** Handles 7 concurrent meteor obstacles using parallel array processing.
* **Direct Hardware Sound:** Synthesizes sound effects by manipulating the Programmable Interval Timer (PIT 8253) and PC Speaker ports (`42h`, `61h`).

## 🎮 Controls

| Context | Key | Action |
| :--- | :---: | :--- |
| **Menu** | `S` | Start Single Player (vs CPU) |
| | `M` | Start Multiplayer (1 vs 1) |
| | `E` | Exit Game |
| **Player 1 (Left)** | `W` | Move Up |
| | `S` | Move Down |
| **Player 2 (Right)** | `O` | Move Up |
| | `L` | Move Down |
| **Game Over** | `R` | Restart Game |
| | `E` | Return to Menu |

## 💾 How to Run

You will need an MS-DOS emulator (like **DOSBox**) and the **MASM 6.11** compiler (or compatible).

### Prerequisites

1.  Download and install [DOSBox](https://www.dosbox.com/).
2.  Place `MASM.EXE`, `LINK.EXE`, and `game.asm` in a folder (e.g., `C:\8086`).

**Note:** You can watch this video to set up all the necessary configuration: https://www.youtube.com/watch?v=RhsaakpatqI&list=PLvpbDCl_H7mfgmEJPl1bTHlH5g-f0kWDM&index=2

The Youtube video is property of Programming Dimmension

### Compilation & Execution

Open DOSBox and run the following commands:

```bash
# 1. Mount your local folder
MOUNT C C:\8086

# 2. Switch to drive C
C:

# 3. Assemble source code
MASM space

# 4. Link object file
LINK space

# 5. Run the game
space
```
