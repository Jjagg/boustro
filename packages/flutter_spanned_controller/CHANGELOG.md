## [0.5.0+1]

- Add example.

## [0.5.0]

- **Added** `StringDiff.isEmpty` and `StringDiff.isNotEmpty`.
- **Added** `getSpans` and `getTypedSpans` to `SpanList`.
- **Added** `SpanController.getAppliedSpansWithUnsafeType`.

- **Fixed**: `GestureRecognizers` on spans are now indexed with their attribute instead of the resolved attribute value,
  because function object equality does not work with inline lambdas.
- **Fixed**: `SpannedTextEditingController.buildTextSpan` did not translate composition indices, causing an exception in
  some cases with characters that take up multiple code units in UTF-16 (like most emoji).

- **Changed**: `TextAttribute.resolve` now takes a `BuildContext` instead of taking an `AttributeTheme` directly.
- **Changed**: made `TextStyle` in `buildTextSpans` optional.

## [0.4.0-0]

- **Removed** `TextAttribute.simple`. In favor of custom classes, so each attribute has its own type and
  serialization can use the type to determine which encoder to use.

- **Changed**: moved `ExpandRules` to be a part of attributes themselves.

## [0.3.0-0]

- **Added** system to theme `TextAttributes` with `AttributeTheme`.
- **Added** `Range` to avoid confusion with `TextRange`.
  `TextRange` is designed to be for indexing into `String` by UTF-16 code units.

- **Changed**: `TextAttribute` now has a resolve method that returns the actual information for
  applying the attribute in the form of `TextAttributeValue`.
- **Changed**: the `characters` library is used to index with grapheme clusters instead of UTF-16 code units.
  This changes most `String`-based API to use `Characters` instead.
- **Changed**: use `Range` in `AttributeSpan` and related classes to avoid confusion with UTF-16 indices used by `TextRange`.
- **Changed**: renamed `SpanList.spans` to `iter` to prevent confusing `spans.spans`.
- **Changed**: `SpannedTextEditingController` takes a `SpanList` now instead of `Iterable<AttributeSpan>`.
- **Changed**: renamed `InsertBehavior` to `ExpandRule` and `FullInsertBehavior` to `SpanExpandRules`.
  Finally, I've come up with the right name for this concept :)
- **Changed**: rename `SpannedString()` to `SpannedString.chars()` and let unnamed constructor take `String`.

- **Fixed**: Changed library name from flutter\_span\_controller to flutter\_spann**ed**\_controller.

## [0.2.0-0]

- **Added**: `SpannedStringBuilder` to fluently build `SpannedString`.

## [0.1.1-0]

- **Changed**: Replaced template README with short explanation.

## [0.1.0-0]

**Initial release**.

[Unreleased]: https://github.com/Jjagg/boustro/tree/main/packages/flutter_spanned_controller
[0.5.0+1]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.5.0+1/packages/flutter_spanned_controller
[0.5.0]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.5.0/packages/flutter_spanned_controller
[0.4.0-0]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.4.0-0/packages/flutter_spanned_controller
[0.3.0-0]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.3.0-0/packages/flutter_spanned_controller
[0.2.0-0]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.2.0-0/packages/flutter_spanned_controller
[0.1.1-0]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.1.1-0/packages/flutter_spanned_controller
[0.1.0-0]: https://github.com/Jjagg/boustro/tree/9aa26d5459ecf7447bd8accc6fc31938b1d6d5aa/packages/flutter_spanned_controller
