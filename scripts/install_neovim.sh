#!/bin/bash
#
# Copyright (C) 2023 Ronald Record <ronaldrecord@gmail.com>
# Copyright (C) 2022 Michael Peter <michaeljohannpeter@gmail.com>
#
# Install Neovim and all dependencies for the Neovim config at:
#     https://github.com/doctorfree/nvim-lazyman
#
# shellcheck disable=SC2001,SC2016,SC2006,SC2086,SC2181,SC2129,SC2059

DOC_HOMEBREW="https://docs.brew.sh"
BREW_EXE="brew"

abort () {
  printf "\nERROR: %s\n" "$@" >&2
  exit 1
}

log () {
  [ "${quiet}" ] || {
    printf "\n\t%s" "$@"
  }
}

check_prerequisites () {
  if [ -z "${BASH_VERSION:-}" ]; then
    abort "Bash is required to interpret this script."
  fi

  if [[ $EUID -eq 0 ]]; then
    abort "Script must not be run as root user"
  fi

  arch=$(uname -m)
  if [[ $arch =~ "arm" || $arch =~ "aarch64" ]]; then
    abort "Only amd64/x86_64 is supported"
  fi
}

install_brew () {
  if ! command -v brew >/dev/null 2>&1; then
    [ "${debug}" ] && START_SECONDS=$(date +%s)
    log "Installing Homebrew ..."
    BREW_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    have_curl=$(type -p curl)
    [ "${have_curl}" ] || abort "The curl command could not be located."
    curl -fsSL "${BREW_URL}" > /tmp/brew-$$.sh
    [ $? -eq 0 ] || {
      rm -f /tmp/brew-$$.sh
      curl -kfsSL "${BREW_URL}" > /tmp/brew-$$.sh
    }
    [ -f /tmp/brew-$$.sh ] || abort "Brew install script download failed"
    chmod 755 /tmp/brew-$$.sh
    NONINTERACTIVE=1 /bin/bash -c "/tmp/brew-$$.sh" > /dev/null 2>&1
    rm -f /tmp/brew-$$.sh
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ENV_HINTS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    [ "${quiet}" ] || printf " done"
    if [ -f ${HOME}/.profile ]
    then
      BASHINIT="${HOME}/.profile"
    else
      if [ -f ${HOME}/.bashrc ]
      then
        BASHINIT="${HOME}/.bashrc"
      else
        BASHINIT="${HOME}/.profile"
      fi
    fi
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]
    then
      HOMEBREW_HOME="/home/linuxbrew/.linuxbrew"
      BREW_EXE="${HOMEBREW_HOME}/bin/brew"
    else
      if [ -x /usr/local/bin/brew ]
      then
        HOMEBREW_HOME="/usr/local"
        BREW_EXE="${HOMEBREW_HOME}/bin/brew"
      else
        if [ -x /opt/homebrew/bin/brew ]
        then
          HOMEBREW_HOME="/opt/homebrew"
          BREW_EXE="${HOMEBREW_HOME}/bin/brew"
        else
          abort "Homebrew brew executable could not be located"
        fi
      fi
    fi

    if [ -f "${BASHINIT}" ]
    then
      grep "^eval \"\$(${BREW_EXE} shellenv)\"" "${BASHINIT}" > /dev/null || {
        echo 'if [ -x XXX ]; then' | sed -e "s%XXX%${BREW_EXE}%" >> "${BASHINIT}"
        echo '  eval "$(XXX shellenv)"' | sed -e "s%XXX%${BREW_EXE}%" >> "${BASHINIT}"
        echo 'fi' >> "${BASHINIT}"
      }
      grep "^eval \"\$(zoxide init" "${BASHINIT}" > /dev/null || {
        echo 'if command -v zoxide > /dev/null; then' >> "${BASHINIT}"
        echo '  eval "$(zoxide init bash)"' >> "${BASHINIT}"
        echo 'fi' >> "${BASHINIT}"
      }
    else
      echo 'if [ -x XXX ]; then' | sed -e "s%XXX%${BREW_EXE}%" > "${BASHINIT}"
      echo '  eval "$(XXX shellenv)"' | sed -e "s%XXX%${BREW_EXE}%" >> "${BASHINIT}"
      echo 'fi' >> "${BASHINIT}"
      echo 'if command -v zoxide > /dev/null; then' >> "${BASHINIT}"
      echo '  eval "$(zoxide init bash)"' >> "${BASHINIT}"
      echo 'fi' >> "${BASHINIT}"
    fi
    [ -f "${HOME}/.zshrc" ] && {
      grep "^eval \"\$(${BREW_EXE} shellenv)\"" "${HOME}/.zshrc" > /dev/null || {
        echo 'if [ -x XXX ]; then' | sed -e "s%XXX%${BREW_EXE}%" >> "${HOME}/.zshrc"
        echo '  eval "$(XXX shellenv)"' | sed -e "s%XXX%${BREW_EXE}%" >> "${HOME}/.zshrc"
        echo 'fi' >> "${HOME}/.zshrc"
      }
      grep "^eval \"\$(zoxide init" "${HOME}/.zshrc" > /dev/null || {
        echo 'if command -v zoxide > /dev/null; then' >> "${HOME}/.zshrc"
        echo '  eval "$(zoxide init zsh)"' >> "${HOME}/.zshrc"
        echo 'fi' >> "${HOME}/.zshrc"
      }
    }
    eval "$(${BREW_EXE} shellenv)"
    have_brew=`type -p brew`
    [ "${have_brew}" ] && BREW_EXE="brew"
    [ "${debug}" ] && {
      FINISH_SECONDS=$(date +%s)
      ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
      ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
      printf "\nHomebrew install elapsed time = ${ELAPSED}\n"
    }
  fi
  [ "${HOMEBREW_HOME}" ] || {
    brewpath=$(command -v brew)
    if [ $? -eq 0 ]
    then
      HOMEBREW_HOME=`dirname ${brewpath} | sed -e "s%/bin$%%"`
    else
      HOMEBREW_HOME="Unknown"
    fi
  }
  log "Homebrew installed in ${HOMEBREW_HOME}"
  log "See ${DOC_HOMEBREW}"
}

install_zoxide () {
  log "Installing zoxide ..."
  have_zoxide=$(type -p zoxide)
  [ "${have_zoxide}" ] || {
    [ "${debug}" ] && START_SECONDS=$(date +%s)
    ${BREW_EXE} install --quiet zoxide > /dev/null 2>&1
    [ $? -eq 0 ] || ${BREW_EXE} link --overwrite --quiet ${pkg} > /dev/null 2>&1
    if [ "${debug}" ]
    then
      FINISH_SECONDS=$(date +%s)
      ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
      ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
      printf "\nInstall zoxide elapsed time = %s${ELAPSED}\n"
    fi
  }
  [ "${quiet}" ] || printf " done"
}


install_neovim_dependencies () {
  log "Installing dependencies ..."
  PKGS="git curl tar unzip lazygit fd ripgrep fzf xclip"
  for pkg in ${PKGS}
  do
    have_pkg=$(type -p ${pkg})
    [ "${have_pkg}" ] || {
      [ "${debug}" ] && START_SECONDS=$(date +%s)
      [ "${quiet}" ] || printf " ${pkg}"
      ${BREW_EXE} install --quiet ${pkg} > /dev/null 2>&1
      [ $? -eq 0 ] || ${BREW_EXE} link --overwrite --quiet ${pkg} > /dev/null 2>&1
      [ "${debug}" ] && {
        FINISH_SECONDS=$(date +%s)
        ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
        ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
        printf "\nInstall ${pkg} elapsed time = %s${ELAPSED}\n"
      }
    }
  done
  [ "${quiet}" ] || printf " done"
}

install_neovim () {
  log "Installing Neovim ..."
  if [ "${debug}" ]
  then
    START_SECONDS=$(date +%s)
  fi
  ${BREW_EXE} install -q neovim > /dev/null 2>&1
  if [ "${debug}" ]
  then
    FINISH_SECONDS=$(date +%s)
    ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
    ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
    printf "\nInstall Neovim elapsed time = %s${ELAPSED}\n"
  fi
  [ "${quiet}" ] || printf " done"
}

install_neovim_head () {
  log "Installing Neovim HEAD ..."
  if [ "${debug}" ]
  then
    START_SECONDS=$(date +%s)
  fi
  ${BREW_EXE} install -q --HEAD neovim > /dev/null 2>&1
  if [ "${debug}" ]
  then
    FINISH_SECONDS=$(date +%s)
    ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
    ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
    printf "\nInstall Neovim HEAD elapsed time = %s${ELAPSED}\n"
  fi
  [ "${quiet}" ] || printf " done"
}

check_python () {
  brew_path=$(command -v brew)
  brew_dir=$(dirname ${brew_path})
  if [ -x ${brew_dir}/python3 ]
  then
    PYTHON="${brew_dir}/python3"
  else
    PYTHON=$(command -v python3)
  fi
}

# Brew doesn't create a python symlink so we do so here
link_python () {
  python3_path=$(command -v python3)
  [ "${python3_path}" ] && {
    python_dir=`dirname ${python3_path}`
    if [ -w ${python_dir} ]
    then
      rm -f ${python_dir}/python
      ln -s ${python_dir}/python3 ${python_dir}/python
    else
      sudo rm -f ${python_dir}/python
      sudo ln -s ${python_dir}/python3 ${python_dir}/python
    fi
  }
}

install_language_servers() {
  log "Installing language servers ..."
  have_npm=$(type -p npm)
  [ "${have_npm}" ] && {
    [ "${debug}" ] && START_SECONDS=$(date +%s)
	  for pkg in awk-language-server cssmodules-language-server eslint_d \
							 vim-language-server dockerfile-language-server-nodejs
		do
      [ "${quiet}" ] || printf " ${pkg}"
      npm i -g ${pkg} > /dev/null 2>&1
		done
    [ "${debug}" ] && {
      FINISH_SECONDS=$(date +%s)
      ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
      ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
      printf "\nNpm tools install elapsed time = %s${ELAPSED}\n"
    }
  }
  # brew installed language servers
  for server in pyright typescript vscode-langservers-extracted
  do
    [ "${debug}" ] && START_SECONDS=$(date +%s)
    [ "${quiet}" ] || printf " ${server}"
    ${BREW_EXE} install -q ${server} > /dev/null 2>&1
    if [ "${debug}" ]
    then
      FINISH_SECONDS=$(date +%s)
      ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
      ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
      printf "\nInstall ${server} elapsed time = %s${ELAPSED}\n"
    fi
  done
  for server in ansible bash haskell sql lua typescript yaml
  do
    [ "${debug}" ] && START_SECONDS=$(date +%s)
    [ "${quiet}" ] || printf " ${server}-language-server"
    ${BREW_EXE} install -q ${server}-language-server > /dev/null 2>&1
    if [ "${debug}" ]
    then
      FINISH_SECONDS=$(date +%s)
      ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
      ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
      printf "\nInstall ${server}-language-server elapsed time = %s${ELAPSED}\n"
    fi
  done

  [ "${debug}" ] && START_SECONDS=$(date +%s)
  [ "${quiet}" ] || printf " ccls"
  ${BREW_EXE} install -q ccls > /dev/null 2>&1
  ${BREW_EXE} link --overwrite --quiet ccls > /dev/null 2>&1
  if [ "${debug}" ]
  then
    FINISH_SECONDS=$(date +%s)
    ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
    ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
    printf "\nInstall ccls elapsed time = %s${ELAPSED}\n"
  fi

  for pkg in golangci-lint jdtls marksman rust-analyzer shellcheck \
             taplo texlab stylua eslint prettier terraform black shfmt \
             yarn julia composer php deno
  do
    [ "${debug}" ] && START_SECONDS=$(date +%s)
    [ "${quiet}" ] || printf " ${pkg}"
    ${BREW_EXE} install -q ${pkg} > /dev/null 2>&1
    if [ "${debug}" ]
    then
      FINISH_SECONDS=$(date +%s)
      ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
      ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
      printf "\nInstall ${pkg} elapsed time = %s${ELAPSED}\n"
    fi
  done
  [ "${PYTHON}" ] && {
    ${PYTHON} -m pip install cmake-language-server > /dev/null 2>&1
    ${PYTHON} -m pip install python-lsp-server > /dev/null 2>&1
  }
  if command -v go >/dev/null 2>&1; then
    go install golang.org/x/tools/gopls@latest > /dev/null 2>&1
  fi
  [ "${quiet}" ] || printf " done"
}

install_tools() {
  check_python
  [ "${PYTHON}" ] || {
    # Could not find Python, install with Homebrew
    log 'Installing Python with Homebrew ...'
    ${BREW_EXE} install --quiet python > /dev/null 2>&1
    [ $? -eq 0 ] || ${BREW_EXE} link --overwrite --quiet python > /dev/null 2>&1
    link_python
    check_python
    [ "${quiet}" ] || printf " done"
  }
  [ "${PYTHON}" ] && {
    log 'Installing Python dependencies ...'
    ${PYTHON} -m pip install --upgrade pip > /dev/null 2>&1
    ${PYTHON} -m pip install --upgrade setuptools > /dev/null 2>&1
    ${PYTHON} -m pip install wheel > /dev/null 2>&1
    ${PYTHON} -m pip install pynvim doq > /dev/null 2>&1
    [ "${quiet}" ] || printf " done"
  }
  have_npm=$(type -p npm)
  [ "${have_npm}" ] && {
    log "Installing Neovim npm package ..."
    npm i -g neovim > /dev/null 2>&1
    [ "${quiet}" ] || printf " done"

    log "Installing the icon font for Visual Studio Code ..."
    npm i -g @vscode/codicons > /dev/null 2>&1
    [ "${quiet}" ] || printf " done"
  }
  if ! command -v tree-sitter >/dev/null 2>&1; then
    log "Installing tree-sitter command line interface ..."
    if [ "${debug}" ]
    then
      START_SECONDS=$(date +%s)
      ${BREW_EXE} install tree-sitter
      FINISH_SECONDS=$(date +%s)
      ELAPSECS=$(( FINISH_SECONDS - START_SECONDS ))
      ELAPSED=`eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
      printf "\nInstall tree-sitter elapsed time = %s${ELAPSED}\n"
    else
      ${BREW_EXE} install -q tree-sitter > /dev/null 2>&1
    fi
    [ "${quiet}" ] || printf " done"
  fi
  if command -v tree-sitter >/dev/null 2>&1; then
    tree-sitter init-config > /dev/null 2>&1
  fi
  if command -v cargo >/dev/null 2>&1; then
    cargo install rnix-lsp > /dev/null 2>&1
  fi
  GHUC="https://raw.githubusercontent.com"
  JETB_URL="${GHUC}/JetBrains/JetBrainsMono/master/install_manual.sh"
  [ "${quiet}" ] || printf "\n\tInstalling JetBrains Mono font ... "
  curl -fsSL "${JETB_URL}" > /tmp/jetb-$$.sh
  [ $? -eq 0 ] || {
    rm -f /tmp/jetb-$$.sh
    curl -kfsSL "${JETB_URL}" > /tmp/jetb-$$.sh
  }
  [ -f /tmp/jetb-$$.sh ] && {
    chmod 755 /tmp/jetb-$$.sh
    /bin/bash -c "/tmp/jetb-$$.sh" > /dev/null 2>&1
    rm -f /tmp/jetb-$$.sh
  }
  [ "${quiet}" ] || printf "done"
}

main () {
  if [ "${lang_tools}" ]
  then
    install_neovim_dependencies
    install_language_servers
    install_tools
  else
    check_prerequisites
    install_brew
    if ! command -v zoxide >/dev/null 2>&1; then
      install_zoxide
    fi
    if command -v nvim >/dev/null 2>&1; then
      nvim_version=$(nvim --version | head -1 | grep -o '[0-9]\.[0-9]')
      if (( $(echo "$nvim_version < 0.9 " |bc -l) )); then
        log "Currently installed Neovim is less than version 0.9"
        [ "${nvim_head}" ] && {
          log "Installing latest Neovim version with Homebrew"
          install_neovim_head
        }
      fi
    else
      log "Neovim not found, installing Neovim with Homebrew"
      if [ "${nvim_head}" ]
      then
        install_neovim_head
      else
        install_neovim
      fi
    fi
  fi
}

nvim_head=1
quiet=
debug=
lang_tools=

while getopts "dhlq" flag; do
  case $flag in
    d)
        debug=1
        ;;
    h)
        nvim_head=
        ;;
    l)
        lang_tools=1
        ;;
    q)
        quiet=1
        ;;
    *)
        ;;
  esac
done

currlimit=$(ulimit -n)
hardlimit=$(ulimit -Hn)
if [ ${hardlimit} -gt 4096 ]
then
  ulimit -n 4096
else
  ulimit -n ${hardlimit}
fi

[ "${debug}" ] && MAIN_START_SECONDS=$(date +%s)

main

[ "${debug}" ] && {
  MAIN_FINISH_SECONDS=$(date +%s)
  MAIN_ELAPSECS=$(( MAIN_FINISH_SECONDS - MAIN_START_SECONDS ))
  MAIN_ELAPSED=`eval "echo $(date -ud "@$MAIN_ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')"`
  printf "\nTotal elapsed time = %s${MAIN_ELAPSED}\n"
}

ulimit -n ${currlimit}