# Workshop Guide: Blank ➔ Standard Version
> **Instructor Cheat Sheet** | Keep this file open on your side screen while live-coding from `main_blank.dart`.

---

## 🎯 Pedagogical Flow
```text
Phase 1: Skeleton UI      ➔ Drop in 4 widgets (instant visual gratification)
Phase 2: Set the Theme    ➔ Apply WorkshopPalette (show Flutter theming)
Phase 3: Text Controllers ➔ First DEMO the need, then ADD controllers
Phase 4: AI Prerequisites ➔ Explain keys, models, and mock mode
Phase 5: Live Gen AI      ➔ Flip useMock: false, test Gemini 3.5 live
```

---

## 🦴 Phase 1: Setup the Skeleton (Just Widgets, No Logic)

**Goal:** Give participants immediate visual gratification. In 60 seconds, have the full app structure visible on screen.

### Instructor Talking Point:
> *"Before we write any logic or state, let's assemble the visual skeleton. Flutter is declarative: UI is just a tree of widgets."*

### Action:
In `main_blank.dart`, drop the 4 core widgets into `children: [...]` inside `WorkshopApp`:

```dart
  @override
  Widget build(BuildContext context) => WorkshopApp(
    title: 'character.AI',
    palette: palette,
    config: config,
    children: const [
      // 1. Brand Logo
      AppLogo(
        title: 'character.AI',
        subtitle: 'Roleplay with any fictional or historical persona',
        icon: Icons.psychology_rounded,
      ),

      // 2. Character Input Box
      AppCharacterSelector(
        hint: 'Who do you want to talk to? (e.g. Socrates, Yoda, Einstein)',
      ),

      // 3. User Message Box & Chat History Area
      AppConversation(
        hint: 'Ask anything...',
      ),

      // 4. Send Action Button
      AppActionButton(),
    ],
  );
```

⚡ **Hit Hot Reload (`r`):**
The entire layout appears immediately! Walk through the 4 visual pieces on screen.

---

## 🎨 Phase 2: Set the Theme

**Goal:** Show how Flutter theming works and how clean design tokens customize the app without touching individual widget styles.

### Instructor Talking Point:
> *"Our app works, but it's using default fallback colors. Let's give it a clean, modern aesthetic using `WorkshopPalette`."*

### Action:
Populate `const palette` at the top of Section A:

```dart
const palette = WorkshopPalette(
  primary: Color(0xFF171717),
  secondary: Color(0xFF525252),
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFF5F5F5),
  text: Color(0xFF171717),
  accent: Color(0xFFA3A3A3),
  brightness: Brightness.light,
);
```

⚡ **Hit Hot Reload:**
The entire app instantly transforms into a sleek, minimalist light-mode theme!
- Point out: `background` colored the page, `surface` colored the input cards, `primary` styled the button.

---

## 📝 Phase 3: Adding Text Controllers (First Demo, Then Adding)

### 1. 🎤 First DEMO the problem to the room:
> *"Right now, we have two text boxes and a button. But how does the button know what character you typed in the top box, or what question you typed in the bottom box?*
>
> *In Flutter, widgets cannot reach into each other. To read text, clear text, or control inputs programmatically, we use a **TextEditingController**—think of it as a **shared whiteboard**."*

```text
[ Character Input ] ──writes to──▶ characterController ──┐
                                                          ├──▶ [ Action Button ]
[ Message Input ]   ──writes to──▶ messageController   ──┘
```

### 2. 💻 Now ADD the controllers:

#### Step A: Declare controllers inside `_MyPersonaAppState`
```dart
class _MyPersonaAppState extends State<MyPersonaApp> {
  // Whiteboard 1: Stores WHO we are talking to
  final characterController = TextEditingController(text: 'Socrates');

  // Whiteboard 2: Stores WHAT we are asking
  final messageController = TextEditingController();
```

#### Step B: Dispose them (explain memory leaks)
```dart
  @override
  void dispose() {
    // Rule: Always clean up controllers when the widget leaves the tree
    characterController.dispose();
    messageController.dispose();
    super.dispose();
  }
```

#### Step C: Connect the controllers to the widgets
Remove `const` from `children: [...]` and pass the controllers:

```dart
    children: [
      const AppLogo(
        title: 'character.AI',
        subtitle: 'Roleplay with any fictional or historical persona',
        icon: Icons.psychology_rounded,
      ),
      AppCharacterSelector(
        controller: characterController,
        hint: 'Who do you want to talk to? (e.g. Socrates, Yoda, Einstein)',
      ),
      AppConversation(
        controller: messageController,
        hint: 'Ask anything...',
      ),
      AppActionButton(
        characterController: characterController,
        messageController: messageController,
      ),
    ],
```

⚡ **Quick Test:**
Type into the inputs. Show that tapping **Send message** reads both fields and resets cleanly!

---

## 🤖 Phase 4: Setup Gen AI Prerequisites

**Goal:** Introduce the Gen AI configuration layer.

### Instructor Talking Point:
> *"To connect an LLM to Flutter, we need three things:
> 1. Which model we want (`gemini-3.5-flash-lite`)
> 2. An API authentication key (from Google AI Studio)
> 3. `useMock`: A safety switch for offline testing so we don't waste API quota while building UI."*

### Action:
Populate `const config` at the top of Section A:

```dart
const config = AiConfig(
  apiKey: 'PASTE_YOUR_API_KEY_HERE',
  model: 'gemini-3.5-flash-lite',
  useMock: true, // Offline mock mode enabled
);
```

⚡ **Hit Hot Reload & Test:**
Tap **Send message**. Explain:
> *"Because `useMock: true`, our app simulates Gemini responses instantly offline! This is how you test error states, loading spinners, and layout before touching real APIs."*

---

## 🚀 Phase 5: Add Gen AI Functionality (Go Live!)

**Goal:** Transition from offline mock simulation to live real-time Gemini 3.5 inference.

### Instructor Talking Point:
> *"Now let's bring it to life with Google's newest lightweight model: Gemini 3.5 Flash-Lite. We just paste our API key and flip `useMock` to `false`."*

### Action:
Update `const config`:

```dart
const config = AiConfig(
  apiKey: 'AIzaSyYourActualKeyHere', // Paste key from aistudio.google.com/apikey
  model: 'gemini-3.5-flash-lite',
  useMock: false, // LIVE AI ENABLED!
);
```

⚡ **Live Demo Test:**
1. In the Character box, type: `Yoda` or `Albert Einstein` or `Sherlock Holmes`.
2. In the Question box, type: `Explain how airplanes fly in one sentence.`
3. Tap **Send message**!
4. Point out:
   - Button switches to **Thinking...** with disabled state.
   - Response card streams the authentic roleplay response directly from Gemini 3.5.
   - Button switches to **Chat again** to reset for the next prompt.

---

## 📋 Quick Instructor Checklist
- [x] **Phase 1:** 4 skeleton widgets dropped in `children: []`. App renders immediately.
- [x] **Phase 2:** `WorkshopPalette` added. Theme restyles.
- [x] **Phase 3:** Controllers demoed & wired up (`characterController` + `messageController`).
- [x] **Phase 4:** `AiConfig` explained (`useMock: true` for offline testing).
- [x] **Phase 5:** Real API key pasted & `useMock: false`. Live Gemini 3.5 inference!
