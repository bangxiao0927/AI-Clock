# AI clock 1

**AI clock 1** is a small, calm Flutter app built around three things: the **Clock**, your **Day**, and your **Notes**. This first version is a clean foundation: an animated splash screen, a main menu with smooth transitions, and three separate feature screens with lightweight placeholder content.

| | |
|---|---|
| **App name** | `AI clock 1` (shown under the launcher icon on Android and iOS) |
| **Dart package** | `ai_clock_1` |
| **Platforms** | Android, iOS |
| **Look** | Dark theme, one restrained accent colour per feature |
| **Dependencies** | Flutter SDK only, no third-party packages |

## Screen structure

```
Splash (animated logo)
   └─► Main menu
          ├─► Clock
          ├─► Day
          └─► Notes
```

1. **Splash** – the logo draws itself in (badge, ring, clock hands, AI spark), the app name fades up, then the app cross-fades into the menu while the logo flies into the menu header.
2. **Main menu** – the logo and name, then one card per feature, fading in one after another. Tapping a card opens that feature; its icon flies into the new screen's header.
3. **Feature screens** – Clock, Day and Notes share one layout (back button, icon and title, content cards) so they feel consistent.

## The three features

| Feature | What it does today | Planned |
|---|---|---|
| **Clock** | Live analog face plus digital time and date (follows the device's 12/24-hour setting) | Alarms, timers, world clocks |
| **Day** | Today's weekday and date, with a "day progress" bar | Schedule and reminders |
| **Notes** | Empty state with a "New note" button (shows a "coming soon" message) | Note editor and list |

## Project structure

```
lib/
├── main.dart                  entry point
├── app.dart                   MaterialApp: title, theme, first screen
├── core/                      shared by every feature
│   ├── constants.dart         app name and tagline
│   ├── theme/app_theme.dart   colour tokens and the dark theme
│   ├── transitions/           fade route used after the splash
│   ├── utils/                 small date/time formatting helpers
│   └── widgets/               logo, card, fade-in, icon tile, placeholder card
└── features/
    ├── app_feature.dart       the three features: title, icon, accent colour
    ├── feature_scaffold.dart  layout shared by the feature screens
    ├── splash/                animated splash screen
    ├── menu/                  main menu
    ├── clock/                 Clock feature
    ├── day/                   Day feature
    └── notes/                 Notes feature
tool/generate_icons.dart       regenerates the launcher icons from the logo
test/widget_test.dart          splash → menu → each feature
```

Each feature lives in its own folder, so it can grow (data, state, widgets) without touching the others.

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

- **Motion** is short and eased (about 0.5 s per element). Page changes use the platform's own transition: a slide with swipe-back on iOS, a fade-forward on Android. If the system's "reduce motion" setting is on, the splash animation and the fade-ins are skipped.
- **The logo** is drawn in code (`LogoPainter`): a clock face whose 12 o'clock mark is an AI spark. The launcher icons are generated from the same painter, so they always match. After changing the logo, run `flutter test tool/generate_icons.dart`.
- **Launch screens** (Android and iOS) use the app's dark background, so there is no white flash before the splash.
