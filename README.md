# WonderStyler

Neovim plugin for extracting and visualizing CSS classes from any file type by parsing `class=""` and`className="" or className={}` attributes, with support for both regular CSS and CSS Modules syntax.

## Problem

When working with large React applications using CSS Modules and utility-first CSS frameworks:

- Class structures become complex and hard to track
- Mixing CSS Modules with regular CSS classes creates cognitive overhead
- Conditional class applications (via clsx/classnames) make it difficult to see the full styling structure
- BEM methodology becomes harder to maintain without proper visualization

## Solution

WonderStyler parses your React/TSX files and generates a clean, hierarchical view of all CSS classes, showing:

- Native CSS classes with their modifiers and elements
- CSS Module structures separated by module
- BEM structure visualization with proper nesting
- Support for conditional class applications

## Features

- **Smart Parsing**: Handles both `className` and `class` attributes
- **Multiple Syntax Support**:
  - Regular CSS classes
  - CSS Modules
  - clsx/classnames library syntax
  - Conditional class applications
  - Template literals
- **BEM Structure Recognition**:
  - Block-Element relationships (`block__element`)
  - Modifiers (`block_modifier`, `block__element_modifier`)
- **Case-Sensitive Module Handling**: Maintains proper casing for module imports
- **Interactive UI**:
  - Floating window with syntax highlighting
  - Easy navigation and dismissal
  - SCSS syntax formatting

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "mr-scrpt/wonderstyler",
  keys = {
    { "<leader>wg", ":WonderStylerGenerate<CR>", desc = "Style Generate [Wonderstyler]" },
    { "<leader>wl", ":WonderStylerShow<CR>", desc = "Style Show [Wonderstyler]" },
  },
  config = function()
    require("wonderstyler").setup()
  end,
}
```

## Usage

1. Open a React/TSX file
2. Run `:WonderStylerGenerate` or use `<leader>wg` to parse classes
3. Run `:WonderStylerShow` or use `<leader>wl` to view the structure
4. Press `q` or `<Esc>` to close the viewer

## Example

Input TSX code:

```tsx
export const NavigationMainLayout: FC<NavigationMainLayoutProps> = (props) => {
  const { className, MenuSlost, listSize } = props;
  return (
    <RowSection
      topology="ROW_CONTAINER"
      className={clsx(sNavigationMainLayout.root, className)}
    >
      <div className={sNavigationMainLayout.inner}>
        <div
          className={clsx(
            sNavigationMainLayout.menu,
            sNavigationMainLayout.menu_top,
          )}
        >
          {MenuSlost}
        </div>
        <ListComponent
          className={clsx("list list_top", sList.list, {
            [sList.list_l]: listSize == "L",
            [slist.list_m]: listSize == "M",
            [sList.list_s]: listSize == "S",
          })}
        >
          <div className={clsx(sList.inner, "list__inner")}>
            <div
              className={clsx(
                sList.item,
                sNavigationMainLayout.menu__item,
                "list__item",
              )}
            >
              <div className={sList.content}>
                <div className={sList.title}>Доставка</div>
              </div>
            </div>
          </div>
        </ListComponent>
      </div>
    </RowSection>
  );
};
```

Output SCSS structure:

```scss
/* Native CSS */
.list {
  &_top {
  }
  &__item {
  }
  &__inner {
  }
}

/* Module: sNavigationMainLayout */
.root {
}
.inner {
}
.menu {
  &_top {
  }
  &__item {
  }
}

/* Module: sList */
.content {
}
.list {
  &_l {
  }
  &_s {
  }
  &_m {
  }
}
.title {
}
.inner {
}
.item {
}
```

## Requirements

- Neovim >= 0.5.0
- Tree-sitter (for better syntax recognition)

## Credits

Created by [mr-scrpt](https://github.com/mr-scrpt)
