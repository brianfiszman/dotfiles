#!/bin/sh

# move to script directory so all relative paths work
cd "$(dirname "$0")"

error() {
  echo $1
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

# Checks for compatibility
check_distro

# Delete existant installation.
delete_previous_setup

# Install!
install_process

# Clean Up
clean_up

echo "                               .:xxxxxxxx:. "
echo "                            .xxxxxxxxxxxxxxxx." 
echo "                           :xxxxxxxxxxxxxxxxxxx:." 
echo "                          .xxxxxxxxxxxxxxxxxxxxxxx:" 
echo "                         :xxxxxxxxxxxxxxxxxxxxxxxxx: "
echo "                         xxxxxxxxxxxxxxxxxxxxxxxxxxX: "
echo "                         xxx:::xxxxxxxx::::xxxxxxxxx: "
echo "                        .xx:   ::xxxxx:     :xxxxxxxx "
echo "                        :xx  x.  xxxx:  xx.  xxxxxxxx "
echo "                        :xx xxx  xxxx: xxxx  :xxxxxxx "
echo "                        'xx 'xx  xxxx:. xx'  xxxxxxxx "
echo "                         xx ::::::xx:::::.   xxxxxxxx "
echo "                         xx:::::.::::.:::::::xxxxxxxx "
echo "                         :x'::::'::::':::::':xxxxxxxxx. "
echo "                         :xx.::::::::::::'   xxxxxxxxxx "
echo "                         :xx: '::::::::'     :xxxxxxxxxx. "
echo "                        .xx     '::::'        'xxxxxxxxxx. "
echo "                      .xxxx                     'xxxxxxxxx. "
echo "                    .xxxx                         'xxxxxxxxx. "
echo "                  .xxxxx:                          xxxxxxxxxx. "
echo "                 .xxxxx:'                          xxxxxxxxxxx. "
echo "                .xxxxxx:::.           .       ..:::_xxxxxxxxxxx:. "
echo "               .xxxxxxx''      ':::''            ''::xxxxxxxxxxxx. "
echo "               xxxxxx            :                  '::xxxxxxxxxxxx "
echo "              :xxxx:'            :                    'xxxxxxxxxxxx: "
echo "             .xxxxx              :                     ::xxxxxxxxxxxx "
echo "             xxxx:'                                    ::xxxxxxxxxxxx "
echo "             xxxx               .                      ::xxxxxxxxxxxx. "
echo "         .:xxxxxx               :                      ::xxxxxxxxxxxx:: "
echo "         xxxxxxxx               :                      ::xxxxxxxxxxxxx: "
echo "         xxxxxxxx               :                      ::xxxxxxxxxxxxx: "
echo "         ':xxxxxx               '                      ::xxxxxxxxxxxx:' "
echo "           .:. xx:.                                   .:xxxxxxxxxxxxx' "
echo "         ::::::.'xx:.            :                  .:: xxxxxxxxxxx': "
echo " .:::::::::::::::.'xxxx.                            ::::'xxxxxxxx':::. "
echo " ::::::::::::::::::.'xxxxx                          :::::.'.xx.'::::::. "
echo " ::::::::::::::::::::.'xxxx:.                       :::::::.'':::::::::   "
echo " ':::::::::::::::::::::.'xx:'                     .'::::::::::::::::::::.. "
echo "   :::::::::::::::::::::.'xx                    .:: ::::::::::::::::::::::: "
echo " .:::::::::::::::::::::::. xx               .::xxxx ::::::::::::::::::::::: "
echo " :::::::::::::::::::::::::.'xxx..        .::xxxxxxx ::::::::::::::::::::' "
echo " '::::::::::::::::::::::::: xxxxxxxxxxxxxxxxxxxxxxx :::::::::::::::::' "
echo "   '::::::::::::::::::::::: xxxxxxxxxxxxxxxxxxxxxxx :::::::::::::::' "
echo "       ':::::::::::::::::::_xxxxxx::'''::xxxxxxxxxx '::::::::::::' "
echo "            ':::.:::::::::'                          '._::::::_.'  "

echo "Now all you have to do is: "
echo "nvim"

echo "Once inside the text editor: "
echo "call dein#install()"

echo "Wait until every script is installed..."
echo "Enjoy!!!"

