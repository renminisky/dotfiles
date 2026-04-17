## Before install script (skip this on mac)

1. install apt packages

    ```
    sudo apt update
    sudo apt upgrade
    sudo apt install -y build-essential procps curl file git wget zsh
    ```

1. change to zsh shell

    ```
    chsh -s $(which zsh)
    exec zsh
    ```

    press `q` when prompt with zsh config wizard

    you can check with: `echo $0` for current shell and `echo $SHELL` for default login shell

## Run installation script

1. git clone this repo

1. run install.zsh

    ```
    ./dotfiles/install.zsh
    ```


## After install script

1. install nerd fonts (JetBrainsMono) https://www.nerdfonts.com/font-downloads
    
    - in vscode, set `"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"` in settings.js 

1. edit private config files in `/dotfiles/private_config`

1. generate SSH keys

    check if ssh key exist

    ```
    ls -al ~/.ssh
    ```

    generate ssh keys
    
    ```
    ssh-keygen -t ed25519 -C "your_email@example.com"
    ```