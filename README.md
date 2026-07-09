# Protocol VII

Protocol VII is an immersive 3D tactical hacking and cybersecurity simulation game built using the Godot Engine (version 4.5, Forward Plus). Set inside a high-tech War Room, the player assumes the role of a tactical network operator. The objective is to secure the world's seven continents by solving progressive terminal-based security puzzles while managing threat levels and preventing the rival AI agent, Omni, from gaining full awareness.

---

## Game Overview and Backstory

In a near-future cyber conflict, global digital control is divided among seven continental nodes. An adversarial system known as Omni is attempting to intercept and compromise these nodes. Your mission is to enter the command center, log into the workstation console, and execute security protocols to reclaim full digital domination.

Every continent you target presents unique technical challenges. Successfully completing puzzles locks down the node, driving up your domination level. However, failing sequences alerts Omni, increasing its detection rate and threatening the integrity of the operation.

---

## Gameplay Loop

1. **The War Room**: Start in a first-person 3D command room. Observe the holographic rotating globe and monitor arrays displaying real-time campaign stats.
2. **Workstation Integration**: Walk up to the desktop station and click on the screen to enter the terminal environment.
3. **Target Selection**: Access the global tactical map to view continental nodes. Different regions demand different skill levels, determining the distribution of easy, medium, and hard puzzles.
4. **Security Challenges**: Enter the terminal command line to solve cyber-hacking puzzles.
5. **Campaign Completion**: Dominate all 7 continents (21 puzzles in total) to secure a total digital lockdown and achieve victory.

---

## Core Features

### 3D War Room Environment
- First-person 3D character controller and room exploration.
- Real-time rotating holographic earth representing global network status.
- Interactive terminal workstation that transitions smoothly to the desktop interface.
- Viewports mapping real-time stats and notification logs onto virtual 3D monitors.

### Tactical Desktop System
- Custom 2D OS simulator environment.
- Integrated apps:
  - **Tactical Map**: A custom shader-driven interface with hover-glow highlights and localized difficulty routing.
  - **Terminal Console**: Command line interface for solving live puzzle tasks.
  - **Stats Center**: Monitor domination levels, penalty counts, and Omni system state.
  - **Notification Feed**: Live feed detailing system messages and intrusion updates.

### Cybersecurity Puzzle Tiers
- **Easy Puzzles (CLI Sequence Verification)**: Manually key in terminal setups for essential security tools (BurpSuite installation, Nmap scans, Docker deployments, Metasploit commands, and WiFi network reconnaissance).
- **Medium Puzzles (Log Parsing and Navigation)**: Explore custom directory hierarchies, search administrative files, and retrieve hidden information using unix-like utility commands (ls, cd, cat, help).
- **Hard Puzzles (SQL Injection Exploitation)**: Inspect vulnerable script source code, examine security logs for user targets, and craft SQL Injection payloads (e.g. bypass queries using OR conditions) to compromise local database configurations.

---

## Project Structure

```text
├── Fonts/               - Custom typography assets for terminal and OS UI
├── Resources/           - Core data resources for continents, players, and game configuration
├── Shader/              - Spatial and Canvas shaders (e.g., CRT scanline filters, holograms, outline glow)
├── Sounds/              - Ambient cues, error alarms, and button feedback audio
├── music/               - Dynamic cyber-thriller background scores
├── scenes/              - Game scene files (.tscn)
│   ├── 3D/              - 3D environments, furniture, and structural elements
│   ├── Continents/      - Individual 2D map node visual instances
│   ├── Puzzles/         - Puzzle layouts (Easy, Medium, Hard, and Puzzle Panel displays)
│   └── UI/              - Desktop environment, notification templates, and stats page
├── scripts/             - Game logic files (.gd)
│   ├── 3D/              - 3D room, camera, and camera viewport controls
│   ├── Continent/       - Logic mapping for individual continent data
│   ├── puzzles/         - Code controlling command line, logs, and SQLi puzzle validation
│   └── (Root Scripts)   - Desktop UI, map routing, main game loop, and global state autoloads
├── textures/            - UI icons, button graphics, and mapping visual assets
├── project.godot        - Godot engine configuration file
└── export_presets.cfg   - Build distribution profiles
```

---

## System Configuration and Requirements

- **Engine Version**: Godot Engine 4.5.
- **Rendering Method**: Forward Plus (for premium lighting, volumetric visuals, and shader-driven effects).
- **Default Resolution**: 1920 x 1080.
- **Stretch Mode**: Canvas Items (expandable aspect ratio).
- **Control System**: Mouse and Keyboard.

---

## Controls

### In 3D War Room
- **W, A, S, D**: Walk around the command room.
- **Mouse Movement**: Look around (adjust sensitivity in the Pause Menu).
- **Left Click (Hovering on Terminal Monitor)**: Focus and enter the desktop workstation.
- **Escape**: Pause game (access audio/sensitivity sliders or exit back to main menu).

### In Workstation/Desktop Environment
- **Mouse Cursor**: Point and click to select apps or run programs.
- **Keyboard Input**: Submit text inside LineEdits when solving command-line challenges.
- **Close Button (Red Arrow Icon)**: Return from the desktop back to 3D room movement.
