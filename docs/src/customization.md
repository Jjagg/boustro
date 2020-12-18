# Customization

Boustro is designed to be extremely customizable.

The `boustro` library itself does not define any `TextAttributes`, `LineModifiers` or
`ParagraphEmbeds`, meaning all of those can be provided by the user. Of course, there's some
common components a rich text editor is supposed to have out of the box.

To that end, a supplementary library called [`boustro_starter`](boustro_starter.md) is developed
alongside boustro.  It contains a bunch of components that you can directly use with boustro.

To learn how to:

- Theme `boustro` widgets such as the editor and the toolbar, see [Theming boustro](customization/theming_boustro.md).
- Create and theme attributes, see [Attributes](customization/attributes.md).
- Create and theme line modifiers, see [Embeds](customization/embeds.md).
- Create and theme embeds, see [Embeds](customization/embeds.md).
