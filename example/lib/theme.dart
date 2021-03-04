import 'package:flutter/material.dart';

class ThemeModeScope extends InheritedWidget {
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

class ThemeBuilder extends StatefulWidget {
  const ThemeBuilder({Key? key, required this.builder}) : super(key: key);

  final ValueWidgetBuilder<ThemeMode> builder;

  @override
  _ThemeBuilderState createState() => _ThemeBuilderState();
}

class _ThemeBuilderState extends State<ThemeBuilder> {
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
        builder: widget.builder,
      ),
    );
  }
}
