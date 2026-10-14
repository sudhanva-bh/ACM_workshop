# Character.AI Flutter Workshop (v7)

A hands-on workshop building a dual-controller Gen AI roleplay app powered by **Gemini 3.5 Flash-Lite**.

---

## 📁 Code Files in `lib/`

| File | Purpose | Who uses it? |
|---|---|---|
| **`lib/main_blank.dart`** | Clean starter file with empty `children: []`. | **Participants** start here. |
| **`lib/main_standard.dart`** | Standard working version with dual controllers & mock responses. | **Presenter reference** during workshop. |
| **`lib/main_complete.dart`** | Showcases all available customization props (preset chips, custom bubbles, badges). | Advanced reference / final showcase. |
| **`lib/main.dart`** | Active playground / testing file. | Development & testing. |

> **Architecture Rule:** Every file is split into **Section A (editable code)** and **Section B (prebuilt plumbing & engine — do not touch)**.

---

## 📚 Workshop Guides & Tools

- **[`WORKSHOP_GUIDE_BLANK_TO_STANDARD.md`](./WORKSHOP_GUIDE_BLANK_TO_STANDARD.md)**  
  The 5-phase teaching cheat sheet (keep open on a side monitor while live coding):
  1. **Phase 1: Skeleton UI** — Drop in 4 core widgets with no state (instant visual layout in 60s).
  2. **Phase 2: Set the Theme** — Apply `WorkshopPalette` design tokens.
  3. **Phase 3: Text Controllers** — Demo why inputs need "whiteboards", then add & wire `characterController` and `messageController`.
  4. **Phase 4: AI Prerequisites** — Configure `AiConfig` with `useMock: true` (instant offline replies).
  5. **Phase 5: Live Gen AI** — Paste Google AI Studio key, set `useMock: false`, and chat live with Gemini 3.5!

- **[`WORKSHOP_GUIDE_STANDARD_TO_COMPLETE.md`](./WORKSHOP_GUIDE_STANDARD_TO_COMPLETE.md)**  
  Guide for upgrading the standard version to the fully customized version.

- **[`WORKSHOP_WIDGETS_AND_CONFIGS.md`](./WORKSHOP_WIDGETS_AND_CONFIGS.md)**  
  Complete field reference and Mermaid architecture diagram for all widgets and configs.

- **[`workshop_architecture.html`](./workshop_architecture.html)**  
  Interactive, zoomable/pannable dark visualizer. Click any class to get a clean copyable constructor snippet, or click the phase buttons to jump between workshop sections.

---

## 🚀 How to Run

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the blank starter (for students)
flutter run -t lib/main_blank.dart

# 3. Run the standard version (for instructor reference)
flutter run -t lib/main_standard.dart

# 4. Run the complete version
flutter run -t lib/main_complete.dart
```

---

## 🔑 AI Configuration (`AiConfig`)

In Section A of any file:
```dart
const config = AiConfig(
  apiKey: 'YOUR_GEMINI_API_KEY', // Get from aistudio.google.com/apikey
  model: 'gemini-3.5-flash-lite',
  useMock: false, // true = offline instant mock; false = live Gemini API
);
```
