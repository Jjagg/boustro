import 'package:boustro/boustro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ImageEmbed extends ParagraphEmbedBuilder {
  @override
  String get key => 'image';

  @override
  Widget buildEmbed(
    BoustroScope scope,
    BoustroParagraphEmbed embed, [
    FocusNode? focusNode,
  ]) {
    return _ImageEmbed(
      scope: scope,
      embed: embed,
      focusNode: focusNode,
    );
  }
}

class _ImageEmbed extends StatelessWidget {
  _ImageEmbed({
    required this.scope,
    required this.embed,
    required this.focusNode,
  });

  BoustroScope scope;
  BoustroParagraphEmbed embed;
  FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (!scope.editable) {
      return _buildContent(context, imageWrapper: _center);
    }

    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          return GestureDetector(
            onTap: () {
              if (!focusNode.hasFocus) {
                focusNode.requestFocus();
              }
            },
            child: _buildContent(
              context,
              imageWrapper: _buildOverlay,
            ),
          );
        },
      ),
    );
  }

  Widget _center(BuildContext context, Widget child) => Center(child: child);

  Widget _buildOverlay(BuildContext context, Widget child) {
    final hasFocus = Focus.of(context).hasFocus;
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: AnimatedCrossFade(
              crossFadeState: hasFocus
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 800),
              firstChild: SizedBox(),
              secondChild: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildButton(
                        context: context,
                        icon: Icons.edit,
                        onPressed: () {},
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildButton(
                        context: context,
                        icon: Icons.close,
                        onPressed: () {
                          scope.controller!.removeCurrentParagraph();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Widget Function(BuildContext context, Widget child) imageWrapper,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget image = Image(
      image: embed.value as ImageProvider,
      fit: BoxFit.contain,
    );

    image = imageWrapper(context, image);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Container(
        color: isDark
            ? Colors.deepPurple.shade900.withOpacity(0.2)
            : Colors.brown.withOpacity(0.2),
        child: image,
      ),
    );
  }
}

//class OverlayButton extends StatefulWidget {
//  @override
//  _OverlayButtonState createState() => _OverlayButtonState();
//}
//
//class _OverlayButtonState extends State<OverlayButton> {
//  late final OverlayEntry? _overlayEntry = _createOverlayEntry();
//  final LayerLink _layerLink = LayerLink();
//  bool _overlayIsShown = false;
//
//  @override
//  void dispose() {
//    super.dispose();
//    if (_overlayIsShown) {
//      _hideOverlay();
//    }
//  }
//
//  void _showOverlay() {
//    if (_overlayIsShown) return;
//    Overlay.of(context).insert(_overlayEntry);
//    _overlayIsShown = true;
//  }
//
//  void _hideOverlay() {
//    _overlayIsShown = false;
//    _overlayEntry.remove();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return CompositedTransformTarget(
//      link: _layerLink,
//      child: RaisedButton(child: Text('Open Overlay'), onPressed: _showOverlay),
//    );
//  }
//
//  OverlayEntry _createOverlayEntry() {
//    RenderBox renderBox = context.findRenderObject();
//    var anchorSize = renderBox.size;
//    return OverlayEntry(builder: (context) {
//      // TODO: dynamically use the correct child width / height for
//      // positioning us correctly on top + centered on the anchor
//      var childWidth = 200.0;
//      var childHeight = 40.0;
//      var childOffset =
//          Offset(-(childWidth - anchorSize.width) / 2, -(childHeight));
//      return Row(
//        children: <Widget>[
//          CompositedTransformFollower(
//            link: _layerLink,
//            offset: childOffset,
//            child: RaisedButton(
//              child: Text('close'),
//              onPressed: _hideOverlay,
//            ),
//          ),
//        ],
//      );
//    });
//  }
//}
//
//class DeclarativeOverlayEntry extends StatefulWidget {
//  const DeclarativeOverlayEntry({
//    Key? key,
//    required this.overlayBuilder,
//    required this.child,
//    this.overlayAnchor = Alignment.center,
//    this.childAnchor = Alignment.center,
//    this.visible = true,
//  }) : super(key: key);
//
//  final WidgetBuilder overlayBuilder;
//  final Widget child;
//  final bool visible;
//  final Alignment overlayAnchor;
//  final Alignment childAnchor;
//
//  @override
//  _DeclarativeOverlayEntryState createState() =>
//      _DeclarativeOverlayEntryState();
//}
//
//class _DeclarativeOverlayEntryState extends State<DeclarativeOverlayEntry> {
//  late final overlayEntry = OverlayEntry(builder: widget.overlayBuilder);
//
//  @override
//  void initState() {}
//
//  void showOverlayEntry() {
//    if (!overlayEntry.mounted) {
//      assert(() {
//        if (context is! Overlay &&
//            context.findAncestorWidgetOfExactType<Overlay>() == null) {
//          throw FlutterError.fromParts(<DiagnosticsNode>[
//            ErrorSummary('No Overlay found.'),
//            ErrorDescription(
//                'This widget requires an Overlay parent to add its '
//                'overlay to'),
//            ErrorHint(
//                'Include an Overlay widget above this widget in the tree.'),
//          ]);
//        }
//        return true;
//      }(), 'unnreachable');
//
//      final overlay = Overlay.of(context)!;
//      overlay.insert(overlayEntry);
//    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    if (!widget.visible) {
//      return widget.child;
//    }
//
//    return Placeholder();
//  }
//}
