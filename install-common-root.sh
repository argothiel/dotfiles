#!/bin/bash

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage &&
chmod +x nvim.appimage &&
mv nvim.appimage /usr/local/bin/nvim

curl -L https://api.github.com/repos/nelsonenzo/tmux-appimage/releases/latest |
grep "browser_download_url.*appimage" |
cut -d : -f 2,3 |
tr -d \" |
wget -qi - &&
chmod +x tmux.appimage && mv tmux.appimage /usr/local/bin/tmux
