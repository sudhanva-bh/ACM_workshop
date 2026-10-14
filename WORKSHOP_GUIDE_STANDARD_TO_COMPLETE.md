# Workshop Guide: Standard ➔ Complete Version
> **Instructor Cheat Sheet** | Use this screen side-by-side to guide students through customizing every widget.

---

## 🎯 Target Goal
Take the basic working app and upgrade each of the 4 widgets with advanced customization props.

---

## Upgrade 1: Brand the Logo (`AppLogo`)
Explain: *"Let's add a badge tag, customize alignment, and override title colors."*

```dart
// REPLACE basic AppLogo with:
const AppLogo(
  title: 'character.AIrL',
  subtitle: 'Roleplay with any fictional or historical persona',
  icon: Icons.psychology_rounded,
  badgeText: 'PRO',                  // 🆕 Pill badge
  alignment: CrossAxisAlignment.center, // 🆕 Alignment (center / start)
  titleColor: Color(0xFF171717),      // 🆕 Direct title color override
),
```

---

## Upgrade 2: Preset Personas (`AppCharacterSelector`)
Explain: *"Instead of just a text box, let's add quick-select character chips, each with their own subtitle, custom icon, and unique system personality prompt."*

```dart
// UPGRADE AppCharacterSelector with:
AppCharacterSelector(
  controller: characterController,
  label: 'CHOOSE OR TYPE A PERSONA', // 🆕 Uppercase header
  hint: 'Type any persona (e.g. Socrates, Yoda, Einstein)...',
  characters: const [                 // 🆕 Quick-select persona chips
    WorkshopCharacter(
      'Socrates',
      subtitle: 'Classical Philosopher',
      personality: 'Deep, questioning, intellectual, and uses the Socratic method.',
      avatarIcon: Icons.auto_stories_rounded,
    ),
    WorkshopCharacter(
      'Tony Stark',
      subtitle: 'Genius & Superhero',
      personality: 'Sarcastic, witty, brilliant, and confident.',
      avatarIcon: Icons.bolt_rounded,
    ),
    WorkshopCharacter(
      'Yoda',
      subtitle: 'Grand Jedi Master',
      personality: 'Wise, speaks in inverted sentences, patient.',
      avatarIcon: Icons.self_improvement_rounded,
    ),
    WorkshopCharacter(
      'Marie Curie',
      subtitle: 'Pioneering Scientist',
      personality: 'Passionate about science, methodical, dedicated.',
      avatarIcon: Icons.science_rounded,
    ),
  ],
),
```
> **Teaching Point:** Tapping a chip writes into `characterController` and sets the character's unique AI prompt automatically!

---

## Upgrade 3: Polish the Chat Box (`AppConversation`)
Explain: *"Let's add an explicit label, a clear button, custom bubble radii, and custom bubble tints."*

```dart
// UPGRADE AppConversation with:
AppConversation(
  controller: messageController,
  label: 'YOUR MESSAGE',                                 // 🆕 Section label
  hint: 'Ask anything (philosophy, science, advice)...', // 🆕 Custom placeholder
  showClearButton: true,                                 // 🆕 'X' clear icon
  bubbleRadius: 16.0,                                    // 🆕 Corner curvature
  inputMaxLines: 4,                                      // 🆕 Expandable input height
  userBubbleColor: const Color(0xFFF0F0F0),              // 🆕 Custom user bubble
  botBubbleColor: const Color(0xFFFAFAFA),               // 🆕 Custom bot bubble
),
```

---

## Upgrade 4: Custom Action Button (`AppActionButton`)
Explain: *"Let's customize the button label, icon, loading indicator text, and colors."*

```dart
// UPGRADE AppActionButton with:
AppActionButton(
  characterController: characterController,
  messageController: messageController,
  label: 'Generate response',           // 🆕 Custom button text
  icon: Icons.arrow_upward_rounded,      // 🆕 Custom icon
  loadingLabel: 'Thinking...',           // 🆕 Custom loading text
  fullWidth: false,                      // 🆕 Full-width toggle
  color: const Color(0xFF171717),        // 🆕 Custom accent color
),
```

---

## 🏆 Final Verification
1. Hot Reload (`r`).
2. Tap the **Yoda** chip ➔ notice the text field updates to "Yoda".
3. Send a question ➔ observe that Gemini 3.5 roleplays as Yoda with his characteristic speech patterns!
