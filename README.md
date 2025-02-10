# WonderStyler

Neovim plugin for extracting and visualizing CSS classes from any file type by parsing `class=""` and`className="" or className={}` attributes, with support for both regular CSS and CSS Modules syntax.

## Problem

When developing applications with many CSS classes:

- Copying and organizing styles from markup to CSS/SCSS files is time-consuming
- Finding all class usages across different files is difficult
- Class structures become complex and hard to track
- Mixing CSS Modules with regular CSS creates overhead
- BEM methodology needs proper structure visualization

## Solution

WonderStyler helps you quickly copy styles from markup to your CSS/SCSS files by:

- Extracting classes from any file type
- Creating a clean, hierarchical structure ready for CSS/SCSS implementation
- Organizing native CSS classes and CSS Modules separately
- Supporting BEM methodology with proper nesting
- Making conditional classes visible and organized

## Features

- **Universal Parsing**: Works with any file containing `class=""` or `className=""` attributes
- **Ready-to-Use Structure**: Generate organized SCSS templates from your markup
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

1. Open any file with class/className attributes
2. Run `:WonderStylerGenerate` or use `<leader>wg` to parse classes
3. Run `:WonderStylerShow` or use `<leader>wl` to view the structure
4. Press `q` or `<Esc>` to close the viewer
5. Copy generated structure to your CSS/SCSS file

## Example

Input code:

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

Generated SCSS structure ready for implementation:

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
