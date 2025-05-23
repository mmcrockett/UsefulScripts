alias ls='ls -a'
alias ll='ls -al'
alias vi='vim'
alias gimp_resize_images="/Applications/GIMP.app/Contents/MacOS/GIMP -i -b '(batch-resize-image \"*.*\")' -b '(gimp-quit 0)'"
alias unlock='xattr -d com.apple.quarantine ${1}'
alias rake-no-warn='rake 2>&1 | grep -v "warning:"'
alias ssh-add-hour='ssh-add -t 1H'
alias ssh-add-day='ssh-add -t 1D'
alias ssh-add-week='ssh-add -t 1W'
alias rails-changed-tests-ff='rails-changed-tests --fail-fast'
alias rails-test-ff='rails test --fail-fast'
alias chrome-allow-cors="open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security"
alias chrome-allow-cors='/usr/bin/google-chrome-stable --args --disable-web-security --user-data-dir=/tmp/chrome_dev_test'
alias mvim='gvim'

if [ -z "$(isMac)" ]; then
  alias pbcopy='xsel --primary'
fi

alias increase-fd='sudo sysctl -w fs.inotify.max_user_watches=20000 && sudo sysctl -p'
alias bluebg="echo -ne '\e]11;#111140\e\\'"
alias greybg="echo -ne '\e]11;#333340\e\\'"
alias ssh-dh-compute="ssh -i ${HOME}/.ssh/dreamcomputeserverpw debian@208.113.128.139"

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
