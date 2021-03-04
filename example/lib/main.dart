import 'package:boustro/boustro.dart';
import 'package:boustro_starter/boustro_starter.dart';
import 'package:boustro_starter/toolbar_items.dart' as toolbar_items;
import 'package:example/theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  late final controller = DocumentController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoustroConfig(
      attributeTheme: (AttributeThemeBuilder()
            ..boldFontWeight = FontWeight.w900
            ..linkOnTap = (context, url) async {
              if (await canLaunch(url)) {
                await launch(url);
              }
            })
          .build(),
      componentConfigData: Theme.of(context).brightness == Brightness.light
          ? (BoustroComponentConfigBuilder()
                ..imageMaxHeight = 400
                ..imageSideColor = Colors.brown.withOpacity(0.2))
              .build()
          : (BoustroComponentConfigBuilder()
                ..imageMaxHeight = 350
                ..imageSideColor = Colors.deepPurple.shade900.withOpacity(0.2))
              .build(),
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text('Boustro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (context) {
                    return Scaffold(
                      appBar: AppBar(title: Text('Preview')),
                      body: DocumentView(
                        document: controller.toDocument(),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              // Demo the auto formatter text separated with hashtags, mentions
              // and URLs.
              child: AutoFormatter(
                controller: controller,
                rules: [
                  FormatRule(CommonPatterns.hashtag, (_) => boldAttribute),
                  FormatRule(CommonPatterns.mention, (_) => italicAttribute),
                  FormatRule(CommonPatterns.httpUrl, (_) => boldAttribute),
                ],
                child: DocumentEditor(
                  controller: controller,
                ),
              ),
            ),
            Toolbar(
              documentController: controller,
              defaultItemBuilder: (context, controller, item) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
              },
              items: [
                toolbar_items.bold,
                toolbar_items.italic,
                toolbar_items.underline,
                toolbar_items.link(),
                toolbar_items.title,
                toolbar_items.image(
                  pickImage: (_) async => NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/1/19/Billy_Joel_Shankbone_NYC_2009.jpg'),
                  snapImage: (_) async => NetworkImage(
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
}
