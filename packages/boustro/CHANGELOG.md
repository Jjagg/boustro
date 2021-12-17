## Unreleased

- **Changed**: Merged `boustro_starter` and `flutter_spanned_controller` into `boustro` for easier consumption
  and development. You can find the old changelogs for those packages in the history of the Git repository.
- **Changed**: Boustro now uses marker characters to detect backspace on empty lines.
  See [this blog post](https://medium.com/super-declarative/why-you-cant-detect-a-delete-action-in-an-empty-flutter-text-field-3cf53e47b631) for an explanation on why that's necessary. It uses space characters so capitalization on iOS works properly. They
  are replaced with zero-width spaces when rendered.
- **Added**: `BoustroScaffold` widget that provies a default layout and maintains editor focus when clicking the toolbar.
- **Added**: Link toolbar item support for custom validator and input processor.
- **Fixed**: Link toolbar item URI's does not prepend `https://` for URI's that contain a protocol.

## 0.1.1

- **Added** textSelectable flag to DocumentView.

## 0.1.0

Initial publish.
