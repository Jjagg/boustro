**The packages maintained in this repository depend on a prerelease version of Flutter. I'm waiting for the required change to land in the stable Flutter SDK before publishing the packages to pub.dev.**

<p align="center">
  <a href="https://github.com/Jjagg/boustro/actions"><img src="https://github.com/Jjagg/boustro/workflows/Build/badge.svg" alt="Build Status"></a>
<a href="https://codecov.io/gh/Jjagg/boustro"><img src="https://codecov.io/gh/Jjagg/boustro/branch/main/graph/badge.svg" alt="codecov"></a>
</p>

# boustro

Boustro is a rich text editor for Flutter.

| **flutter_spanned_controller** | [![pub package](https://img.shields.io/pub/v/flutter_spanned_controller.svg?color=blue)](https://pub.dev/packages/flutter_spanned_controller) |
| ------------------------------ | ----------- |
| **boustro**                    | Unpublished |
| **boustro_starter**            | Unpublished |

## Features

### Easy to customize

Boustro is designed to be extremely customizable.

The boustro library itself does not define any of formatting modifiers or embedded content.
Instead, it provides the base infrastructure to implement these components outside of boustro.
This way, any custom components can be implemented in user code.

Documentation on writing custom components has not yet been written. For now, check out the
implementation of the start components in `boustro_starter`.

Of course, there's some common components a rich text editor is supposed to have out of the box.
To that end, a supplementary library called `boustro_starter` is developed alongside boustro.
It contains a bunch of components that you can directly use with boustro.

### Themeable with dark and light defaults

Boustro defines extensible theming classes that let users customize the base editor,
as well as any components implemented outside of boustro itself. These theme classes
even support lerping, for a nice animation when switching themes.

### Cross-platform

Boustro builds on Flutter's built-in text widgets, without any custom rendering,
so it runs on all platforms supported by Flutter.

## Getting Started

Check out the [example](packages/boustro_starter/example).

### Glossary and Concepts

- **Document**: Immutable representation of a rich text document.
- **Paragraph**: Can be either a line of text or (non-inline) embed.
- **Line**: A line of text with rich formatting.
- **Embed**: Any content in a document that is not a Line.
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

## Keep a Changelog + SemVer

Changelogs for the packages document all notable changes.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
