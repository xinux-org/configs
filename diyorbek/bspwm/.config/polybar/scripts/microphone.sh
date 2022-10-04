DEFAULT_SOURCE=$(pactl info | grep "Default Source" | cut -f3 -d" ")

status () {
	VOLUME=$(pactl list sources | grep -A 10 $DEFAULT_SOURCE | grep Volume -m 1 | awk -F/ '{print $2}')
	MUTED=$(pactl list sources | grep -A 10 $DEFAULT_SOURCE | grep Mute | cut -f 2 | cut -c 7-)

	if [ $MUTED = "yes" ]
	then
		echo "%{F#707880} $VOLUME"
	else
		echo " $VOLUME"
	fi
}

case $1 in
	"--toggle") pactl set-source-mute @DEFAULT_SOURCE@ toggle
	;;
	"--increase") pactl set-source-volume @DEFAULT_SOURCE@ +5%
	;;
	"--decrease") pactl set-source-volume @DEFAULT_SOURCE@ -5%
	;;
	*) status
esac
