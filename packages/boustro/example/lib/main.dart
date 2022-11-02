// ignore_for_file: diagnostic_describe_all_properties, use_key_in_widget_constructors, public_member_api_docs
import 'package:boustro/boustro.dart';
import 'package:boustro/toolbar_items.dart' as toolbar_items;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  /// The attribute theme is used to customize the effect of [TextAttribute]s.
  AttributeThemeData _buildAttributeTheme(BuildContext context) {
    final builder = AttributeThemeBuilder();
    builder.boldFontWeight = FontWeight.w900;
    builder.linkOnTap = _handleLinkTap;
    return builder.build();
  }

  /// The component config is used to customize embeds and line modifiers.
  BoustroComponentConfigData _buildComponentConfig(BuildContext context) {
    final builder = BoustroComponentConfigBuilder();
    builder.imageMaxHeight = 400;
    builder.imageSideColor = Theme.of(context).brightness == Brightness.light
        ? Colors.brown.withOpacity(0.2)
        : Colors.deepPurple.shade900.withOpacity(0.2);
    return builder.build();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, child) {
        return BoustroConfig(
          attributeTheme: _buildAttributeTheme(context),
          componentConfigData: _buildComponentConfig(context),
          builder: (context) => MaterialApp(
            title: 'Flutter Demo',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            home: HomeScreen(),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = DocumentController();

  @override
  Widget build(BuildContext context) {
    // BoustroConfig wraps the three theming classes and provides
    // an implicit animation to switch between themes.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boustro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _showPreview,
          ),
        ],
      ),
      // A BoustroScaffold lays out the editor and toolbar, and ensures
      // toolbar clicks don't cause the editor to lose focus.

      // To maintain focus without a scaffold, wrap the area that should keep
      // the editor focused when clicked in a FocusTrapArea and pass it the
      // focusNode of your DocumentController.
      body: CallbackShortcuts(
        bindings: {
          SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
              _toggleAttribute(boldAttribute),
          SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
              _toggleAttribute(italicAttribute),
          SingleActivator(LogicalKeyboardKey.keyU, control: true): () =>
              _toggleAttribute(underlineAttribute),
        },
        child: BoustroScaffold(
          focusNode: controller.focusNode,
          // The auto formatter automatically applies attributes to text
          // matching regular expressions. Some patterns are provided
          // in CommonPatterns for convenience.
          editor: AutoFormatter(
            controller: controller,
            rules: [
              FormatRule.group(CommonPatterns.hashtag, 1, (_) => boldAttribute),
              FormatRule.group(
                  CommonPatterns.mention, 1, (_) => italicAttribute),
              FormatRule.group(CommonPatterns.httpUrl, 1, (_) => boldAttribute),
            ],
            // DocumentEditor is the main editor class. It manages the
            // paragraphs that are either embeds (custom widgets) or
            // TextFields with custom TextEditingControllers that manage
            // spans for formatting.
            child: DocumentEditor(
              controller: controller,
            ),
          ),
          // The Toolbar contains buttons that can modify the document using
          // the DocumentController. There are built-in ToolbarItems for the
          // boustro_starter components. Toolbar has support for nested menus
          // (try the image button).
          toolbar: Toolbar(
            documentController: controller,
            defaultItemBuilder: _defaultToolbarItemBuilder,
            items: [
              toolbar_items.bold,
              toolbar_items.italic,
              toolbar_items.underline,
              toolbar_items.link(),
              // TODO toolbar_items.title,
              toolbar_items.image(
                pickImage: (_) async => const NetworkImage(
                    'https://upload.wikimedia.org/wikipedia/commons/1/19/Billy_Joel_Shankbone_NYC_2009.jpg'),
                snapImage: (_) async => const NetworkImage(
                    'https://upload.wikimedia.org/wikipedia/commons/1/19/Billy_Joel_Shankbone_NYC_2009.jpg'),
              ),
              // TODO toolbar_items.bulletList,
              ToolbarItem(
                title: const Icon(Icons.wb_sunny),
                onPressed: (context, __) =>
                    ThemeModeScope.of(context).toggle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPreview() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Preview')),
          // DocumentView displays a document readonly.
          body: DocumentView(
            document: controller.toDocument(),
          ),
        ),
      ),
    );
  }

  Widget _defaultToolbarItemBuilder(
    BuildContext context,
    DocumentController controller,
    ToolbarItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Center(
        child: IconButton(
          splashColor: Colors.transparent,
          onPressed: item.onPressed == null
              ? null
              : () => item.onPressed!(context, controller),
          icon: item.title!,
          tooltip: item.tooltip,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleAttribute(TextAttribute attribute) {
    final focusedLine = controller.getFocusedText();
    focusedLine?.textController.toggleAttribute(attribute);
  }
}

Future<void> _handleLinkTap(BuildContext context, String link) async {
  if (!link.contains('://')) {
    link = 'http://$link';
  }
  final uri = Uri.tryParse(link);
  if (uri != null) {
    try {
      await launchUrl(uri);
    } catch (_) {}
  }
}

final darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade800,
  ),
  dividerColor: Colors.black12,
);

final lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Colors.blue,
    onPrimary: Colors.grey.shade800,
  ),
  appBarTheme: AppBarTheme(backgroundColor: Colors.grey.shade200),
  dividerColor: Colors.grey.shade300,
);
