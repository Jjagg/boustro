# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- System to theme `TextAttributes` with `AttributeTheme`.
- Range to avoid confusion with `TextRange`.
  `TextRange` is designed to be for indexing into `String` by UTF-16 code units.

### Changed

- `TextAttribute` now has a resolve method that returns the actual information for
  applying the attribute in the form of `TextAttributeValue`.
- The `characters` library is used to index with grapheme clusters instead of UTF-16 code units.
  This changes most `String`-based API to use `Characters` instead.
- Use `Range` in `AttributeSpan` and related classes to avoid confusion with UTF-16 indices used by `TextRange`.
- Renamed `SpanList.spans` to `iter` to prevent confusing `spans.spans`.
- `SpannedTextEditingController` takes a `SpanList` now instead of `Iterable<AttributeSpan>`.
- Renamed `InsertBehavior` to `ExpandRule` and `FullInsertBehavior` to `SpanExpandRules`.
  Finally I've come up with the right name for this concept :)

## [0.2.0-0] — 2020-12-14

### Added

- `SpannedStringBuilder` to fluently build `SpannedString`.

## [0.1.1-0] — 2020-12-14

### Changed

- Replaced template README with short explanation.

## [0.1.0-0] — 2020-12-11

Initial release.

[Unreleased]: https://github.com/Jjagg/boustro/tree/main/packages/flutter_spanned_controller
[0.2.0-0]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.2.0-0/packages/flutter_spanned_controller
[0.1.1-0]: https://github.com/Jjagg/boustro/tree/release_fsp_v0.1.1-0/packages/flutter_spanned_controller
[0.1.0-0]: https://github.com/Jjagg/boustro/tree/9aa26d5459ecf7447bd8accc6fc31938b1d6d5aa/packages/flutter_spanned_controller
