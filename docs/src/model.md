# Model

This chapter describes how rich text content is represented in boustro.

## Document

A document in boustro is a list of lines of formatted text and embeddable content (called embeds).
An immutable document is represented by a [`Document`](https://pub.dev/documentation/boustro/latest/boustro/Document-class.html).
While editing a document, its state is maintained by a [`DocumentController`](https://pub.dev/documentation/boustro/latest/boustro/Document-class.html).

A document holds a collection of [`Paragraphs`](https://pub.dev/documentation/boustro/latest/boustro/Paragraph-class.html).
Paragraphs are either a [`TextLine`](https://pub.dev/documentation/boustro/latest/boustro/TextLine-class.html) —
for rich text content — or an [embed](https://pub.dev/documentation/boustro/latest/boustro/ParagraphEmbed-class.html),
which can be any custom content, for example an image or a code block.

## Text

A text line represents rich text using a [`SpannedString`](https://pub.dev/documentation/flutter_spanned_controller/latest/flutter_spanned_controller/SpannedString-class.html).
Text lines can be modified with [`LineModifiers`](https://pub.dev/documentation/boustro/latest/boustro/LineModifier-class.html).
These modifiers wrap a line of text and can modify how they are displayed or override their style.
For example, `boustro_starter` has modifiers for block quotes or list items (bullet or numbered).

Spanned strings hold text, along with a list of spans that apply formatting or attach gestures to
the text. The mutable version of a `SpannedString` is a [`SpannedTextEditingController`](https://pub.dev/documentation/flutter_spanned_controller/latest/flutter_spanned_controller/SpannedString-class.html) —
a subclass of Flutter's [`TextEditingController`](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html)
that manages formatting of its text.

Both `SpannedString` and `SpannedTextEditingController` maintain a [`SpanList`](https://pub.dev/documentation/flutter_spanned_controller/latest/flutter_spanned_controller/SpanList-class.html).
`SpanList` is an immutable list of [`AttributeSpan`](https://pub.dev/documentation/flutter_spanned_controller/latest/flutter_spanned_controller/AttributeSpan-class.html).

Attribute spans hold three values:

- A range in the source text to which the attribute is applied. The boundaries of the range are
  indices into the source text, using [Unicode (Extended) Grapheme Clusters](https://unicode.org/reports/tr29/)
  (EGC) as the unit. EGC map to user-perceived characters. EGC indices are used to prevent indices
  in the middle of user-perceived characters.
- A [`TextAttribute`](https://pub.dev/documentation/flutter_spanned_controller/latest/flutter_spanned_controller/TextAttribute-class.html).
  The attribute can be resolved to a `TextStyle` (to apply formatting) and gestures (for example tap handler that opens a
  hyperlink).
- An [`ExpandRule`](https://pub.dev/documentation/flutter_spanned_controller/latest/flutter_spanned_controller/ExpandRule-class.html)
  for its start and end indices. These rules determine how the span responds to insertions in the
  source text.

## Embeds

Embeds in boustro can be pretty much anything as long as it extends `ParagraphEmbed`.
Users should override the `build` method to create a `Widget` for the embed.

## Component

A component is any implementation of `TextAttribute`, `LineModifier` or `ParagraphEmbed`. This
concept is not used within boustro itself, but it's useful to define it for talking about
[customization](customization.md) in boustro.
