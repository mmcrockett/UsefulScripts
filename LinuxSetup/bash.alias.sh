alias ls='ls -a'
alias ll='ls -al'
alias vi='vim'
alias gimp_resize_images="/Applications/GIMP.app/Contents/MacOS/GIMP -i -b '(batch-resize-image \"*.*\")' -b '(gimp-quit 0)'"
alias dhretrieve='s3cmd sync s3://b137124-20150708-backups/ ~/DreamObjects/'
alias dhbackup='s3cmd sync $1 --exclude "*.log" --rexclude "^\." --rexclude "\/\." ~/DreamObjects/ s3://b137124-20150708-backups/'
alias unlock='xattr -d com.apple.quarantine ${1}'
alias git-rm-merged-local-branches='git branch --merged | grep "^\s*[_]" | xargs -n 1 git branch -d'
alias move-podcasts='rsync -avz --remove-source-files hyperlvs71.qa.paypal.com:~/Downloads/*.mp3 ~/Downloads/'
alias rake-no-error-out='rake 2> /dev/null'
alias git-config-mmcrockett='git config --local user.email "github@mmcrockett.com"'
