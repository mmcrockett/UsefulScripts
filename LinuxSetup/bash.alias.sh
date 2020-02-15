alias ls='ls -a'
alias ll='ls -al'
alias vi='vim'
alias gimp_resize_images="/Applications/GIMP.app/Contents/MacOS/GIMP -i -b '(batch-resize-image \"*.*\")' -b '(gimp-quit 0)'"
alias unlock='xattr -d com.apple.quarantine ${1}'
alias rake-no-warn='rake 2>&1 | grep -v "warning:"'
alias git-config-mmcrockett='git config --local user.email "github@mmcrockett.com"'
alias git-commit-wip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify -m "--wip--"'

function create-find-grep-aliases {
  local FILE_ENDINGS=(
    rb
    js
    html
  )
  local FILE_ENDING=""

  for FILE_ENDING in "${FILE_ENDINGS[@]}"; do
    alias find-grep-${FILE_ENDING}="find-grep -n '*.${FILE_ENDING}'"
  done
}

create-find-grep-aliases
