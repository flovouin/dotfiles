Flo's personal dot files
------------------------

This repository contains all the dot files I use for:
  - vim
  - bash
  - git
  - tmux
  - IPython / Jupyter

It also contains a script `install.sh` that takes care of setting
up the dot files, and backing up already existing ones before replacing
them. This scripts works for both OSX and Ubuntu. On OSX, it installs
Homebrew and uses it to install the tools I commonly use. On Ubuntu
it does the same thing, but using `apt-get`. It also installs Powerline
fonts to make the best out of some vim plugins (airline). Finally,
on OSX, it allows you (by running `sudo ./install.sh limits`) to
change OSX default max files.
