alias ls='ls -a'
alias ll='ls -al'
alias vi='vim'
alias gimp_resize_images="/Applications/GIMP.app/Contents/MacOS/GIMP -i -b '(batch-resize-image \"*.*\")' -b '(gimp-quit 0)'"
alias unlock='xattr -d com.apple.quarantine ${1}'
alias rake-no-warn='rake 2>&1 | grep -v "warning:"'
alias git-config-mmcrockett='git config --local user.email "github@mmcrockett.com"'
alias git-commit-wip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -m "--wip--"'
alias git-commit-wip-no-hooks='git-commit-wip -n'
alias ssh-add-hour='ssh-add -t 1H'
alias ssh-add-day='ssh-add -t 1D'
alias ssh-add-week='ssh-add -t 1W'
alias rails-changed-tests-ff='rails-changed-tests --fail-fast'
alias rails-test-ff='rails test --fail-fast'
alias chrome-allow-cors="open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security"
alias chrome-allow-cors='/usr/bin/google-chrome-stable --args --disable-web-security --user-data-dir=/tmp/chrome_dev_test'
alias mvim='gvim'
alias pbcopy='xsel --primary'
alias increase-fd='sudo sysctl -w fs.inotify.max_user_watches=20000 && sudo sysctl -p'

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
