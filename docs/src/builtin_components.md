# Built-in components

Boustro — the rich text editor itself — does not know how to apply .

Boustro uses abstractions to make it as extensible[^extensible] as possible.
Any text attributes, line modifiers and embeds[^components] can be defined in user code.

Boustro provides a range of built-in components that are commonly required in a rich
text editor. Here, you'll find a list of components provided.

## Attributes

- Bold
- Italic
- Underline
- Strikethrough
- Link (with user-defined callback)

## Line Modifiers

- Bullet list
- **Numbered list (TODO)**
- **Blockquote (TODO)**

## Embeds

- Image
- **Code block (TODO)**

If you're missing a component that is generally useful, please [open an issue](https://github.com/Jjagg/boustro/issues)
to request it.

[^components]: For an explanation of these concepts, see [Model](model.md).

[^extensible]: See [Customization](customization.md)
for more information about the different ways in which boustro can be
customized.
