import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ================= SECTION A: EDIT THIS =================
const palette = WorkshopPalette(
  primary: Color(0xFF171717),
  secondary: Color(0xFF525252),
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFF5F5F5),
  text: Color(0xFF171717),
  accent: Color(0xFFA3A3A3),
  brightness: Brightness.light,
);

const config = AiConfig(
  apiKey: 'PASTE_YOUR_API_KEY_HERE',
  model: 'gemini-3.5-flash-lite',
  useMock: true,
);

void main() => runApp(const MyPersonaApp());

class MyPersonaApp extends StatefulWidget {
  const MyPersonaApp({super.key});

  @override
  State<MyPersonaApp> createState() => _MyPersonaAppState();
}

class _MyPersonaAppState extends State<MyPersonaApp> {
  // 📝 THE TWO WHITEBOARDS (Controllers):
  // 1. Controls which character you are chatting with
  final characterController = TextEditingController(text: 'Socrates');
  // 2. Controls the message you are sending
  final messageController = TextEditingController();

  @override
  void dispose() {
    characterController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WorkshopApp(
    title: 'character.AI',
    palette: palette,
    config: config,
    children: [
      /*
        WIDGET CHEAT-SHEET:
        - AppLogo(title: '...', subtitle: '...', icon: Icons.psychology_rounded)
        - AppCharacterSelector(controller: characterController, hint: '...')
        - AppConversation(controller: messageController, hint: '...')
        - AppActionButton(characterController: characterController, messageController: messageController)
      */
      const AppLogo(
        title: 'character.AIrL',
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
  );
}

// ================= SECTION B: PREBUILT (DO NOT EDIT) =================
class WorkshopPalette {
  const WorkshopPalette({
    this.primary = const Color(0xFF8ABFFF),
    this.secondary = const Color(0xFF22364B),
    this.background = const Color(0xFF101215),
    this.surface = const Color(0xFF282C34),
    this.text = const Color(0xFFF5F7FA),
    this.accent = const Color(0xFF8ABFFF),
    this.brightness = Brightness.dark,
  });
  final Color primary, secondary, background, surface, text, accent;
  final Brightness brightness;
}

Color contrastColor(Color bg) =>
    bg.computeLuminance() > .179 ? Colors.black : Colors.white;
Color _visible(Color ink, Color bg) {
  final a = ink.computeLuminance(), b = bg.computeLuminance();
  final ratio = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
  return ratio >= 4.5 ? ink : contrastColor(bg);
}

class AiConfig {
  const AiConfig({
    this.apiKey = '',
    this.model = 'gemini-3.5-flash-lite',
    this.useMock = true,
  });
  final String apiKey, model;
  final bool useMock;
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.character = '',
    this.isError = false,
  });
  final String text;
  final bool isUser;
  final String character;
  final bool isError;
}

class AiModule {
  const AiModule(this.config);
  final AiConfig config;

  String _instruction(String character, String personality) =>
      'Roleplay as $character. Personality: $personality. '
      'Stay in character while being helpful and safe. '
      'Do not claim to really be this person.';

  Future<String> generate({
    required String character,
    required String prompt,
    required String personality,
    List<ChatMessage> history = const [],
  }) async {
    final key = config.apiKey.trim();
    if (key.isEmpty || key == 'PASTE_YOUR_API_KEY_HERE') {
      throw Exception('Enter your API key in AiConfig in main().');
    }
    // history already includes the latest user message exactly once.
    final turns = history.isNotEmpty
        ? history
        : [ChatMessage(text: prompt, isUser: true)];
    return _gemini(character, personality, key, turns);
  }

  Future<Map<String, dynamic>> _post(
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 45));
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Unreadable server response (HTTP ${response.statusCode}).',
      );
    }
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected server response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final failure = data['error'];
      final description = failure is Map ? failure['message'] : null;
      throw Exception(description?.toString() ?? 'HTTP ${response.statusCode}');
    }
    return data;
  }

  Future<String> _gemini(
    String character,
    String personality,
    String key,
    List<ChatMessage> history,
  ) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/'
      'models/${Uri.encodeComponent(config.model)}:generateContent',
    );
    final data = await _post(
      uri,
      {'Content-Type': 'application/json', 'x-goog-api-key': key},
      {
        'systemInstruction': {
          'parts': [
            {'text': _instruction(character, personality)},
          ],
        },
        'contents': [
          for (final message in history)
            {
              'role': message.isUser ? 'user' : 'model',
              'parts': [
                {'text': message.text},
              ],
            },
        ],
        'generationConfig': {'maxOutputTokens': 500, 'temperature': .8},
      },
    );
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini returned no response; check safety filters.');
    }
    final content = candidates.first['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) throw Exception('Gemini returned no text parts.');
    final answer = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
    if (answer.isEmpty) throw Exception('Gemini response was empty.');
    return answer;
  }
}

class PersonaEngine extends ChangeNotifier {
  PersonaEngine({required this.ai, this.useMock = true});
  final AiModule ai;
  final bool useMock;
  String selectedCharacter = 'Socrates';
  String selectedAvatarUrl = '';
  IconData? selectedAvatarIcon;
  String selectedPersonality = '';
  String prompt = '';
  String response = '';
  String error = '';
  bool isLoading = false;
  bool _disposed = false;
  int _requestId = 0;
  bool get hasSubmitted => prompt.isNotEmpty;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void selectCharacter(WorkshopCharacter character) {
    if (isLoading) return;
    selectedCharacter = character.name;
    selectedAvatarUrl = character.imageUrl;
    selectedAvatarIcon = character.avatarIcon;
    selectedPersonality = character.personality.trim().isNotEmpty
        ? character.personality.trim()
        : 'Respond naturally in the style of this character. Be concise.';
    reset();
  }

  Future<void> generate(String message, {String? character}) async {
    if (isLoading || hasSubmitted) return;
    final text = message.trim();
    if (text.isEmpty) {
      error = 'Type a message first.';
      _notify();
      return;
    }
    if (character != null && character.trim().isNotEmpty) {
      selectedCharacter = character.trim();
    }
    prompt = text;
    error = '';
    response = '';
    isLoading = true;
    final id = ++_requestId;
    _notify();
    try {
      final personalityPrompt = selectedPersonality.isNotEmpty
          ? selectedPersonality
          : 'Respond naturally in the style of this character. Be concise.';
      final answer = useMock
          ? await _mockReply(selectedCharacter, text)
          : await ai.generate(
              character: selectedCharacter,
              prompt: text,
              personality: personalityPrompt,
            );
      if (_disposed || id != _requestId) return;
      response = answer;
    } catch (e) {
      if (_disposed || id != _requestId) return;
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!_disposed && id == _requestId) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<String> _mockReply(String character, String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    final persona = character.trim().isEmpty ? 'AI' : character.trim();
    if (persona.toLowerCase().contains('socrates')) {
      return 'The unexamined life is not worth living. Regarding "$text": tell me, what leads you to ask this question?';
    }
    return 'As $persona: That is a thoughtful question. Approaching "$text" with curiosity leads to great discoveries! (Mock response — enter API key for live AI.)';
  }

  void reset() {
    if (isLoading) ++_requestId; // Ignore any previous in-flight response.
    isLoading = false;
    prompt = '';
    response = '';
    error = '';
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_requestId;
    super.dispose();
  }
}

class WorkshopCharacter {
  const WorkshopCharacter(
    this.name, {
    this.imageUrl = '',
    this.personality = '',
    this.subtitle = '',
    this.avatarIcon,
  });

  final String name;
  final String imageUrl;
  final String personality;
  final String subtitle;
  final IconData? avatarIcon;
}

class WorkshopScope extends InheritedNotifier<PersonaEngine> {
  const WorkshopScope({
    super.key,
    required PersonaEngine engine,
    required this.controller,
    required super.child,
  }) : super(notifier: engine);

  final TextEditingController controller;

  static PersonaEngine of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WorkshopScope>();
    assert(scope != null, 'Use these widgets inside WorkshopApp.');
    return scope!.notifier!;
  }

  static TextEditingController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WorkshopScope>();
    assert(scope != null, 'Use these widgets inside WorkshopApp.');
    return scope!.controller;
  }
}

class WorkshopApp extends StatefulWidget {
  const WorkshopApp({
    super.key,
    this.config = const AiConfig(),
    this.engine,
    this.controller,
    this.palette = const WorkshopPalette(),
    this.title = 'character.AI',
    this.children = const [],
  });

  final AiConfig config;
  final PersonaEngine? engine;
  final TextEditingController? controller;
  final WorkshopPalette palette;
  final String title;
  final List<Widget> children;

  @override
  State<WorkshopApp> createState() => _WorkshopAppState();
}

class _WorkshopAppState extends State<WorkshopApp> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final PersonaEngine _engine =
      widget.engine ??
      PersonaEngine(
        ai: AiModule(widget.config),
        useMock: widget.config.useMock,
      );

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.engine == null) _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: widget.title,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: widget.palette.brightness,
      scaffoldBackgroundColor: widget.palette.background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: widget.palette.primary,
            brightness: widget.palette.brightness,
          ).copyWith(
            primary: widget.palette.primary,
            surface: widget.palette.surface,
            onSurface: _visible(widget.palette.text, widget.palette.surface),
          ),
    ),
    home: WorkshopScope(
      engine: _engine,
      controller: _controller,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final widget in widget.children) ...[
                      widget,
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.title = 'character.AI',
    this.subtitle = '',
    this.icon,
    this.badgeText = '',
    this.alignment = CrossAxisAlignment.center,
    this.titleColor,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final String badgeText;
  final CrossAxisAlignment alignment;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final defaultTextColor = _visible(theme.colorScheme.onSurface, bg);
    final textColor = titleColor ?? defaultTextColor;
    final pieces = title.split('.');

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: .08),
              ),
            ),
            child: Icon(icon, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: pieces.first,
                    style: TextStyle(color: textColor),
                  ),
                  if (pieces.length > 1)
                    TextSpan(
                      text: '.${pieces.skip(1).join('.')}',
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                ],
              ),
              textAlign: alignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.start,
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: -1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badgeText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: TextStyle(
              color: defaultTextColor.withValues(alpha: .6),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

class AppCharacterSelector extends StatelessWidget {
  const AppCharacterSelector({
    super.key,
    this.controller,
    this.label = 'CHARACTER / PERSONA',
    this.hint = 'Type any character (e.g. Socrates, Yoda, Einstein)...',
    this.characters = const [],
  });

  final TextEditingController? controller;
  final String label;
  final String hint;
  final List<WorkshopCharacter> characters;

  @override
  Widget build(BuildContext context) {
    final engine = WorkshopScope.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final textColor = _visible(
      theme.colorScheme.onSurface,
      theme.scaffoldBackgroundColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: .6),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: .08),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: !engine.isLoading,
            style: TextStyle(
              color: _visible(theme.colorScheme.onSurface, surface),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              icon: Icon(Icons.person_search_rounded, size: 22, color: accent),
              hintText: hint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: .4),
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (text) {
              final trimmed = text.trim();
              if (trimmed.isNotEmpty) {
                engine.selectCharacter(WorkshopCharacter(trimmed));
              }
            },
          ),
        ),
        if (characters.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in characters)
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: ChoiceChip(
                      label: Text(item.name),
                      selected:
                          engine.selectedCharacter.toLowerCase() ==
                          item.name.toLowerCase(),
                      onSelected: engine.isLoading
                          ? null
                          : (_) {
                              controller?.text = item.name;
                              engine.selectCharacter(item);
                            },
                      showCheckmark: false,
                      selectedColor: accent.withValues(alpha: .15),
                      backgroundColor: surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: .08,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

typedef AppCharacterInput = AppCharacterSelector;

class _RoundAvatar extends StatelessWidget {
  const _RoundAvatar({required this.user, this.url = '', this.fallbackIcon});

  final bool user;
  final String url;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    final defaultIcon = user
        ? Icons.person_rounded
        : (fallbackIcon ?? Icons.psychology_rounded);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: .08),
        ),
      ),
      child: ClipOval(
        child: !user && url.trim().isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(defaultIcon, color: color, size: 22),
              )
            : Icon(defaultIcon, color: color, size: 22),
      ),
    );
  }
}

class AppConversation extends StatelessWidget {
  const AppConversation({
    super.key,
    this.controller,
    this.hint = 'Ask anything...',
    this.label = 'YOUR MESSAGE',
    this.showClearButton = true,
    this.userBubbleColor,
    this.botBubbleColor,
    this.bubbleRadius = 16.0,
    this.inputMaxLines = 3,
  });

  final TextEditingController? controller;
  final String hint;
  final String label;
  final bool showClearButton;
  final Color? userBubbleColor;
  final Color? botBubbleColor;
  final double bubbleRadius;
  final int inputMaxLines;

  @override
  Widget build(BuildContext context) {
    final textController = controller ?? WorkshopScope.controllerOf(context);
    final engine = WorkshopScope.of(context);
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final ink = _visible(theme.colorScheme.onSurface, surface);
    final accent = theme.colorScheme.primary;
    final userBg = userBubbleColor ?? surface;
    final botBg = botBubbleColor ?? surface;
    final labelColor = _visible(
      theme.colorScheme.onSurface,
      theme.scaffoldBackgroundColor,
    ).withValues(alpha: .6);

    Widget messageBubble({required Widget child, required bool isUser}) =>
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: isUser ? userBg : botBg,
              borderRadius: BorderRadius.circular(bubbleRadius),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: .08),
              ),
            ),
            child: child,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: userBg,
                  borderRadius: BorderRadius.circular(bubbleRadius),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                ),
                child: engine.hasSubmitted
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          engine.prompt,
                          style: TextStyle(
                            color: _visible(ink, userBg),
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                      )
                    : TextField(
                        controller: textController,
                        maxLines: inputMaxLines,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: _visible(ink, userBg),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(
                            color: _visible(ink, userBg).withValues(alpha: .4),
                          ),
                          suffixIcon: showClearButton && !engine.hasSubmitted
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: _visible(
                                      ink,
                                      userBg,
                                    ).withValues(alpha: .45),
                                  ),
                                  onPressed: textController.clear,
                                  tooltip: 'Clear',
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            const _RoundAvatar(user: true),
          ],
        ),
        if (engine.hasSubmitted) ...[
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundAvatar(
                user: false,
                url: engine.selectedAvatarUrl,
                fallbackIcon: engine.selectedAvatarIcon,
              ),
              const SizedBox(width: 12),
              messageBubble(
                isUser: false,
                child: engine.isLoading
                    ? SizedBox(
                        height: 22,
                        width: 48,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: accent,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        engine.error.isNotEmpty
                            ? engine.error
                            : engine.response,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: engine.error.isNotEmpty
                              ? Colors.redAccent
                              : ink,
                        ),
                      ),
              ),
            ],
          ),
        ],
        if (!engine.hasSubmitted && engine.error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              engine.error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    this.characterController,
    this.messageController,
    this.controller,
    this.label = 'Send message',
    this.icon = Icons.arrow_upward_rounded,
    this.fullWidth = false,
    this.loadingLabel = 'Thinking...',
    this.color,
  });

  final TextEditingController? characterController;
  final TextEditingController? messageController;
  final TextEditingController? controller;
  final String label;
  final IconData icon;
  final bool fullWidth;
  final String loadingLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final msgController =
        messageController ?? controller ?? WorkshopScope.controllerOf(context);
    final charController = characterController;
    final engine = WorkshopScope.of(context);
    final theme = Theme.of(context);
    final done = engine.hasSubmitted && !engine.isLoading;
    final buttonColor = color ?? theme.colorScheme.primary;

    final button = FilledButton.icon(
      onPressed: engine.isLoading
          ? null
          : () {
              if (done) {
                msgController.clear();
                engine.reset();
              } else {
                final character = charController?.text.trim();
                final message = msgController.text.trim();
                engine.generate(message, character: character);
              }
            },
      icon: Icon(done ? Icons.refresh_rounded : icon, size: 18),
      label: Text(
        engine.isLoading
            ? loadingLabel
            : done
            ? 'Chat again'
            : label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: contrastColor(buttonColor),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return Align(alignment: Alignment.center, child: button);
  }
}
