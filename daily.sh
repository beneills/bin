#
# Daily tasks, to be run before emacs, browser, etc. start
#

genplan.rb # prerequisite for emacs
beemem.rb &
beeplan.rb &

YESTERDAY_PLAN=~/plans/`date --date="yesterday" +%F`.org
if grep --quiet --ignore-case "DONE morning teeth" $YESTERDAY_PLAN \
    && grep --quiet --ignore-case "DONE evening teeth" $YESTERDAY_PLAN; then
    beemind teeth 1 "added by daily.sh"
fi
