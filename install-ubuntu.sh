sudo apt update

sudo ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
sudo DEBIAN_FRONTEND=noninteractive apt -y install bash colortest curl fish fzf git git-delta grep libfuse2 lsd nfs-common podman putty-tools python-is-python3 python3-pip rclone ripgrep tzdata wget \
  clang clangd g++ gdb cmake \
  golang-go ruby nodejs npm luarocks cargo composer php openjdk-21-jdk-headless \
  apt-transport-https ca-certificates gnupg curl fd-find tree-sitter-cli \
  python3-jenkinsapi python3-venv

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt update && sudo apt install google-cloud-cli
gcloud init

sudo npm install -g neovim

echo chsh -s /usr/bin/fish
chsh -s /usr/bin/fish

fish_add_path ~/bin
fish -c 'set -Ux EDITOR nvim'
