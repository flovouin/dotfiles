#!/bin/bash

#
ORIGINALDIR=$( pwd )
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DAEMONDIR="/Library/LaunchDaemons"
BACKUPDIR="$SCRIPTDIR/backup"
MONO64DIR="$HOME/.monobrew"

DOTFILES=".bashrc .git-prompt.sh .gitignore_global .tmux.conf .vimrc .ycm_extra_conf.py"
BREWTOOLS="git cmake bash-completion cloc doxygen octave python python3 tmux the_silver_searcher vim"
DAEMONFILES="limit.maxfiles.plist limit.maxproc.plist"

COLOUR_YELLOW="\033[1;33m"
COLOUR_RED="\033[0;31m"
COLOUR_GREEN="\033[0;32m"
COLOUR_BLUE="\033[0;35m"
NO_COLOUR="\033[0m"

#
cd "$SCRIPTDIR"

# Update and relaunch script
if [ $# = 0 ]; then
  clear
  echo -e "Dot files & configuration installer"
  echo -e "==================================="
  echo -e ""

  echo -e $COLOUR_BLUE"Updating dot files and this script..."$NO_COLOUR
  git pull > /dev/null

  echo -e "Relaunching the script..."
  ./install.sh standard

  DAEMONFILESEXIST=true
  for DAEMONFILE in $DAEMONFILES; do
    DSTFILE="$DAEMONDIR/$DAEMONFILE"
    if [ ! -f "$DSTFILE" ]; then
      DAEMONFILESEXIST=false
      break
    fi
  done

  if ! $DAEMONFILESEXIST; then
    echo -e ""
    echo -e $COLOUR_YELLOW"Run 'sudo \"$SCRIPTDIR/install.sh\" limits' to change OSX default max files limits."$NO_COLOUR
  fi

  cd "$ORIGINALDIR"
  exit
elif [ $# -gt 1 ]; then
  >&2 echo -e $COLOUR_RED"Unexpected number of arguments."$NO_COLOUR
  exit 1
elif [ $1 = "limits" ]; then
  # Updating limits
  echo -e ""
  echo -e $COLOUR_BLUE"Updating limits..."$NO_COLOUR

  for DAEMONFILE in $DAEMONFILES; do
    SRCFILE=$SCRIPTDIR/$DAEMONFILE
    DSTFILE="$DAEMONDIR/$DAEMONFILE"
    if [ -f "$DSTFILE" ]; then
      echo -e $COLOUR_YELLOW"$DAEMONFILE already exists, skipping."$NO_COLOUR
      continue
    fi

    cat "$SRCFILE" > "$DSTFILE"
  done

  exit
elif [ $1 = "standard" ]; then
  :
else
  >&2 echo -e $COLOUR_RED"Unexpected argument."$NO_COLOUR
  exit 1
fi

# Installing brew
echo -e ""
echo -e $COLOUR_BLUE"Checking Homebrew..."$NO_COLOUR
if ! $( which -s brew ); then
  echo -e "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" > /dev/null
fi

echo -e "Updating Homebrew..."
if ! $( brew tap | grep -xq homebrew/science ); then
  echo -e "Adding science tap to Homebrew..."
  brew tap homebrew/science > /dev/null
fi
brew update > /dev/null

# Installing tools
echo -e ""
echo -e $COLOUR_BLUE"Installing tools \"$BREWTOOLS\"..."$NO_COLOUR

brew install $BREWTOOLS

#Installing fonts
echo -e ""
echo -e $COLOUR_BLUE"Installing powerline fonts..."$NO_COLOUR

if [ -d "fonts-master" ]; then
  rm -rf fonts-master
fi
curl -s -L https://github.com/powerline/fonts/archive/master.zip | \
  tar -xf- -C . && \
  ./fonts-master/install.sh > /dev/null && \
  rm -rf fonts-master

# Linking dot files
echo -e ""
echo -e $COLOUR_BLUE"Checking dot files."$NO_COLOUR
echo -e "Existing files will be backed up to $BACKUPDIR..."

rm -rf "$BACKUPDIR"
mkdir -p "$BACKUPDIR"

for DOTFILE in $DOTFILES; do
  SRCDOTFILE="$SCRIPTDIR/$DOTFILE"
  DSTDOTFILE="$HOME/$DOTFILE"
  if [ -f "$HOME/$DOTFILE" ]; then
    CURDSTFILE=$( readlink "$DSTDOTFILE" )
    if [ "$CURDSTFILE" = "$SRCDOTFILE" ]; then
      echo -e $COLOUR_GREEN"$DOTFILE is already linked."$NO_COLOUR
      continue
    else
      echo -e $COLOUR_YELLOW"Backing up $DOTFILE..."$NO_COLOUR
      cp "$HOME/$DOTFILE" "$BACKUPDIR"
      rm -f "$HOME/$DOTFILE"
    fi
  fi
  echo -e "Linking $DOTFILE..."
  ln -s "$SCRIPTDIR/$DOTFILE" "$HOME"
done

GITCONFIGFILE=$HOME/.gitconfig
if ! $( grep -q "path = ~/profiles/.gitconfig" $GITCONFIGFILE ); then
  echo -e ""
  echo -e $COLOUR_YELLOW"Please include the following lines to $GITCONFIGFILE:"$NO_COLOUR
  echo -e "[include]"
  echo -e "  path = $SCRIPTDIR/.gitconfig"
fi

# Link .vim directory
LINKVIM=false
SRCVIM="$SCRIPTDIR/.vim"
DSTVIM="$HOME/.vim"
echo -e ""
echo -e $COLOUR_BLUE"Checking .vim directory..."$NO_COLOUR
if [ -d "$DSTVIM" ]; then
  EXISTINGVIM=$( readlink "$DSTVIM" )
  if [ "$EXISTINGVIM" = "$SRCVIM" ]; then
    echo -e $COLOUR_GREEN".vim is already linked."$NO_COLOUR
  else
    echo -e -n $COLOUR_YELLOW".vim directory already exists, do you want to replace it? (y/n)"$NO_COLOUR
    read -n 1 OVERWRITEVIM
    if [ "$OVERWRITEVIM" = "y" ]; then
      LINKVIM=true
      echo -e $COLOUR_YELLOW"Backing up .vim directory to $BACKUPDIR..."$NO_COLOUR
      cp -r "$EXISTINGVIM" "$BACKUPDIR"
      rm -rf "$DSTVIM"
    fi
  fi
else
  LINKVIM=true
fi

if $LINKVIM; then
  echo -e "Linking .vim directory..."
  ln -s "$SRCVIM" "$DSTVIM"
fi

# Installing vundle
echo -e ""
echo -e $COLOUR_BLUE"Checking Vundle..."$NO_COLOUR
if [ ! -d "$HOME/.vim/bundle" ]; then
  echo -e "Installing Vundle..."
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
else
  echo -e $COLOUR_GREEN"Vundle is already installed."$NO_COLOUR
fi

YCMEXISTED=false
if [ -d "$HOME/.vim/bundle/YouCompleteMe" ]; then
  YCMEXISTED=true
fi

# Updating vim plugings
echo -e ""
echo -e $COLOUR_BLUE"Installing and updating ViM plugins..."$NO_COLOUR
vim +PluginUpdate +PluginInstall +PluginClean +qall

# Compiling YouCompleteMe
if $YCMEXISTED; then
  echo -e $COLOUR_GREEN"YouCompleteMe already exists, not compiling it."$NO_COLOUR
else
  echo -e "Compiling YouCompleteMe..."
  "$HOME/.vim/bundle/YouCompleteMe/install.sh" --clang-completer --omnisharp-completer > /dev/null
fi

# Installing separate mono64
echo -e ""
echo -e $COLOUR_BLUE"Checking Mono 64-bit..."$NO_COLOUR
MONO64BREW="$MONO64DIR/bin/brew"
if [ -d "$MONO64DIR" ]; then
  echo -e $COLOUR_GREEN"Mono 64-bit is already set up."$NO_COLOUR
  echo -e "Checking for (and installing) updates..."
  "$MONO64BREW" update > /dev/null && "$MONO64BREW" upgrade
else
  echo -e "Installing separate Homebrew and Mono..."
  mkdir -p "$MONO64DIR" && \
    curl -s -L https://github.com/Homebrew/homebrew/tarball/master | \
    tar xz --strip 1 -C "$MONO64DIR" && \
    brew update && \
    install mono
fi

#
cd "$ORIGINALDIR"

echo -e ""
echo -e "Done."
