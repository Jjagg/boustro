# boustro

Boustro is a rich text editor for Flutter.

## Features

### Themeable with dark and light defaults

### Easy to customize

## Getting Started

Check out the [example](example).

### Glossary and Concepts

- **Document**: Immutable representation of a rich text document.
- **Paragraph**: A line of text or non-inline embed.
- **Line**: A line of text with rich formatting.
- **Embed**: Any content in a document that is not rich text.
- **Line modifier**: Wraps a line and can change the way it's displayed.
- **Text attribute**: Applied to text to set its formatting or add gesture recognizers.
- **Span**: Text range with a text attribute and rules for how the range behaves when text is inserted (whether it is expanded or not).

## Repo structure

Boustro is split into 3 packages that are layered on top of each other.

1. [flutter_spanned_controller](packages/flutter_spanned_controller): The
`TextEditingController` implementation that makes formatting of editable
text possible and data structures to represent text formats and formatted
text. The structure is similar to Android's [Spannable](https://developer.android.com/reference/android/text/Spannable).
1. [boustro](packages/boustro): The actual rich text editor.
1. [boustro_starter](packages/boustro_starter): Attributes, line modifiers and embeds to get started with boustro.

## Limitations

- Can't select across lines. I might be able to fix this issue and make line handling (newlines and
backspace at the start to delete lines) less hacky by using only a single `TextField`. However, this
would greatly complicate the line paragraph system, and I'm not sure that's worth it.
- At most 1 gesture per `TextSpan`. `TextSpan` can have a gesture recognizer,
but not multiple. We can solve this by using a `WidgetSpan` that wraps a `GestureRecognizer`, that wraps
the actual text span, but that's blocked by:
  - [Support WidgetSpan in SelectableText](https://github.com/flutter/flutter/issues/38474)
  - [Support WidgetSpan in EditableText](https://github.com/flutter/flutter/issues/30688)
- The same issues prevent me from creating inline embeds (e.g. inline images) using `WidgetSpan`. Please
go upvote these issues if you'd like to see these limitations overcome.

## Alternatives

- [Zefyr](https://github.com/memspace/zefyr): A big inspiration for this project.
