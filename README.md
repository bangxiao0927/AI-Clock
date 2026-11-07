# AI clock 1

**AI clock 1** is a small, calm Flutter app built around three tools: the **Clock**, your **Day**, and your **Notes**. It has an animated splash screen and a floating frosted-glass tab bar. Each tool lives in its own folder, so adding a fourth is a few lines.

| | |
|---|---|
| **App name** | `AI clock 1` (shown under the launcher icon on Android and iOS) |
| **Dart package** | `ai_clock_1` |
| **Platforms** | Android, iOS |
| **Look** | Dark theme, glass tab bar and cards, one restrained accent colour per tab |
| **Dependencies** | Flutter SDK only, no third-party packages |

## Screen structure

```
Splash (animated logo)
   └─► App shell, with a floating glass tab bar
          ├─ Home    greeting + a card for every tool
          ├─ Clock
          ├─ Day
          └─ Notes
```

1. **Splash** – the logo draws itself in (badge, ring, hands, AI spark), the name fades up, then the app cross-fades into the shell while the logo flies into the Home header.
2. **App shell** – a pill-shaped tab bar of frosted glass floats at the bottom. A tinted capsule slides to the selected tab, and the pages cross-fade. Content scrolls underneath the bar and shows through the blur. Tabs are built the first time they are opened and then keep their state. *Back* returns to Home first, then leaves the app.
3. **Home** – the app name, a time-of-day greeting, and one card per tool. Tapping a card switches to that tool's tab.
4. **Tool screens** – all three share one layout (`ToolScaffold`: icon and title, then cards fading in one after another).

## The three tools

| Tool | What it does today | Planned |
|---|---|---|
| **Clock** | Live analog face plus digital time and date (follows the device's 12/24-hour setting) | Alarms, timers, world clocks |
| **Day** | Today's weekday and date, with a "day progress" bar | Schedule and reminders |
| **Notes** | Empty state with a "New note" button (shows a "coming soon" message) | Note editor and list |

## Project structure

```
lib/
├── main.dart                     entry point
├── app/
│   ├── app.dart                  MaterialApp: theme and routes
│   ├── routes.dart               route names
│   ├── app_router.dart           route name -> page
│   └── app_shell.dart            tab shell: glass tab bar + tabs
├── core/                         shared building blocks (no tool code)
│   ├── constants.dart            app name and tagline
│   ├── theme/app_theme.dart      colour tokens and the dark theme
│   ├── transitions/              fade route used after the splash
│   ├── utils/                    date/time formatting helpers
│   └── widgets/                  glass container + tab bar, cards, logo, fade-in, ...
├── features/                     app-level screens
│   ├── splash/
│   └── home/
└── tools/                        one folder per tool
    ├── app_tool.dart             ToolInfo (title, icon, colour) and AppTool
    ├── tool_registry.dart        the list of tools: add yours here
    ├── tool_scaffold.dart        layout shared by the tool screens
    ├── clock/                    clock_tool.dart, clock_screen.dart, widgets/
    ├── day/                      day_tool.dart, day_screen.dart, widgets/
    └── notes/                    notes_tool.dart, notes_screen.dart, widgets/
tool/generate_icons.dart          regenerates the launcher icons from the logo
test/widget_test.dart             splash, tab bar, Home cards, back handling
```

Layering: `core` imports nothing else from the app, and `tools` import only `core` (and each other's `ToolInfo`), so a tool never depends on the shell or on another tool's screen. `app` and `features` sit on top; the splash navigates by name through `app/routes.dart`, which holds names only.

## Adding a tool

1. Create `lib/tools/<name>/` with `<name>_tool.dart` (a `const ToolInfo`: id, title, description, icon, colour) and `<name>_screen.dart` (a screen built on `ToolScaffold`).
2. Add one `AppTool(info: ..., builder: ...)` line to `lib/tools/tool_registry.dart`.

The tab bar and the Home screen pick it up automatically. The tab bar suits about 3 to 4 tools; with more, keep the extras on Home only.

## Run it in Android Studio

1. Install the **Flutter** plugin (it also installs **Dart**): *Settings → Plugins → Marketplace → Flutter*, then restart.
2. Set the SDK path: *Settings → Languages & Frameworks → Flutter → Flutter SDK path*.
3. *File → Open…* and choose this folder, then run `flutter pub get` if prompted.
4. Pick an emulator or device and press **Run**.

Or from a terminal:

```bash
flutter pub get
flutter run
```

Quality checks:

```bash
flutter analyze
flutter test
```

## Design notes

- **Glass** – `GlassContainer` blurs what is behind it, adds a faint white tint and a thin gradient edge. It is used only for the tab bar, because every glass surface costs a backdrop blur per frame. Cards use a cheaper translucent fill and border in the same style.
- **Motion** – short and eased (about 0.3 to 0.5 s). If the system's "reduce motion" setting is on, the splash animation, the fade-ins and the tab cross-fade are skipped.
- **Logo and icons** – the logo is drawn in code (`LogoPainter`): a clock face whose 12 o'clock mark is an AI spark. The launcher icons are generated from the same painter, so they always match. After changing the logo, run `flutter test tool/generate_icons.dart`.
- **Launch screens** (Android and iOS) use the app's dark background, so there is no white flash before the splash.
