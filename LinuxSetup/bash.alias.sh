alias ls='ls -a'
alias ll='ls -al'
alias vi='vim'
alias gimp_resize_images="/Applications/GIMP.app/Contents/MacOS/GIMP -i -b '(batch-resize-image \"*.*\")' -b '(gimp-quit 0)'"
alias unlock='xattr -d com.apple.quarantine ${1}'
alias move-podcasts='rsync -avz --remove-source-files hyperlvs71.qa.paypal.com:~/Downloads/*.mp3 ~/Downloads/'
alias rake-no-error-out='rake 2> /dev/null'
alias git-config-mmcrockett='git config --local user.email "github@mmcrockett.com"'
alias mvim='mvim --servername $(basename ${PWD}) --remote-silent'
alias mvim-no-opts='/usr/local/bin/mvim'

function create-find-grep-aliases {
  local FILE_ENDINGS=(
    rb
    js
    html
  )

  for FILE_ENDING in "${FILE_ENDINGS[@]}"; do
    alias find-grep-${FILE_ENDING}='find-grep -n "*.${FILE_ENDING}"'
  done
}

create-find-grep-aliases
