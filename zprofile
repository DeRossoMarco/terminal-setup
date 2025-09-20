# Brew path
eval "$(/opt/homebrew/bin/brew shellenv)"

# Terminal color option
export CLICOLOR=1
#export LSCOLORS="exfxcxdxbxegedabagacad"

# Ignore duplicates and blank lines in history
setopt hist_ignore_dups
setopt hist_ignore_space

# Auto correct typos in commands
setopt correct

# Alert when a job completes (usage: command; alert)
alias alert='osascript -e "display notification with title \"Command Status\" subtitle \"$(if [[ $? -eq 0 ]]; then echo Success; else echo Error; fi)\"" && afplay /System/Library/Sounds/Blow.aiff'

# User defined aliases
alias ll="ls -l"
alias cl="printf '\33c\e[3J'"
alias h="history"
alias please="sudo"

# User defined functions
ffmpeg-compress () {
    ffmpeg -i "$1" -vn -ar 44100 -ac 1 -b:a 96k "$2";
}
ffmpeg-concat () {
    for f in *."$1"; do echo "file '$f'" >> files.txt; done; 
    ffmpeg -f concat -safe 0 -i files.txt -c copy "$2";
    rm files.txt;
}
md2pdf () {
    pandoc "$1" -s -V geometry:margin=1in -o "${1%.*}.pdf";
}
mkcd () {
    mkdir -p "$1" && cd "$1";
}
