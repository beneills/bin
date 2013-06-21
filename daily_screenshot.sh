#!/bin/zsh

cd /tmp

format="%Y-%m-%d_%H-%M_$(hostname).jpg"
exec="mv \$f $HOME/backup/dailys/"

if [[ $(pidof X) -gt 0 ]]; then
  DISPLAY=:0.0 scrot -m $format -q 30 -e "$exec"
fi
