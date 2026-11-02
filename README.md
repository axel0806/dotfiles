# dotfiles

GNU Stow packages for an Arch + Hyprland setup. Link a package with
`stow <package>` from this directory, e.g. `stow hypr kitty matugen themes`.

## Dependencies

- `pacman -S hyprland waybar rofi kitty thunar stow matugen awww python-pillow`
- Icons: [WhiteSur](https://github.com/vinceliuice/WhiteSur-icon-theme),
  installed with `./install.sh -d ~/.local/share/icons` (`WhiteSur-dark` is used)

## Wallpapers and colors

- `SUPER+W` opens a wallpaper picker, `SUPER+SHIFT+W` picks a random one
  (`hypr/.config/hypr/scripts/wallpaper.sh`, images in `wallpapers/`).
- Switching runs matugen, which writes kitty's colors to
  `~/.config/kitty/colors-wallpaper.conf`, and `border-colors.py`, which writes
  Hyprland border colors in the wallpaper's complementary hue to
  `~/.config/hypr/colors.lua`. Both are generated, so they're not tracked.
