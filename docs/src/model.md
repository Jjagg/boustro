# Model

This chapter describes how rich text content is represented in boustro.
The terminology from this chapter is used throughout the book.

## Document

A document in boustro is a list of lines of formatted text and embeddable content (called embeds).
An immutable document is represented by a [`Document`](https://pub.dev/documentation/boustro/latest/boustro/Document-class.html).
While editing a document, its state is maintained by a [`DocumentController`](https://pub.dev/documentation/boustro/latest/boustro/Document-class.html).

A document holds a collection of [`Paragraphs`](https://pub.dev/documentation/boustro/latest/boustro/Paragraph-class.html).
Paragraphs are either a [line of rich text](https://pub.dev/documentation/boustro/latest/boustro/TextLine-class.html) —
or an [embed](https://pub.dev/documentation/boustro/latest/boustro/ParagraphEmbed-class.html) —
which can be any custom content, for example an image or a code block.

## Text

A text line represents rich text using a [spanned string](https://pub.dev/documentation/boustro/latest/boustro/SpannedString-class.html).
Text lines can be modified with [line modifiers](https://pub.dev/documentation/boustro/latest/boustro/LineModifier-class.html).
These modifiers wrap a line of text and can modify how they are displayed or override their style.
Boustro has a modifier for bullet lists.

Spanned strings hold text, along with a list of spans that apply formatting or attach gestures to
the text. The mutable version of a `SpannedString` is a [`SpannedTextEditingController`](https://pub.dev/documentation/boustro/latest/boustro/SpannedString-class.html) —
a subclass of Flutter's [`TextEditingController`](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html)
that manages formatting of its text.

Both `SpannedString` and `SpannedTextEditingController` maintain a [`SpanList`](https://pub.dev/documentation/boustro/latest/boustro/SpanList-class.html).
`SpanList` is an immutable list of [`AttributeSpan`](https://pub.dev/documentation/boustro/latest/boustro/AttributeSpan-class.html).

Attribute spans hold an attribute and a range:

- [`Range`](https://pub.dev/documentation/boustro/latest/boustro/Range-class.html):
  range in the source text to which the attribute is applied. The boundaries of the range are
  indices into the source text, using [Unicode (Extended) Grapheme Clusters](https://unicode.org/reports/tr29/)
  (EGC) as the unit. EGC map to user-perceived characters. EGC indices are used to prevent indices
  in the middle of user-perceived characters. If you use a `Range` directly, you likely want to use
  the [`characters`](https://pub.dev/packages/characters) package.
- [`TextAttribute`](https://pub.dev/documentation/boustro/latest/boustro/TextAttribute-class.html):
  The attribute can be resolved to a `TextStyle` (to apply formatting) and gestures (for example tap handler that opens a
  hyperlink) with its `resolve` method, which can optionally use an [`AttributeTheme`](https://pub.dev/documentation/boustro/latest/boustro/AttributeTheme-class.html)
  to resolve to a style and gestures. The attribute also defines [`SpanExpandRules`](https://pub.dev/documentation/boustro/latest/boustro/SpanExpandRules-class.html)
  which determine how the span responds to insertions in the source text.

## Embeds

An embed, in boustro, is a custom piece of content that can be embedded in rich text.

Visually, an embed can be any widget, and users can define different widgets for the editable and view-only version of the embed.

See [Embeds](customization/embeds.md) to learn how embeds work and how to create custom embeds.

## Component

A component is any implementation of `TextAttribute`, `LineModifier` or `ParagraphEmbed`. This
concept is not used within boustro itself, but it's useful to define it for talking about
[customization](customization.md) in boustro.
