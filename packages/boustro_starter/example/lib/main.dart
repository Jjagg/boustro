// ignore_for_file: diagnostic_describe_all_properties, use_key_in_widget_constructors, public_member_api_docs
import 'package:boustro/boustro.dart';
import 'package:boustro_starter/boustro_starter.dart';
import 'package:boustro_starter/toolbar_items.dart' as toolbar_items;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, child) => MaterialApp(
        title: 'Flutter Demo',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = DocumentController();

  /// The attribute theme is used to customize the effect of [TextAttribute].
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
    // BoustroConfig wraps the three theming classes and provides
    // an implicit animation to switch between themes.
    return BoustroConfig(
      attributeTheme: _buildAttributeTheme(context),
      componentConfigData: _buildComponentConfig(context),
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Boustro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _showPreview,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              // The auto formatter automatically applies attributes to text
              // matching regular expressions. Some patterns are provided
              // in CommonPatterns for convenience.
              child: AutoFormatter(
                controller: controller,
                rules: [
                  FormatRule(CommonPatterns.hashtag, (_) => boldAttribute),
                  FormatRule(CommonPatterns.mention, (_) => italicAttribute),
                  FormatRule(CommonPatterns.httpUrl, (_) => boldAttribute),
                ],
                // DocumentEditor is the main editor class. It manages the
                // paragraphs that are either embeds (custom widgets) or
                // TextFields with custom TextEditingControllers that manage
                // spans for formatting.
                child: DocumentEditor(
                  controller: controller,
                ),
              ),
            ),
            // The Toolbar contains buttons that can modify the document using
            // the DocumentController. There are built-in ToolbarItems for the
            // boustro_starter components. Toolbar has support for nested menus
            // (try the image button).
            Toolbar(
              documentController: controller,
              defaultItemBuilder: _defaultToolbarItemBuilder,
              items: [
                toolbar_items.bold,
                toolbar_items.italic,
                toolbar_items.underline,
                toolbar_items.link(),
                toolbar_items.title,
                toolbar_items.image(
                  pickImage: (_) async => const NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/1/19/Billy_Joel_Shankbone_NYC_2009.jpg'),
                  snapImage: (_) async => const NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/1/19/Billy_Joel_Shankbone_NYC_2009.jpg'),
                ),
                toolbar_items.bulletList,
                ToolbarItem(
                  title: const Icon(Icons.wb_sunny),
                  onPressed: (context, __) =>
                      ThemeModeScope.of(context).toggle(context),
                ),
              ],
            ),
          ],
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
}

Future<void> _handleLinkTap(BuildContext context, String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  }
}

final darkTheme = ThemeData(
  primarySwatch: Colors.grey,
  primaryColor: Colors.grey.shade800,
  brightness: Brightness.dark,
  accentColor: Colors.grey.shade100,
  dividerColor: Colors.black12,
);

final lightTheme = ThemeData(
  primarySwatch: Colors.grey,
  primaryColor: Colors.grey.shade200,
  brightness: Brightness.light,
  accentColor: Colors.grey.shade50,
  dividerColor: Colors.white54,
);
