#!/bin/bash

# Installation script for coding environment.
# Flo Vouin

#
ORIGINALDIR=$( pwd )
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DAEMONDIR="/Library/LaunchDaemons"
BACKUPDIR="$SCRIPTDIR/backup"
FONTSTEMPDIR="fonts-master"

DOTFILES=".bash_profile .bashrc .git-prompt.sh .gitignore_global .tmux.conf .vimrc"

COMMONTOOLS="git cmake bash-completion python python3 tmux vim nodenv"
OSXTOOLS="the_silver_searcher"
LINUXTOOLS="silversearcher-ag python-dev python3-dev python3-pip"
DAEMONFILES="limit.maxfiles.plist limit.maxproc.plist"

COLOUR_YELLOW="\033[1;33m"
COLOUR_RED="\033[0;31m"
COLOUR_GREEN="\033[0;32m"
COLOUR_BLUE="\033[0;35m"
NO_COLOUR="\033[0m"

#
if $( python -mplatform | grep -q Darwin ); then
  PLATFORM="OSX"
  PKGCMD="brew"
  PKGUPDATE="$PKGCMD update"
  PKGINSTALL="$PKGCMD install"
  PKGUPGRADE="$PKGCMD upgrade"
  PKGCLEAN="$PKGCMD cleanup"
elif $( python -mplatform | grep -q Ubuntu ); then
  PLATFORM="Linux"
  PKGCMD="apt-get"
  PKGUPDATE="$PKGCMD update -qy"
  PKGINSTALL="$PKGCMD install -qy"
  PKGUPGRADE="$PKGCMD upgrade -qy"
  PKGCLEAN="$PKGCMD clean -q"
else
  >&2 echo $COLOUR_RED"Could not determine the platform."$NO_COLOUR
  exit 1
fi

# Tests if OSX limit files exist. If not, displays a message.
test_osx_limit_files() {
  if [[ $PLATFORM != "OSX" ]]; then
    >&2 echo $COLOUR_RED"Limits files are only defined on OSX."$NO_COLOUR
    return 1
  fi

  DAEMONFILESEXIST=true
  for DAEMONFILE in $DAEMONFILES; do
    DSTFILE="$DAEMONDIR/$DAEMONFILE"
    if [[ ! -f $DSTFILE ]]; then
      DAEMONFILESEXIST=false
      break
    fi
  done

  if ! $DAEMONFILESEXIST; then
    echo -e ""
    echo -e $COLOUR_YELLOW"Run 'sudo \"$SCRIPTDIR/install.sh\" limits' to change OSX default max files limits."$NO_COLOUR
  fi

  return 0
}

# Copies limit files.
apply_osx_limit_files() {
  if [[ $PLATFORM != "OSX" ]]; then
    >&2 echo $COLOUR_RED"Limits files are only defined on OSX."$NO_COLOUR
    return 1
  fi

  for DAEMONFILE in $DAEMONFILES; do
    SRCFILE=$SCRIPTDIR/$DAEMONFILE
    DSTFILE="$DAEMONDIR/$DAEMONFILE"
    if [[ -f "$DSTFILE" ]]; then
      echo -e $COLOUR_YELLOW"$DAEMONFILE already exists, skipping."$NO_COLOUR
      continue
    fi

    cat "$SRCFILE" > "$DSTFILE"
  done

  return 0
}

# Installs Hombrew on OSX.
install_brew() {
  if [[ $PLATFORM != "OSX" ]]; then
    >&2 echo $COLOUR_RED"Limits files are only defined on OSX."$NO_COLOUR
    return 1
  fi

  # Installing brew
  echo -e ""
  echo -e $COLOUR_BLUE"Checking Homebrew..."$NO_COLOUR
  if ! $( which -s brew ); then
    echo -e "Installing Homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  return 0
}

# Installs useful programs.
install_tools() {
  if [[ $PLATFORM == "OSX" ]]; then
    if ! xcode-select -p > /dev/null; then
      >&2 echo -e $COLOUR_RED"Please install the Xcode Command Line Tools first using"$NO_COLOUR
      >&2 echo -e $COLOUR_YELLOW"xcode-select --install"$NO_COLOUR
      exit 1
    fi

    install_brew
  fi

  # Common to all systems
  echo -e ""
  echo -e $COLOUR_BLUE"Installing tools..."$NO_COLOUR

  echo -e "Updating package manager..."
  $PKGUPDATE > /dev/null

  echo -e ""
  echo -e $COLOUR_BLUE"Installing tools \"$COMMONTOOLS\"..."$NO_COLOUR

  $PKGUPGRADE $COMMONTOOLS > /dev/null
  $PKGINSTALL $COMMONTOOLS > /dev/null

  # Platform-dependent tools
  if [[ $PLATFORM == "Linux" ]]; then
    echo -e ""
    echo -e $COLOUR_BLUE"Installing Linux-specific tools \"$LINUXTOOLS\"..."$NO_COLOUR

    $PKGUPDATE > /dev/null

    $PKGUPGRADE $LINUXTOOLS > /dev/null
    $PKGINSTALL $LINUXTOOLS > /dev/null
  elif [[ $PLATFORM == "OSX" ]]; then
    echo -e ""
    echo -e $COLOUR_BLUE"Installing OSX-specific tools \"$OSXTOOLS\"..."$NO_COLOUR
    $PKGUPGRADE $OSXTOOLS > /dev/null
    $PKGINSTALL $OSXTOOLS > /dev/null
  fi

  $PKGCLEAN > /dev/null
}

# Installs fonts.
install_fonts() {
  echo -e ""
  echo -e $COLOUR_BLUE"Installing powerline fonts..."$NO_COLOUR

  if [[ -d $FONTSTEMPDIR ]]; then
    rm -rf "$FONTSTEMPDIR"
  fi

  curl -s -L https://github.com/powerline/fonts/archive/master.zip | \
    tar -xf- -C . && \
    ./fonts-master/install.sh > /dev/null && \
    rm -rf "$FONTSTEMPDIR"
}

source_gitconfig() {
  GITCONFIGFILE=$HOME/.gitconfig
  LOCALCONFIG="$SCRIPTDIR/.gitconfig"
  if ! $( grep -q "path = $LOCALCONFIG" $GITCONFIGFILE ); then
    echo -e ""
    echo -e $COLOUR_RED"$GITCONFIGFILE does not source $LOCALCONFIG. The following lines should be added to $GITCONFIGFILE:"
    echo -e $COLOUR_YELLOW"[include]"
    echo -e "  path = $SCRIPTDIR/.gitconfig"$NO_COLOUR
    echo -e ""

    echo -e -n "Do you want to add them now? (y/n) "
    read -n 1 SOURCEGITCONFIG
    echo -e ""
    if [ "$SOURCEGITCONFIG" = "y" ]; then
      echo "[include]" >> $GITCONFIGFILE
      echo "  path = $SCRIPTDIR/.gitconfig" >> $GITCONFIGFILE
    fi
  fi
}

link_directory() {
  SRCDIR=$1
  DSTDIR=$2

  LINKDIR=false
  echo -e ""
  echo -e $COLOUR_BLUE"Checking $SRCDIR directory..."$NO_COLOUR
  if [[ -d $DSTDIR ]]; then
    EXISTINGDIR=$( readlink "$DSTDIR" )
    if [[ $EXISTINGDIR == $SRCDIR ]]; then
      echo -e $COLOUR_GREEN"$SRCDIR is already linked."$NO_COLOUR
    else
      echo -e -n $COLOUR_YELLOW"$SRCDIR directory already exists, do you want to replace it? (y/n) "$NO_COLOUR
      read -n 1 OVERWRITEDIR
      echo -e ""
      if [[ $OVERWRITEDIR == "y" ]]; then
        LINKDIR=true
        echo -e $COLOUR_YELLOW"Backing up $EXISTINGDIR directory to $BACKUPDIR..."$NO_COLOUR
        cp -r "$EXISTINGDIR" "$BACKUPDIR"
        rm -rf "$DSTDIR"
      fi
    fi
  else
    LINKDIR=true
  fi

  if $LINKDIR; then
    echo -e "Linking $SRCDIR directory..."
    ln -s "$SRCDIR" "$DSTDIR"
  fi
}

# Linking dot files
link_dot_files() {
  echo -e ""
  echo -e $COLOUR_BLUE"Checking dot files."$NO_COLOUR
  echo -e "Existing files will be backed up to $BACKUPDIR..."

  rm -rf "$BACKUPDIR"
  mkdir -p "$BACKUPDIR"

  for DOTFILE in $DOTFILES; do
    SRCDOTFILE="$SCRIPTDIR/$DOTFILE"
    DSTDOTFILE="$HOME/$DOTFILE"
    if [[ -f "$DSTDOTFILE" ]]; then
      CURDSTFILE=$( readlink "$DSTDOTFILE" )
      if [[ $CURDSTFILE == $SRCDOTFILE ]]; then
        echo -e $COLOUR_GREEN"$DOTFILE is already linked."$NO_COLOUR
        continue
      else
        echo -e $COLOUR_YELLOW"Backing up $DOTFILE..."$NO_COLOUR
        cp "$DSTDOTFILE" "$BACKUPDIR"
        rm -f "$DSTDOTFILE"
      fi
    fi
    echo -e "Linking $DOTFILE..."
    ln -s "$SRCDOTFILE" "$HOME"
  done

  # Sourcing the gitconfig
  source_gitconfig

  # Link .vim directory
  SRCVIM="$SCRIPTDIR/.vim"
  DSTVIM="$HOME/.vim"
  link_directory $SRCVIM $DSTVIM
}

# Installing ViM
install_vim() {
  echo -e ""
  echo -e $COLOUR_BLUE"Checking Vundle..."$NO_COLOUR

  BUNDLEDIR="$HOME/.vim/bundle"
  VUNDLEDIR="$BUNDLEDIR/Vundle.vim"
  if [[ ! -d $VUNDLEDIR ]]; then
    echo -e "Installing Vundle..."
    git clone https://github.com/gmarik/Vundle.vim.git $VUNDLEDIR > /dev/null
  else
    echo -e $COLOUR_GREEN"Vundle is already installed."$NO_COLOUR
  fi

  # Updating vim plugings
  echo -e ""
  echo -e $COLOUR_BLUE"Installing and updating ViM plugins..."$NO_COLOUR
  vim +PluginUpdate +PluginInstall +PluginClean +qall
}

#

cd "$SCRIPTDIR"

if [[ $# -eq 0 ]]; then
  # Update and relaunch script
  clear
  echo -e "Dot files & configuration installer"
  echo -e "==================================="
  echo -e ""

  echo -e $COLOUR_BLUE"Updating dot files and this script..."$NO_COLOUR
  git pull origin master > /dev/null

  echo -e "Relaunching the script..."
  ./install.sh all

  if [[ $PLATFORM == "OSX" ]]; then
    test_osx_limit_files
  fi

  echo -e ""
  echo -e "Done."
elif [ $# -gt 1 ]; then
  >&2 echo -e $COLOUR_RED"Unexpected number of arguments."$NO_COLOUR
else
  case "$1" in
    limits)
      if [[ $PLATFORM != "OSX" ]]; then
        >&2 echo -e $COLOUR_RED"The limits option is only available on OSX."$NO_COLOUR
        exit 1
      fi

      # Updating limits
      echo -e ""
      echo -e $COLOUR_BLUE"Updating limits..."$NO_COLOUR
      apply_osx_limit_files

      exit $?
      ;;
    all)
      if [[ $PLATFORM == "OSX" ]]; then
        ./install.sh tools
        ./install.sh config
      else
        >&2 echo -e $COLOUR_RED"Install all is not possible on Linux because the package manager requires root access, please run these commands separately:"$NO_COLOUR
        >&2 echo -e "sudo ./install.sh tools"
        >&2 echo -e "./install.sh config"
      fi
      ;;
    tools)
      install_tools
      ;;
    config)
      install_fonts
      link_dot_files
      install_vim
      ;;
    *)
      >&2 echo -e $COLOUR_RED"Unexpected argument."$NO_COLOUR
      exit 1
      ;;
  esac
fi

cd "$ORIGINALDIR"
