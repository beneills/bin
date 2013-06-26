#!/bin/bash

#
# Keep the screen blanked, except in periods of user input
# timeout of 0s still results in ~20 seconds to true blanking, but hey...
#

XSCREENSAVER_CONFIG=~/.xscreensaver


function restart_xscreensaver {
	 echo "Restarting xscreensaver"
	 killall -q xscreensaver
	 xscreensaver -no-splash &
}


echo "Backing up current xscreensaver config"
echo "Reconfiguring to query mode"
sed -i'.backup' \
    -e 's/^timeout:	*[0-9]*:[0-9]*:[0-9]*$/timeout:	0:00:00/' \
    -e 's/^fade:	*True$/fade:	False/' \
    "$XSCREENSAVER_CONFIG"

restart_xscreensaver

echo "Press [enter] when done"
read

echo "Reverting to previous config"
mv  "$XSCREENSAVER_CONFIG".backup "$XSCREENSAVER_CONFIG"

restart_xscreensaver

