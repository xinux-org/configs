#!/usr/bin/env bash
#This script created by Abduazimov Abdurakhman https://github.com/abdurakhman-uz/

# Dirs
DIR=`pwd`
FDIR="$HOME/.local/share/fonts"
CDIR="$HOME/.config"


# Install Fonts
install_fonts() {
        echo -e "\n[*] Installing fonts..."
        [[ ! -d "$FDIR" ]] && mkdir -p "$FDIR"
        cp -rf $DIR/fonts/* "$FDIR"
}

# Install Configs
install_configs() {
        if [[ -d "$CDIR" ]]; then
                echo -e "[*] Creating a backup of your old configs..."
                mv "$CDIR" "${CDIR}.old"
                { mkdir -p "$CDIR"; cp -rf $DIR/* "$CDIR"; }
        else
                { mkdir -p "$CDIR"; cp -rf $DIR/* "$CDIR"; }
        fi
}

# Install
install() {

install_fonts
install_configs

echo 'Themes Succesfull Installed'

}

install
