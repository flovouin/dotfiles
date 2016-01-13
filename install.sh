#!/bin/bash

# Installation script for coding environment.
# Flo Vouin

#
ORIGINALDIR=$( pwd )
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DAEMONDIR="/Library/LaunchDaemons"
BACKUPDIR="$SCRIPTDIR/backup"
MONO64DIR="$HOME/.monobrew"
FONTSTEMPDIR="fonts-master"

DOTFILES=".bash_profile .bashrc .git-prompt.sh .gitignore_global .tmux.conf .vimrc .ycm_extra_conf.py"
IPYTHON_CONF_FILE="ipython_config.py"
IPYTHON_CONF_DIR="$HOME/.ipython/profile_default"
JUPYTER_CONF_FILE="jupyter_qtconsole_config.py"
JUPYTER_CONF_DIR="$HOME/.jupyter"

COMMONTOOLS="git cmake bash-completion cloc doxygen octave python python3 tmux vim"
OSXTOOLS="the_silver_searcher"
LINUXTOOLS="silversearcher-ag mono-complete ca-certificates-mono python-dev python3-dev"
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
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" > /dev/null
  fi

  # Adding the science tap
  if ! $( brew tap | grep -xq homebrew/science ); then
    echo -e "Adding science tap to Homebrew..."
    brew tap homebrew/science > /dev/null
  fi

  return 0
}

# Installs useful programs.
install_tools() {
  if [[ $PLATFORM == "OSX" ]]; then
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

    # Up-to-date version of Mono
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /dev/null
    echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list > /dev/null
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

  # Linking config files in weird locations
  # IPython
  mkdir -p "$IPYTHON_CONF_DIR"
  SRCIPYTHONFILE="$SCRIPTDIR/$IPYTHON_CONF_FILE"
  DSTIPYTHONFILE="$IPYTHON_CONF_DIR/$IPYTHON_CONF_FILE"

  if [[ -f "$DSTIPYTHONFILE" ]]; then
    CURDSTFILE=$( readlink "$DSTIPYTHONFILE" )
    if [[ $CURDSTFILE == $SRCIPYTHONFILE ]]; then
      echo -e $COLOUR_GREEN"$IPYTHON_CONF_FILE is already linked."$NO_COLOUR
      continue
    else
      echo -e $COLOUR_YELLOW"Backing up $IPYTHON_CONF_FILE..."$NO_COLOUR
      cp "$DSTIPYTHONFILE" "$BACKUPDIR"
      rm -f "$DSTIPYTHONFILE"
    fi
  fi
  echo -e "Linking $IPYTHON_CONF_FILE..."
  ln -s "$SRCIPYTHONFILE" "$IPYTHON_CONF_DIR"

  # Jupyter
  mkdir -p "$JUPYTER_CONF_DIR"
  SRCJUPYTERFILE="$SCRIPTDIR/$JUPYTER_CONF_FILE"
  DSTJUPYTERFILE="$JUPYTER_CONF_DIR/$JUPYTER_CONF_FILE"

  if [[ -f "$DSTJUPYTERFILE" ]]; then
    CURDSTFILE=$( readlink "$DSTJUPYTERFILE" )
    if [[ $CURDSTFILE == $SRCJUPYTERFILE ]]; then
      echo -e $COLOUR_GREEN"$JUPYTER_CONF_FILE is already linked."$NO_COLOUR
      continue
    else
      echo -e $COLOUR_YELLOW"Backing up $JUPYTER_CONF_FILE..."$NO_COLOUR
      cp "$DSTJUPYTERFILE" "$BACKUPDIR"
      rm -f "$DSTJUPYTERFILE"
    fi
  fi
  echo -e "Linking $JUPYTER_CONF_FILE..."
  ln -s "$SRCJUPYTERFILE" "$JUPYTER_CONF_DIR"

  # Sourcing the gitconfig
  source_gitconfig

  # Link .vim directory
  LINKVIM=false
  SRCVIM="$SCRIPTDIR/.vim"
  DSTVIM="$HOME/.vim"
  echo -e ""
  echo -e $COLOUR_BLUE"Checking .vim directory..."$NO_COLOUR
  if [[ -d $DSTVIM ]]; then
    EXISTINGVIM=$( readlink "$DSTVIM" )
    if [[ $EXISTINGVIM == $SRCVIM ]]; then
      echo -e $COLOUR_GREEN".vim is already linked."$NO_COLOUR
    else
      echo -e -n $COLOUR_YELLOW".vim directory already exists, do you want to replace it? (y/n) "$NO_COLOUR
      read -n 1 OVERWRITEVIM
      echo -e ""
      if [[ $OVERWRITEVIM == "y" ]]; then
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

  YCMDIR="$HOME/.vim/bundle/YouCompleteMe"
  YCMEXISTED=false
  if [[ -d $YCMDIR ]]; then
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

  # Compiling OmniSharp
  echo -e "Compiling OmniSharp server..."
  OMNISHARPDIR="$BUNDLEDIR/omnisharp-vim/server/"
  cd "$OMNISHARPDIR" && xbuild > /dev/null
  cd "$SCRIPTDIR"
}

# Installing separate mono64
install_mono64() {
  echo -e ""
  echo -e $COLOUR_BLUE"Checking Mono 64-bit..."$NO_COLOUR
  MONO64BREW="$MONO64DIR/bin/brew"
  if [[ -d $MONO64DIR ]]; then
    echo -e $COLOUR_GREEN"Mono 64-bit is already set up."$NO_COLOUR
  else
    echo -e "Installing separate Homebrew for Mono..."
    mkdir -p "$MONO64DIR" && \
      curl -s -L https://github.com/Homebrew/homebrew/tarball/master | \
      tar xz --strip 1 -C "$MONO64DIR"
  fi
  echo -e "Checking for (and installing) updates..."
  "$MONO64BREW" update > /dev/null
  "$MONO64BREW" upgrade mono > /dev/null
  "$MONO64BREW" install mono > /dev/null
  "$MONO64BREW" cleanup > /dev/null
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
  git pull > /dev/null

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
        install_mono64
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
