# `boustro_starter`

Boustro — the rich text editor itself — does not know how to apply text attributes or line
modifiers, or draw any embeds[^components]. Instead, it uses abstractions to make it as
extensible[^extensible] as possible.

A modest set of common components is therefore provided by another library: `boustro_starter`.
It provides range of components that are commonly required in a rich text editor. Here, you'll find
a list of components provided.

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
