import 'package:boustro/boustro.dart';
import 'package:boustro_starter/boustro_starter.dart';
import 'package:boustro_starter/toolbar_items.dart' as toolbar_items;
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class ThemeModeScope extends InheritedWidget {
  ///
  const ThemeModeScope({
    Key? key,
    required this.notifier,
    required Widget child,
  }) : super(key: key, child: child);

  final ThemeModeNotifier notifier;

  static ThemeModeNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    return scope!.notifier;
  }

  @override
  bool updateShouldNotify(covariant ThemeModeScope oldWidget) {
    return notifier != oldWidget.notifier;
  }
}

class ThemeModeNotifier extends ValueNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode? value) : super(value ?? ThemeMode.system);

  void setSystem() {
    value = ThemeMode.system;
  }

  void toggle(BuildContext context) {
    Brightness current;
    if (value == ThemeMode.light) {
      current = Brightness.light;
    } else if (value == ThemeMode.dark) {
      current = Brightness.dark;
    } else {
      current = MediaQuery.platformBrightnessOf(context);
    }

    value = current == Brightness.light ? ThemeMode.dark : ThemeMode.light;
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

  late ThemeModeNotifier themeModeNotifier =
      ThemeModeNotifier(ThemeMode.system);

  @override
  void dispose() {
    themeModeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeScope(
      notifier: themeModeNotifier,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, themeMode, child) => MaterialApp(
          title: 'Flutter Demo',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: HomeScreen(),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class BulletListParagraphHandler extends LineParagraphModifier {
  const BulletListParagraphHandler();

  @override
  Widget modify(
    BuildContext context,
    Map<String, Object> properties,
    Widget child,
  ) {
    return LeadingTextModifier(
      padding: 8,
      text: '\u2022',
      child: child,
    );
  }

  @override
  int get priority => 0;

  @override
  bool shouldBeApplied(Map<String, Object> properties) {
    return properties['list'] == 'bullet';
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late final scrollController = ScrollController();
  late final controller =
      DocumentController(scrollController: scrollController);

  final boustroContext = BoustroContext(
    lineHandlers: const [BulletListParagraphHandler()],
    embedHandlers: [
      ImageEmbed(),
    ],
  );

  @override
  void dispose() {
    scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBoustroTheme(
      data: BoustroTheme.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Boustro'),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  Navigator.of(context)
                      .push<void>(MaterialPageRoute<void>(builder: (context) {
                    return Scaffold(
                      body: BoustroView(
                        context: boustroContext,
                        document: controller.toDocument(),
                      ),
                    );
                  }));
                },
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BoustroEditor(
                controller: controller,
                context: boustroContext,
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
                      icon: item.title,
                      tooltip: item.tooltip,
                    ),
                  ),
                );
              },
              items: [
                toolbar_items.bold,
                toolbar_items.italic,
                toolbar_items.underline,
                ToolbarItem.sublist(
                  title: const Icon(Icons.photo),
                  items: [
                    ToolbarItem(
                      title: const Icon(Icons.photo_camera),
                      onPressed: (context, controller) {
                        final embed = controller
                            .insertEmbedAtCurrent(const BoustroParagraphEmbed(
                          'image',
                          NetworkImage(
                              'https://upload.wikimedia.org/wikipedia/commons/1/19/Billy_Joel_Shankbone_NYC_2009.jpg'),
                        ));
                        embed?.focusNode.requestFocus();
                        if (embed != null) {
                          Toolbar.popMenu(context);
                        }
                      },
                    ),
                    ToolbarItem(
                      title: const Icon(Icons.photo_library),
                      onPressed: (_, __) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Left as an exercise to the reader.'),
                          ),
                        );
                      },
                    ),
                  ],
                  tooltip: 'Insert image',
                ),
                ToolbarItem(
                  title: const Icon(Icons.list),
                  onPressed: (context, controller) {
                    final line = controller.focusedLine;
                    if (line != null) {
                      final isBullet = line.properties['list'] == 'bullet';
                      final props = isBullet
                          ? line.properties.rebuild((r) => r.remove('list'))
                          : line.properties
                              .rebuild((r) => r['list'] = 'bullet');
                      controller.setLineProperties(line, props.asMap());
                    }
                  },
                ),
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
