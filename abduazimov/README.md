

### Used Resources
- **OS:** [Arch Linux](https://archlinux.org)
- **WM:** [i3-gaps](https://github.com/Airblader/i3)
- **Bar:** [polybar](https://github.com/polybar/polybar)
- **Terminal:** [alacritty](https://github.com/alacritty/alacritty)
- **Application Launcher:** [rofi](https://github.com/davatorium/rofi)
- **Compositor:** [picom](https://github.com/yshui/picom)
- **Notification Deamon:** [dunst](https://github.com/dunst-project/dunst)
- **Monitor of Resources:** [btop](https://github.com/aristocratos/btop)    
- **Icons:** [Papirus dark](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)  

	
### Used Fonts
-  **Interface and Polybar Icon-Fonts:**  [Feather](https://github.com/AT-UI/feather-font/blob/master/src/fonts/feather.ttf)

- **Polybar Font:**  [Iosevka Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Iosevka)

-  **Interface Font:**   [Open Sans](https://fonts.google.com/specimen/Open+Sans#standard-styles)    

- **Monospace Font:** [Roboto Mono](https://fonts.google.com/specimen/Roboto+Mono#standard-styles)

- **Terminal Font:** JetBrains Mono Nerd Fonts

### Use
Download Config files from GitHub:
```
git clone https://github.com/abdurakhman-uz/dotfiles.git
```
Enter the folder we downloaded:
```
cd dotfiles/
```
Execute Setup file
```
chmod +x setup.sh
```
Run Setup script
```
./setup.sh
```
Munually copy Config files to the desired location:
```
cp -r config/i3/ $HOME/.config/
cp -r config/polybar/ $HOME/.config/
cp -r config/rofi/ $HOME/.config/
cp -r config/dunst/ $HOME/.config/
cp -r config/alacritty/ $HOME/.config/
cp -r config/btop/ $HOME/.config/
cp -r config/neofetch/ $HOME/.config/
cp -r config/wallpapers/ $HOME/.config/
cp config/picom.conf $HOME/.config/
```

### Thanks To
- [Diyorbek](https://github.com/DiyorbekOlimov) - For BTOP configs
