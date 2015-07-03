#!/bin/bash

#
ORIGINALDIR=$( pwd )
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BACKUPDIR="$SCRIPTDIR/backup"
MONO64DIR="$HOME/.monobrew"

DOTFILES=".bashrc .git-prompt.sh .gitignore_global .tmux.conf .vimrc .ycm_extra_conf.py"
BREWTOOLS="git cmake bash-completion cloc doxygen octave python python3 tmux the_silver_searcher vim"

#
cd "$SCRIPTDIR"

# Update and relaunch script
if [ $# = 0 ]; then
  clear
  echo "Dot files & configuration installer"
  echo "==================================="
  echo ""

  echo "Updating dot files and this script..."
  git pull > /dev/null

  echo "Relaunching the script..."
  ./install.sh standard

  cd "$ORIGINALDIR"
  exit
elif [ $# -gt 1 ]; then
  >&2 echo "Unexpected number of arguments."
  exit 1
elif [ $1 != "standard" ]; then
  >&2 echo "Unexpected argument."
  exit 1
fi

# Installing brew
echo ""
echo "Checking Homebrew..."
which -s brew
if [[ $? != 0 ]]; then
  echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" > /dev/null
else
  echo "Homebrew is already installed, updating it..."
  brew update > /dev/null
fi

# Installing tools
echo ""
echo "Installing tools \"$BREWTOOLS\"..."

brew install $BREWTOOLS

#Installing fonts
echo ""
echo "Installing powerline fonts..."

if [ -d "fonts-master" ]; then
  rm -rf fonts-master
fi
curl -s -L https://github.com/powerline/fonts/archive/master.zip | \
  tar -xf- -C . && \
  ./fonts-master/install.sh > /dev/null && \
  rm -rf fonts-master

# Linking dot files
echo ""
echo "Linking dot files, existing files will be backed up to $BACKUPDIR..."

rm -rf "$BACKUPDIR"
mkdir -p "$BACKUPDIR"

for DOTFILE in $DOTFILES; do
  SRCDOTFILE="$SCRIPTDIR/$DOTFILE"
  DSTDOTFILE="$HOME/$DOTFILE"
  if [ -f "$HOME/$DOTFILE" ]; then
    CURDSTFILE=$( readlink "$DSTDOTFILE" )
    if [ "$CURDSTFILE" = "$SRCDOTFILE" ]; then
      echo "$DOTFILE is already linked."
      continue
    else
      echo "Backing up $DOTFILE..."
      cp "$HOME/$DOTFILE" "$BACKUPDIR"
      rm -f "$HOME/$DOTFILE"
    fi
  fi
  echo "Linking $DOTFILE..."
  ln -s "$SCRIPTDIR/$DOTFILE" "$HOME"
done

echo ""
echo "Please include the following lines to $HOME/.gitconfig:"
echo "[include]"
echo "  path = ~/profiles/.gitconfig"

# Link .vim directory
LINKVIM=false
SRCVIM="$SCRIPTDIR/.vim"
DSTVIM="$HOME/.vim"
echo ""
echo "Checking .vim directory..."
if [ -d "$DSTVIM" ]; then
  EXISTINGVIM=$( readlink "$DSTVIM" )
  if [ "$EXISTINGVIM" = "$SRCVIM" ]; then
    echo ".vim is already linked."
  else
    echo -n ".vim directory already exists, do you want to replace it? (y/n)"
    read -n 1 OVERWRITEVIM
    if [ "$OVERWRITEVIM" = "y" ]; then
      LINKVIM=true
      echo "Backing up .vim directory to $BACKUPDIR..."
      cp -r "$EXISTINGVIM" "$BACKUPDIR"
      rm -rf "$DSTVIM"
    fi
  fi
else
  LINKVIM=true
fi

if $LINKVIM; then
  echo "Linking .vim directory..."
  ln -s "$SRCVIM" "$DSTVIM"
fi

# Installing vundle
echo ""
if [ ! -d "$HOME/.vim/bundle" ]; then
  echo "Installing Vundle..."
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
else
  echo "Vundle is already installed."
fi

YCMEXISTED=false
if [ -d "$HOME/.vim/bundle/YouCompleteMe" ]; then
  YCMEXISTED=true
fi

# Updating vim plugings
echo ""
echo "Installing and updating ViM plugins..."
vim +PluginUpdate +PluginInstall +PluginClean +qall

# Compiling YouCompleteMe
if $YCMEXISTED; then
  echo "YouCompleteMe already exists, not compiling it."
else
  echo "Compiling YouCompleteMe..."
  "$HOME/.vim/bundle/YouCompleteMe/install.sh" --clang-completer --omnisharp-completer > /dev/null
fi

# Installing separate mono64
echo ""
echo "Checking Mono 64-bit..."
MONO64BREW="$MONO64DIR/bin/brew"
if [ -d "$MONO64DIR" ]; then
  echo "Mono 64-bit is already set up, checking for (and installing) updates..."
  "$MONO64BREW" update > /dev/null && "$MONO64BREW" upgrade
else
  echo "Installing separate Homebrew and Mono..."
  mkdir -p "$MONO64DIR" && \
    curl -s -L https://github.com/Homebrew/homebrew/tarball/master | \
    tar xz --strip 1 -C "$MONO64DIR" && \
    brew update && \
    install mono
fi

#
cd "$ORIGINALDIR"

echo ""
echo "Done."
