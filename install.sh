#!/bin/sh

GREEN=$(tput setaf 28)
MAGENTA=$(tput setaf 13)
BLUE=$(tput setaf 12)

# move to script directory so all relative paths work
cd "$(dirname "$0")"

error() {
  echo $1
}

show_message() {
  printf "$1\n\n"
}

delete_directory() {
  if [ -d $1 ]; then
    rm $1 -rfv
  fi
}

check_distro() {
  IS_ARCH=`cat /etc/*-release | grep Arch\ Linux`
  IS_DEBIAN=`cat /etc/*-release | grep Debian`
  IS_UBUNTU=`cat /etc/*-release | grep Ubuntu`
  IS_MINT=`cat /etc/*-release | grep Mint`

  if [[ $IS_ARCH == "" && $IS_DEBIAN == "" && $IS_UBUNTU == "" && $IS_MINT == "" ]]; then
    error "Warning!"
    error "Please, only run this script on ArchLinux, Debian, Mint or Ubuntu"
    exit 1;
  fi
}

clean_up() {
  echo "Cleaning up"
  rm -v ./installer.sh
}

install_process() {
  echo "Installing dein plugin manager"
  curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
  sh ./installer.sh ~/.cache/dein

  echo "Copying .vim files"
  cp -rTv ./.config/nvim ~/.config/nvim
}

delete_previous_setup() {
  echo "Deleting previous install"
  delete_directory ~/.config/nvim
  delete_directory ~/.cache/dein
}

# Delete existant installation.
delete_previous_setup

# Install!
install_process

# Clean Up
clean_up

source ./install/draw.sh


show_message ""
show_message "${MAGENTA}Now all you have to do is run nvim."
show_message "Once inside the text editor type the following in the NORMAL mode: "
show_message "${P}:call dein#install()${MAGENTA}"
show_message "Wait until every script is installed...${BLUE}"
show_message "Enjoy!!!"
