#!/usr/bin/env bash
#
# information.sh [-a] [-u] [config name]
#
# Generate a Neovim configuration information page from the command line
# If no configuraton name is given, use 'nvim-Lazyman'
#
# Generated information documents are stored in ~/.config/nvim-Lazyman/info/
# Info documents generated by this script are in Markdown format
# The Markdown is used to generate HTML versions with pandoc

CF_NAMES="Lazyman Abstract AstroNvimPlus BasicIde Ecovim LazyVim LunarVim NvChad Penguin SpaceVim MagicVim AlanVim Allaman CatNvim Go Go2one Knvim LaTeX LazyIde LunarIde LvimIde Magidc Nv NV-IDE Python Rust SaleVim Shuvro Webdev 3rd Adib Brain Charles Craftzdog Dillon Elianiva Enrique Heiker J4de Josean Daniel LvimAdib Maddison Metis Mini ONNO OnMyWay Optixal Rafi Roiz Simple Slydragonn Spider Traap xero Xiao BasicLsp BasicMason Extralight LspCmp Minimal StartBase Opinion StartLsp StartMason Modular 2k AstroNvimStart Basic CodeArt Cosmic Ember Fennel HardHacker JustinLvim JustinNvim Kabin Kickstart Lamia Micah Normal NvPak Modern pde Rohit Scratch SingleFile"

LMANDIR="${HOME}/.config/nvim-Lazyman"
LOGDIR="${LMANDIR}/logs"
PLURLS="${LMANDIR}/scripts/plugin_urls.txt"
[ -d "${LOGDIR}" ] || mkdir -p "${LOGDIR}"

usage() {
  printf "\n\nUsage: information.sh [-a] [nvim-conf]\n\n"
  exit 1
}

get_plugins() {
  nvimdir="$1"
  outfile="$2"
  plugman="$3"
  confdir=
  if [ -d "${HOME}/.config/${nvimdir}" ]
  then
    confdir="${HOME}/.config/${nvimdir}"
  else
    [ -d "${HOME}/.config/nvim-${nvimdir}" ] && {
      confdir="${HOME}/.config/nvim-${nvimdir}"
      nvimdir="nvim-${nvimdir}"
    }
  fi
  [ "${confdir}" ] && {
    case ${plugman} in
      Lazy)
        if [ -f "${confdir}/lazy-lock.json" ]
        then
          echo "### Lazy managed plugins" >> "${outfile}"
          echo "" >> "${outfile}"
          grep ':' "${confdir}/lazy-lock.json" | awk -F ':' ' { print $1 } ' | \
          sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | \
          sed -e 's/"//g' -e "s/'//g" | while read plug
          do
            url=$(grep ${plug} ${PLURLS} | head -1)
            if [ "${url}" ]
            then
              plugin=$(echo ${url} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ')
              echo "- [${plugin}](${url})" >> "${outfile}"
            else
              gitconf="${HOME}/.local/share/${nvimdir}/lazy/${plug}/.git/config"
              if [ -f ${gitconf} ]
              then
                plugurl=$(grep url "${gitconf}" | head -1 | awk -F '=' ' { print $2 } ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                plugin=$(echo ${plugurl} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ' | sed -e "s/\.git$//")
                echo "- [${plugin}](${plugurl})" >> "${outfile}"
              else
                gitconf="${HOME}/.local/share/${nvimdir}/site/pack/lazy/opt/${plug}/.git/config"
                if [ -f ${gitconf} ]
                then
                  plugurl=$(grep url "${gitconf}" | head -1 | awk -F '=' ' { print $2 } ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                  plugin=$(echo ${plugurl} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ' | sed -e "s/\.git$//")
                  echo "- [${plugin}](${plugurl})" >> "${outfile}"
                else
                  echo "- ${plug}" >> "${outfile}"
                fi
              fi
            fi
          done
        else
          echo "### Lazy managed plugins" >> "${outfile}"
          echo "" >> "${outfile}"
          for gitconf in ${HOME}/.local/share/${nvimdir}/lazy/*/.git/config \
                         ${HOME}/.local/share/${nvimdir}/site/pack/lazy/opt/*/.git/config
          do
            [ "${gitconf}" == "${HOME}/.local/share/${nvimdir}/lazy/*/.git/config" ] && continue
            [ "${gitconf}" == "${HOME}/.local/share/${nvimdir}/site/pack/lazy/opt/*/.git/config" ] && continue
            if [ -f ${gitconf} ]
            then
              plugurl=$(grep url "${gitconf}" | head -1 | awk -F '=' ' { print $2 } ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
              plugin=$(echo ${plugurl} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ' | sed -e "s/\.git$//")
              echo "- [${plugin}](${plugurl})" >> "${outfile}"
            fi
          done
        fi
        ;;
      Mini)
        echo "### Mini.nvim managed plugins" >> "${outfile}"
        echo "" >> "${outfile}"
        for gitconf in ${confdir}/.git/modules/*/config
        do
          [ "${gitconf}" == "${confdir}/.git/modules/*/config" ] && continue
          plugurl=$(grep url "${gitconf}" | head -1 | awk -F '=' ' { print $2 } ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
          plugin=$(echo ${plugurl} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ' | sed -e "s/\.git$//")
          echo "- [${plugin}](${plugurl})" >> "${outfile}"
        done
        ;;
      Packer)
        echo "### Packer managed plugins" >> "${outfile}"
        echo "" >> "${outfile}"
        find "${confdir}" -name packer_compiled.lua -print0 | \
        xargs -0 grep url | grep = | awk -F '=' ' { print $2 } ' | \
        sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | \
        sed -e 's/"//g' -e "s/'//g" | while read url
        do
          plugin=$(echo ${url} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ')
          echo "- [${plugin}](${url})" >> "${outfile}"
        done
        ;;
      Plug)
        echo "### Plug managed plugins" >> "${outfile}"
        echo "" >> "${outfile}"
        for gitconf in ${HOME}/.local/share/${nvimdir}/plugged/*/.git/config
        do
          [ "${gitconf}" == "${HOME}/.local/share/${nvimdir}/plugged/*/.git/config" ] && continue
          plugurl=$(grep url "${gitconf}" | head -1 | awk -F '=' ' { print $2 } ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
          plugin=$(echo ${plugurl} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ' | sed -e "s/\.git$//")
          echo "- [${plugin}](${plugurl})" >> "${outfile}"
        done
        ;;
      SP*)
        echo "### SP (dein) managed plugins" >> "${outfile}"
        echo "" >> "${outfile}"
        for gitconf in ${HOME}/.cache/vimfiles/repos/*/*/*/.git/config
        do
          [ "${gitconf}" == "${HOME}/.cache/vimfiles/repos/*/*/*/.git/config" ] && continue
          plugurl=$(grep url "${gitconf}" | head -1 | awk -F '=' ' { print $2 } ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
          plugin=$(echo ${plugurl} | awk -F '/' ' { print $(NF - 1)"/"$(NF) } ' | sed -e "s/\.git$//")
          echo "- [${plugin}](${plugurl})" >> "${outfile}"
        done
        ;;
      *)
        echo "### Unsupported plugin manager" >> "${outfile}"
        ;;
    esac
  }
}

make_info() {
  nvimconf="$1"
  OUTF="${HOME}/src/Neovim/nvim-lazyman/info/${nvimconf}.md"
  HTML="${HOME}/src/Neovim/nvim-lazyman/info/html/${nvimconf}.html"

  GH_URL=
  NC_URL=
  DF_URL=
  WS_URL=
  CF_CAT="Unknown"
  CF_TYP="Custom"
  PL_MAN="Lazy"
  C_DESC=
  C_INST=
  case ${nvimconf} in
    Lazyman)
      GH_URL="https://github.com/doctorfree/nvim-lazyman"
      NC_URL="http://neovimcraft.com/plugin/doctorfree/nvim-lazyman"
      DF_URL="https://dotfyle.com/doctorfree/nvim-lazyman"
      CF_CAT="Default"
      C_DESC="Neovim configuration of Dr. Ronald Joe Record"
      C_INST="Installed and initialized by default"
      ;;
    Abstract)
      GH_URL="https://github.com/Abstract-IDE/Abstract"
      NC_URL="https://neovimcraft.com/plugin/Abstract-IDE/Abstract"
      DF_URL="https://dotfyle.com/plugins/Abstract-IDE/Abstract"
      WS_URL="https://abstract-ide.github.io/site"
      CF_CAT="Base"
      PL_MAN="Packer"
      C_DESC="Preconfigured Neovim as an IDE"
      C_INST="lazyman -g"
      ;;
    AstroNvimPlus)
      GH_URL="https://github.com/doctorfree/astronvim"
      CF_CAT="Base"
      CF_TYP="[AstroNvim](https://astronvim.com)"
      C_DESC="An example [AstroNvim community](https://github.com/AstroNvim/astrocommunity) plugins configuration"
      C_INST="lazyman -a"
      ;;
    BasicIde)
      GH_URL="https://github.com/LunarVim/nvim-basic-ide"
      CF_CAT="Base"
      C_DESC="Maintained by LunarVim, this is a descendent of 'Neovim from Scratch'.All plugins are pinned to known working versions"
      C_INST="lazyman -j"
      ;;
    Ecovim)
      GH_URL="https://github.com/ecosse3/nvim"
      NC_URL="http://neovimcraft.com/plugin/ecosse3/nvim"
      CF_CAT="Base"
      C_DESC="Tailored for frontend development with React and Vue.js"
      C_INST="lazyman -e"
      ;;
    LazyVim)
      GH_URL="https://github.com/LazyVim LazyVim/starter"
      CF_CAT="Base"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="The [LazyVim starter](https://github.com/LazyVim/starter) configuration"
      C_INST="lazyman -l"
      ;;
    LunarVim)
      GH_URL="https://github.com/IfCodingWereNatural/minimal-nvim"
      CF_CAT="Base"
      CF_TYP="[LunarVim](https://www.lunarvim.org)"
      C_DESC="Installs LunarVim plus the [IfCodingWereNatural custom user config](https://youtu.be/Qf9gfx7gWEY)"
      C_INST="lazyman -v"
      ;;
    NvChad)
      GH_URL="https://github.com/doctorfree/NvChad-custom"
      CF_CAT="Base"
      CF_TYP="[NvChad](https://nvchad.com)"
      C_DESC="Advanced [customization of NvChad](https://github.com/doctorfree/NvChad-custom). Good [introductory video](https://youtu.be/Mtgo-nP_r8Y) to NvChad"
      C_INST="lazyman -c"
      ;;
    Penguin)
      GH_URL="https://github.com/p3nguin-kun/penguinVim"
      CF_CAT="Base"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="Aims to provide a base configuration with beautiful UI and fast startup time"
      C_INST="lazyman -o"
      ;;
    SpaceVim)
      GH_URL="https://github.com/doctorfree/spacevim"
      CF_CAT="Base"
      CF_TYP="[SpaceVim](https://spacevim.org)"
      PL_MAN="SP (dein)"
      C_DESC="SpaceVim started in December 2016, it is a mature and well supported Neovim configuration distribution. Lazyman custom SpaceVim configuration installed in \`~/.SpaceVim.d/\`"
      C_INST="lazyman -s"
      ;;
    MagicVim)
      GH_URL="https://gitlab.com/GitMaster210/magicvim"
      CF_CAT="Base"
      PL_MAN="Packer"
      C_DESC="Custom Neovim configuration designed to be light and fast. LSP, Treesitter & Code Completion all work out of the box and auto install when you open a file type that doesn't have code completion for it yet."
      C_INST="lazyman -m"
      ;;
    AlanVim)
      GH_URL="https://github.com/alanRizzo/dot-files"
      CF_CAT="Language"
      PL_MAN="Packer"
      C_DESC="Oriented toward Python development"
      C_INST="lazyman -L AlanVim"
      ;;
    Allaman)
      GH_URL="https://github.com/Allaman/nvim"
      DF_URL="https://dotfyle.com/Allaman/nvim"
      CF_CAT="Language"
      C_DESC="One of the inspirations for Lazyman. Excellent support for Python, Golang, Rust, YAML, and more"
      C_INST="lazyman -L Allaman"
      ;;
    CatNvim)
      GH_URL="https://github.com/nullchilly/CatNvim"
      DF_URL="https://dotfyle.com/nullchilly/catnvim"
      CF_CAT="Language"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="Neovim configuration written in the [C programming language](https://en.wikipedia.org/wiki/C_(programming_language))"
      C_INST="lazyman -L CatNvim"
      ;;
    Go)
      GH_URL="https://github.com/dreamsofcode-io/neovim-go-config"
      CF_CAT="Language"
      CF_TYP="[NvChad](https://nvchad.com)"
      C_DESC="NvChad based Neovim config with Go formatting, debugging, and diagnostics. Dreams of Code [video tutorial](https://youtu.be/i04sSQjd-qo)"
      C_INST="lazyman -L Go"
      ;;
    Go2one)
      GH_URL="https://github.com/leoluz/go2one"
      CF_CAT="Language"
      C_DESC="Neovim Go development environment that does not touch standard Neovim configuration folders"
      C_INST="lazyman -L Go2one"
      ;;
    Knvim)
      GH_URL="https://github.com/knmac/knvim"
      DF_URL="https://dotfyle.com/knmac/knvim"
      CF_CAT="Language"
      C_DESC="Targets Python, Bash, LaTeX, Markdown, and C/C++. See the [Knvim Config Cheat Sheet](https://github.com/knmac/knvim/blob/main/res/cheatsheet.md)"
      C_INST="lazyman -L Knvim"
      ;;
    LaTeX)
      GH_URL="https://github.com/benbrastmckie/.config"
      NC_URL="http://neovimcraft.com/plugin/benbrastmckie/.config"
      CF_CAT="Language"
      PL_MAN="Packer"
      C_DESC="Neovim configuration optimized for writing in LaTeX. Personal Neovim configuration of [Benjamin Brast-McKie](http://www.benbrastmckie.com). Keymaps and more described in the configuration [Cheatsheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md). Blog article by the author detailing [tools used by his configuration](http://www.benbrastmckie.com/tools#access). [Video playlist](https://www.youtube.com/watch?v=_Ct2S65kpjQ&list=PLBYZ1xfnKeDRhCoaM4bTFrjCl3NKDBvqk) of tutorials on using this config for writing LaTeX in Neovim"
      C_INST="lazyman -L LaTeX"
      ;;
    LazyIde)
      GH_URL="https://github.com/doctorfree/nvim-LazyIde"
      CF_CAT="Language"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="LazyVim IDE config for Neovim"
      C_INST="lazyman -L LazyIde"
      ;;
    LunarIde)
      GH_URL="https://github.com/doctorfree/lvim-Christian"
      CF_CAT="Language"
      CF_TYP="[LunarVim](https://www.lunarvim.org)"
      C_DESC="LunarVim config based on [Christian Chiarulli's](https://github.com/ChristianChiarulli/lvim). Java, Python, Lua, Go, JavaScript, Typescript, React, and Rust IDE"
      C_INST="lazyman -L LunarIde"
      ;;
    LvimIde)
      GH_URL="https://github.com/lvim-tech/lvim"
      NC_URL="http://neovimcraft.com/plugin/lvim-tech/lvim"
      CF_CAT="Language"
      C_DESC="Not to be confused with 'LunarVim', this is a standalone Neovim configuration. Modular configuration with LSP support for 60+ languages. Debug support for c, cpp, dart, elixir, go, haskell, java, javascript/typescript, lua, php, python, ruby, rust"
      C_INST="lazyman -L LvimIde"
      ;;
    Magidc)
      GH_URL="https://github.com/magidc/nvim-config"
      CF_CAT="Language"
      C_DESC="Java, Python, Lua, and Rust IDE"
      C_INST="lazyman -L Magidc"
      ;;
    Nv)
      GH_URL="https://github.com/appelgriebsch/Nv"
      NC_URL="http://neovimcraft.com/plugin/appelgriebsch/Nv"
      DF_URL="https://dotfyle.com/appelgriebsch/nv"
      CF_CAT="Language"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="'LazyVim' based Neovim configuration. Andreas Gerlach develops smart farming tech and maintains the 'Sway' edition of 'Manjaro-arm'"
      C_INST="lazyman -L Nv"
      ;;
    NV-IDE)
      GH_URL="https://github.com/crivotz/nv-ide"
      NC_URL="http://neovimcraft.com/plugin/crivotz/nv-ide"
      DF_URL="https://dotfyle.com/crivotz/nv-ide"
      CF_CAT="Language"
      C_DESC="Configuration oriented for web developers (rails, ruby, php, html, css, SCSS, javascript)"
      C_INST="lazyman -L NV-IDE"
      ;;
    Python)
      GH_URL="https://github.com/dreamsofcode-io/neovim-python"
      CF_CAT="Language"
      CF_TYP="[NvChad](https://nvchad.com)"
      C_DESC="'NvChad' based Neovim config with Python formatting, debugging, and diagnostics. Dreams of Code [video tutorial](https://youtu.be/4BnVeOUeZxc). These features are included in the Base 'NvChad' custom add-on (lazyman -c)"
      C_INST="-L Python"
      ;;
    Rust)
      GH_URL="https://github.com/dreamsofcode-io/neovim-rust"
      CF_CAT="Language"
      CF_TYP="[NvChad](https://nvchad.com)"
      C_DESC="'NvChad' based Neovim config with Rust formatting, debugging, and diagnostics. Dreams of Code [video tutorial](https://youtu.be/mh_EJhH49Ms)"
      C_INST="lazyman -L Rust"
      ;;
    SaleVim)
      GH_URL="https://github.com/igorcguedes/SaleVim"
      CF_CAT="Language"
      PL_MAN="Packer"
      C_DESC="'Salesforce' optimized IDE with custom features for editing 'Apex', 'Visualforce', and 'Lightning' code"
      C_INST="lazyman -L SaleVim"
      ;;
    Shuvro)
      GH_URL="https://github.com/shuvro/lvim"
      CF_CAT="Language"
      CF_TYP="[LunarVim](https://www.lunarvim.org)"
      C_DESC="Significantly improved fork of [Abouzar Parvan's](https://github.com/abzcoding/lvim) advanced 'LunarVim' config"
      C_INST="lazyman -L Shuvro"
      ;;
    Webdev)
      GH_URL="https://github.com/doctorfree/nvim-webdev"
      CF_CAT="Language"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="LazyVim based config for web developers. JavaScript, Typescript, React, and Tailwind CSS support"
      C_INST="lazyman -L Webdev"
      ;;
    3rd)
      GH_URL="https://github.com/3rd/config"
      DF_URL="https://dotfyle.com/3rd/config-home-dotfiles-nvim"
      CF_CAT="Personal"
      C_DESC="Example [custom tree-sitter grammar](https://github.com/3rd/syslang)"
      C_INST="lazyman -w 3rd"
      ;;
    Adib)
      GH_URL="https://github.com/adibhanna/nvim"
      NC_URL="http://neovimcraft.com/plugin/adibhanna/nvim"
      CF_CAT="Personal"
      C_DESC="Personal Neovim configuration of Adib Hanna. Tips, distros, and configuration [demo video](https://youtu.be/8SVPOKZVaMU)"
      C_INST="lazyman -w Adib"
      ;;
    Brain)
      GH_URL="https://github.com/brainfucksec/neovim-lua"
      NC_URL="http://neovimcraft.com/plugin/brainfucksec/neovim-lua"
      CF_CAT="Personal"
      C_DESC="Well structured personal config based on the [KISS](https://en.wikipedia.org/wiki/KISS_principle) principle"
      C_INST="lazyman -w Brain"
      ;;
    Charles)
      GH_URL="https://github.com/CharlesChiuGit/nvimdots.lua"
      CF_CAT="Personal"
      C_DESC="Well structured lazy config with several setup scripts and a Wiki"
      C_INST="lazyman -w Charles"
      ;;
    Craftzdog)
      GH_URL="https://github.com/craftzdog/dotfiles-public"
      DF_URL="https://dotfyle.com/craftzdog/dotfiles-public-config-nvim"
      CF_CAT="Personal"
      C_DESC="Takuya Matsuyama's Neovim configuration"
      C_INST="lazyman -w Craftzdog"
      ;;
    Dillon)
      GH_URL="https://github.com/dmmulroy/dotfiles"
      CF_CAT="Personal"
      C_DESC="Author of [tsc.nvim](https://github.com/dmmulroy/tsc.nvim), asynchronous TypeScript type-checking"
      C_INST="lazyman -w Dillon"
      ;;
    Elianiva)
      GH_URL="https://github.com/elianiva/dotfiles"
      CF_CAT="Personal"
      C_DESC="Personal Neovim configuration of Dicha Zelianivan Arkana"
      C_INST="lazyman -w Elianiva"
      ;;
    Enrique)
      GH_URL="https://github.com/kiyov09/dotfiles"
      CF_CAT="Personal"
      C_DESC="Personal Neovim configuration of Enrique Mejidas"
      C_INST="lazyman -w Enrique"
      ;;
    Heiker)
      GH_URL="https://github.com/VonHeikemen/dotfiles"
      CF_CAT="Personal"
      C_DESC="Neovim config of Heiker Curiel, author of [lsp-zero](https://github.com/VonHeikemen/lsp-zero.nvim)"
      C_INST="lazyman -w Heiker"
      ;;
    J4de)
      GH_URL="https://codeberg.org/j4de/nvim"
      CF_CAT="Personal"
      C_DESC="Personal Neovim configuration of Jade Fox"
      C_INST="lazyman -w J4de"
      ;;
    Josean)
      GH_URL="https://github.com/josean-dev/dev-environment-files"
      CF_CAT="Personal"
      PL_MAN="Packer"
      C_DESC="Josean Martinez [video tutorial](https://youtu.be/vdn_pKJUda8)"
      C_INST="lazyman -w Josean"
      ;;
    Daniel)
      GH_URL="https://github.com/daniel-vera-g/lvim"
      CF_CAT="Personal"
      CF_TYP="[LunarVim](https://www.lunarvim.org)"
      C_DESC="'LunarVim' based config of Daniel Vera Gilliard"
      C_INST="lazyman -w Daniel"
      ;;
    LvimAdib)
      GH_URL="https://github.com/adibhanna/lvim-config"
      CF_CAT="Personal"
      CF_TYP="[LunarVim](https://www.lunarvim.org)"
      ;;
    Maddison)
      GH_URL="https://github.com/b0o/nvim-conf"
      DF_URL="https://dotfyle.com/b0o/nvim-conf"
      CF_CAT="Personal"
      C_DESC="Personal Neovim configuration of Maddison Hellstrom, author of 'incline.nvim' floating statuslines, 'SchemaStore.nvim' JSON schemas, 'mapx.nvim' better keymaps"
      C_INST="lazyman -w Maddison"
      ;;
    Metis)
      GH_URL="https://github.com/metis-os/pwnvim"
      CF_CAT="Personal"
      C_DESC="Neovim config by the creator of 'MetisLinux' and 'Ewm'"
      C_INST="lazyman -w Metis"
      ;;
    Mini)
      GH_URL="https://github.com/echasnovski/nvim"
      NC_URL="http://neovimcraft.com/plugin/echasnovski/nvim"
      CF_CAT="Personal"
      PL_MAN="Mini"
      C_DESC="Uses the [mini.nvim](https://github.com/echasnovski/mini.nvim) library. Personal configuration of the 'mini.nvim' author"
      C_INST="lazyman -M"
      ;;
    ONNO)
      GH_URL="https://github.com/loctvl842/nvim"
      DF_URL="https://dotfyle.com/loctvl842/nvim"
      CF_CAT="Personal"
      C_DESC="One of the primary inspirations for Lazyman"
      C_INST="lazyman -w ONNO"
      ;;
    OnMyWay)
      GH_URL="https://github.com/RchrdAlv/NvimOnMy_way"
      CF_CAT="Personal"
      C_DESC="The personal Neovim configuration of Richard Ariza"
      C_INST="lazyman -w OnMyWay"
      ;;
    Optixal)
      GH_URL="https://github.com/Optixal/neovim-init.vim"
      NC_URL="http://neovimcraft.com/plugin/Optixal/neovim-init.vim"
      CF_CAT="Personal"
      PL_MAN="Plug"
      C_DESC="Hybrid Neovim config for developers with a functional yet aesthetic experience. Uses a combination of vimscript and lua with the 'vim-plug' plugin manager"
      C_INST="lazyman -w Optixal"
      ;;
    Rafi)
      GH_URL="https://github.com/rafi/vim-config"
      DF_URL="https://dotfyle.com/rafi/vim-config"
      CF_CAT="Personal"
      C_DESC="[Extensible](https://github.com/rafi/vim-config#extending) Neovim configuration"
      C_INST="lazyman -w Rafi"
      ;;
    Roiz)
      GH_URL="https://github.com/MrRoiz/rnvim"
      CF_CAT="Personal"
      C_DESC="Just a random Neovim config found on Github, works well"
      C_INST="lazyman -w Roiz"
      ;;
    Simple)
      GH_URL="https://github.com/anthdm/.nvim"
      CF_CAT="Personal"
      PL_MAN="Packer"
      C_DESC="A remarkably effective Neovim configuration in only one small file. The author's [video description of this config](https://youtu.be/AzhSnM0uHvM)"
      C_INST="lazyman -w Simple"
      ;;
    Slydragonn)
      GH_URL="https://github.com/slydragonn/dotfiles"
      CF_CAT="Personal"
      PL_MAN="Packer"
      C_DESC="[Introductory video](https://youtu.be/vkCnPdaRBE0)"
      C_INST="lazyman -w Slydragonn"
      ;;
    Spider)
      GH_URL="https://github.com/fearless-spider/FSAstroNvim"
      CF_CAT="Personal"
      CF_TYP="[AstroNvim](https://astronvim.com)"
      C_DESC="AstroNvim based configuration with animated status bar and smooth scroll. [Introductory video](https://youtu.be/Lj6MZsKl9MU)"
      C_INST="lazyman -w Spider"
      ;;
    Traap)
      GH_URL="https://github.com/Traap/nvim"
      CF_CAT="Personal"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="[Introductory video](https://youtu.be/aD9j6d9pgtc)"
      C_INST="lazyman -w Traap"
      ;;
    xero)
      GH_URL="https://github.com/xero/dotfiles"
      NC_URL="http://neovimcraft.com/plugin/xero/dotfiles"
      DF_URL="https://dotfyle.com/xero/dotfiles-neovim-config-nvim"
      CF_CAT="Personal"
      C_DESC="Personal neovim configuration of [xero harrison](https://x-e.ro/). Xero is a fine example, as are many here, of the Unix Greybeard"
      C_INST="lazyman -w xero"
      ;;
    Xiao)
      GH_URL="https://github.com/onichandame/nvim-config"
      CF_CAT="Personal"
      C_DESC="Personal Neovim configuration of XiaoZhang"
      C_INST="lazyman -w Xiao"
      ;;
    BasicLsp)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/xx-basic-lsp"
      CF_CAT="Starter"
      C_DESC="Example lua configuration showing one way to setup LSP servers without plugins"
      C_INST="lazyman -x BasicLsp"
      ;;
    BasicMason)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/xx-mason"
      CF_CAT="Starter"
      C_DESC="Minimal setup with 'mason.nvim'"
      C_INST="lazyman -x BasicMason"
      ;;
    Extralight)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/xx-light"
      CF_CAT="Starter"
      C_DESC="Single file lightweight configuration focused on providing basic features"
      C_INST="lazyman -x Extralight"
      ;;
    LspCmp)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/xx-lsp-cmp"
      CF_CAT="Starter"
      C_DESC="Minimal setup with 'nvim-lspconfig' and 'nvim-cmp'"
      C_INST="lazyman -x LspCmp"
      ;;
    Minimal)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/00-minimal"
      CF_CAT="Starter"
      C_DESC="Small configuration without third party plugins"
      C_INST="lazyman -x Minimal"
      ;;
    StartBase)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/01-base"
      CF_CAT="Starter"
      C_DESC="Small configuration that includes a plugin manager"
      C_INST="lazyman -x StartBase"
      ;;
    Opinion)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/02-opinionated"
      CF_CAT="Starter"
      C_DESC="Includes a combination of popular plugins"
      C_INST="lazyman -x Opinion"
      ;;
    StartLsp)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/03-lsp"
      CF_CAT="Starter"
      C_DESC="Configures the built-in LSP client with autocompletion, based on 'Opinionated'"
      C_INST="lazyman -x StartLsp"
      ;;
    StartMason)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/04-lsp-installer"
      CF_CAT="Starter"
      C_DESC="Same as 'StartLsp' but uses [mason.nvim](https://github.com/williamboman/mason.nvim) to install language servers"
      C_INST="lazyman -x StartMason"
      ;;
    Modular)
      GH_URL="https://github.com/VonHeikemen/nvim-starter/tree/05-modular"
      CF_CAT="Starter"
      C_DESC="Same as 'StartMason' but everything is split in modules"
      C_INST="lazyman -x Modular"
      ;;
    2k)
      GH_URL="https://github.com/2KAbhishek/nvim2k"
      CF_CAT="Starter"
      C_DESC="[Video walkthrough](https://youtu.be/WfhylGI_F-o)"
      C_INST="lazyman -x 2k"
      ;;
    AstroNvimStart)
      GH_URL="https://github.com/doctorfree/AstroNvimStart"
      CF_CAT="Starter"
      CF_TYP="[AstroNvim](https://astronvim.com)"
      C_DESC="Default AstroNvim example configuration"
      C_INST="lazyman -x AstroNvimStart"
      ;;
    Basic)
      GH_URL="https://github.com/NvChad/basic-config"
      CF_CAT="Starter"
      C_DESC="Starter config by the author of NvChad with [video tutorial](https://youtube.com/playlist?list=PLYVQrj2EVSUL1NqYn3jsIVXG3U9eWaMcq)"
      C_INST="lazyman -x Basic"
      ;;
    CodeArt)
      GH_URL="https://github.com/artart222/CodeArt"
      NC_URL="http://neovimcraft.com/plugin/artart222/CodeArt"
      DF_URL="https://dotfyle.com/plugins/artart222/CodeArt"
      CF_CAT="Starter"
      PL_MAN="Packer"
      C_DESC="Use Neovim as a general purpose IDE"
      C_INST="lazyman -x CodeArt"
      ;;
    Cosmic)
      GH_URL="https://github.com/CosmicNvim/CosmicNvim"
      NC_URL="http://neovimcraft.com/plugin/CosmicNvim/CosmicNvim"
      DF_URL="https://dotfyle.com/plugins/CosmicNvim/CosmicNvim"
      CF_CAT="Starter"
      C_DESC="Install 'Node.js', 'prettierd', and 'eslint_d'"
      C_INST="lazyman -x Cosmic"
      ;;
    Ember)
      GH_URL="https://github.com/danlikestocode/embervim"
      DF_URL="https://dotfyle.com/danlikestocode/embervim-nvim"
      CF_CAT="Starter"
      C_DESC="Dan is a computer science student at Arizona State University"
      C_INST="lazyman -x Ember"
      ;;
    Fennel)
      GH_URL="https://github.com/jhchabran/nvim-config"
      CF_CAT="Starter"
      PL_MAN="Packer"
      C_DESC="An opinionated configuration reminiscent of Doom-Emacs, written in Fennel"
      C_INST="lazyman -x Fennel"
      ;;
    HardHacker)
      GH_URL="https://github.com/hardhackerlabs/oh-my-nvim"
      CF_CAT="Starter"
      C_DESC="A theme-driven modern Neovim configuration"
      C_INST="lazyman -x HardHacker"
      ;;
    JustinLvim)
      GH_URL="https://github.com/justinsgithub/dotfiles"
      CF_CAT="Starter"
      CF_TYP="[LunarVim](https://www.lunarvim.org)"
      C_DESC="LunarVim based Neovim configuration by Justin Angeles"
      C_INST="lazyman -x JustinLvim"
      ;;
    JustinNvim)
      GH_URL="https://github.com/justinsgithub/dotfiles"
      CF_CAT="Starter"
      CF_TYP="[LazyVim](https://lazyvim.github.io)"
      C_DESC="LazyVim based Neovim configuration by Justin Angeles. Justin has created a series of YouTube videos on configuring LazyVim: [Part 1 - Colorschemne](https://youtu.be/LznwxUSZz_8), [Part 2 - Options](https://youtu.be/I4flypojhUk), [Part 3 - Keymaps](https://youtu.be/Vc_5feJ9F5k), [Part 4 - Final Thoughts](https://youtu.be/eRQHWeJ3D7I)"
      C_INST="lazyman -x JustinNvim"
      ;;
    Kabin)
      GH_URL="https://github.com/kabinspace/AstroNvim_user"
      CF_CAT="Starter"
      CF_TYP="[AstroNvim](https://astronvim.com)"
      C_DESC="One of the AstroNvim 'Black Belt' example advanced configurations"
      C_INST="lazyman -x Kabin"
      ;;
    Kickstart)
      GH_URL="https://github.com/doctorfree/kickstart.nvim"
      CF_CAT="Starter"
      CF_TYP="[Kickstart](https://github.com/nvim-lua/kickstart.nvim)"
      C_DESC="Popular starting point, small, single file, well documented, modular"
      C_INST="lazyman -k"
      ;;
    Lamia)
      GH_URL="https://github.com/A-Lamia/AstroNvim-conf"
      CF_CAT="Starter"
      CF_TYP="[AstroNvim](https://astronvim.com)"
      C_DESC="One of the AstroNvim 'Black Belt' example advanced configurations"
      C_INST="lazyman -x Lamia"
      ;;
    Micah)
      GH_URL="https://code.mehalter.com/AstroNvim_user"
      CF_CAT="Starter"
      CF_TYP="[AstroNvim](https://astronvim.com)"
      C_DESC="One of the AstroNvim 'Black Belt' example advanced configurations"
      C_INST="lazyman -x Micah"
      ;;
    Normal)
      GH_URL="https://github.com/NormalNvim/NormalNvim"
      NC_URL="http://neovimcraft.com/plugin/NormalNvim/NormalNvim"
      CF_CAT="Starter"
      CF_TYP="[AstroNvim](https://astronvim.com)"
      C_DESC="Based on AstroNvim with additional features"
      C_INST="lazyman -x Normal"
      ;;
    NvPak)
      GH_URL="https://github.com/Pakrohk-DotFiles/NvPak.git"
      NC_URL="http://neovimcraft.com/plugin/Pakrohk-DotFiles/NvPak"
      CF_CAT="Starter"
      C_DESC="PaK in Farsi means pure, something that is in its purest form"
      C_INST="lazyman -x NvPak"
      ;;
    Modern)
      GH_URL="https://github.com/alpha2phi/modern-neovim"
      CF_CAT="Starter"
      C_DESC="Configure Neovim as a modernized development environment. Details described in [an excellent Medium article](https://alpha2phi.medium.com/modern-neovim-configuration-recipes-d68b16537698)"
      C_INST="lazyman -x Modern"
      ;;
    pde)
      GH_URL="https://github.com/alpha2phi/neovim-pde"
      CF_CAT="Starter"
      C_DESC="Configure Neovim as a Personalized Development Environment (PDE)"
      C_INST="lazyman -x pde"
      ;;
    Rohit)
      GH_URL="https://github.com/rohit-kumar-j/nvim"
      CF_CAT="Starter"
      C_DESC="Good example use of [mason-tool-installer](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim)"
      C_INST="lazyman -x Rohit"
      ;;
    Scratch)
      GH_URL="https://github.com/ngscheurich/nvim-from-scratch"
      CF_CAT="Starter"
      C_DESC="Jumping-off point for new Neovim users or those who have declared config bankruptcy"
      C_INST="lazyman -x Scratch"
      ;;
    SingleFile)
      GH_URL="https://github.com/creativenull/nvim-oneconfig"
      CF_CAT="Starter"
      PL_MAN="Packer"
      C_DESC="A clean, organized pre-configured Neovim configuration guide in a single 'init.lua'"
      C_INST="lazyman -x SingleFile"
      ;;
    *)
      nvimdir="nvim-${nvimconf}"
      CDIR="${HOME}/.config/${nvimdir}"
      [ -d "${CDIR}" ] || {
        nvimdir="${nvimconf}"
        CDIR="${HOME}/.config/${nvimdir}"
      }
      if [ -d "${CDIR}" ]
      then
        # Custom config, figure out its nature if we can
        if [ -f "${CDIR}/.git/config" ]
        then
          GH_URL=$(grep url "${CDIR}/.git/config" | head -1 | awk -F '=' ' { print $2 } ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        else
          GH_URL=
        fi
        CF_CAT="Custom"
        CF_TYP="Unknown"
        if [ -f "${CDIR}/lazy-lock.json" ]
        then
          PL_MAN="Lazy"
        else
          pclua=$(find ${CDIR} -name packer_compiled.lua -print0)
          if [ "${pclua}" ]
          then
            PL_MAN="Packer"
          else
            if [ -f "${HOME}/.local/share/${nvimdir}/site/autoload/plug.vim" ]
            then
              PL_MAN="Plug"
            else
              if [ -d "${HOME}/.config/${nvimdir}/lua/spacevim" ]
              then
                PL_MAN="SP (dein)"
              else
                if [ -d "${HOME}/.config/${nvimdir}/.git/modules/mini" ]
                then
                  PL_MAN="Mini"
                else
                  PL_MAN="Unknown"
                fi
              fi
            fi
          fi
        fi
      else
        echo "Unknown Lazyman configuration name: ${nvimconf}"
        echo "Exiting"
        exit 1
      fi
      ;;
  esac

  echo "## ${nvimconf} Neovim Configuration Information" > "${OUTF}"
  echo "" >> "${OUTF}"
  [ "${C_DESC}" ] && {
    echo "${C_DESC}" >> "${OUTF}"
    echo "" >> "${OUTF}"
  }
  [ "${C_INST}" ] && {
    echo "- Install and initialize: \`${C_INST}\`" >> "${OUTF}"
  }
  case ${CF_CAT} in
    Base)
      caturl="https://github.com/doctorfree/nvim-lazyman#base-configurations"
      ;;
    Custom)
      caturl="https://github.com/doctorfree/nvim-lazyman#custom-configurations"
      ;;
    Default)
      caturl="https://github.com/doctorfree/nvim-lazyman#lazyman-neovim-configuration-features"
      ;;
    Language)
      caturl="https://github.com/doctorfree/nvim-lazyman#language-configurations"
      ;;
    Personal)
      caturl="https://github.com/doctorfree/nvim-lazyman#personal-configurations"
      ;;
    Starter)
      caturl="https://github.com/doctorfree/nvim-lazyman#starter-configurations"
      ;;
    *)
      caturl=
      ;;
  esac
  if [ "${caturl}" ]
  then
    echo "- Configuration category: [${CF_CAT}](${caturl})" >> "${OUTF}"
  else
    echo "- Configuration category: ${CF_CAT}" >> "${OUTF}"
  fi
  echo "- Base configuration:     ${CF_TYP}" >> "${OUTF}"
  case ${PL_MAN} in
    Lazy)
      plurl="https://github.com/folke/lazy.nvim"
      ;;
    Mini)
      plurl="https://github.com/echasnovski/mini.nvim"
      ;;
    Packer)
      plurl="https://github.com/wbthomason/packer.nvim"
      ;;
    Plug)
      plurl="https://github.com/junegunn/vim-plug"
      ;;
    SP*)
      plurl="https://github.com/Shougo/dein.vim"
      ;;
    *)
      plurl=
      ;;
  esac
  if [ "${plurl}" ]
  then
    echo "- Plugin manager:         [${PL_MAN}](${plurl})" >> "${OUTF}"
  else
    echo "- Plugin manager:         ${PL_MAN}" >> "${OUTF}"
  fi
  echo "- Installation location:  \`~/.config/nvim-${nvimconf}\`" >> "${OUTF}"
  echo "" >> "${OUTF}"
  echo "[Links to all Lazyman supported configuration documents](https://github.com/doctorfree/nvim-lazyman/wiki/infodocs)" >> "${OUTF}"
  echo "" >> "${OUTF}"
  [ "${WS_URL}" ] && {
    echo "### Website" >> "${OUTF}"
    echo "" >> "${OUTF}"
    echo "[${WS_URL}](${WS_URL})" >> "${OUTF}"
    echo "" >> "${OUTF}"
  }
  [ "${GH_URL}" ] && {
    echo "### Git repository" >> "${OUTF}"
    echo "" >> "${OUTF}"
    echo "[${GH_URL}](${GH_URL})" >> "${OUTF}"
    echo "" >> "${OUTF}"
  }
  [ "${NC_URL}" ] && {
    echo "### Neovimcraft entry" >> "${OUTF}"
    echo "" >> "${OUTF}"
    echo "[${NC_URL}](${NC_URL})" >> "${OUTF}"
    echo "" >> "${OUTF}"
  }
  [ "${DF_URL}" ] && {
    echo "### Dotfyle entry" >> "${OUTF}"
    echo "" >> "${OUTF}"
    echo "[${DF_URL}](${DF_URL})" >> "${OUTF}"
    echo "" >> "${OUTF}"
  }
  get_plugins "${nvimconf}" "${OUTF}" "${PL_MAN}"
  [ "${have_pandoc}" ] && pandoc -t html -o "${HTML}" "${OUTF}"
}

all=
have_pandoc=$(type -p pandoc)
while getopts "au" flag; do
    case $flag in
        a)
            all=1
            ;;
        u)
            usage
            ;;
    esac
done
shift $(( OPTIND - 1 ))

[ "${all}" ] && {
  for conf in ${CF_NAMES}
  do
    make_info ${conf}
  done
  exit 0
}

checkdir="nvim-Lazyman"
[ "$1" ] && checkdir="$1"
conf=$(echo "${checkdir}" | sed -e "s/^nvim-//")
make_info ${conf}
