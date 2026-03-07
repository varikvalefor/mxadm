#!/bin/ksh

set -x

kibysehu=matrix.catgirl.cloud

accessToken=$(head -n 1 $HOME/.config/modbot/accesstoken)

alias c="curl --socks5 127.0.0.1:9050 -H Authorization:\ Bearer\ \"${accessToken}\""

function vlipaCohe {
	i=$1
	kumfaId="$2"
	evtx=$(c "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/state")
	evt=$(echo "$evtx" | jq '.[] | select(.type == "m.room.power_levels")')
	zbas=$(echo "$evtx" | jq '.[] | select(.type == "m.room.create") | .sender')
	versiio=$(echo "$evtx" | jq '.[] | select(.type == "m.room.create") | .content.room_version | tonumber')
	evtId="$(echo "$evt" | jq '.event_id')"

	pilnoLv="{$(cat $HOME/.config/modbot/pwrlv_$1 | perl -pe 's/^([^\s]*)/"\1":/; s/$/,/' | sed -e '$s/,//')}"

	# ni'o lo so'i versiio co'e na mapti tu'a lo barda je mu'oi glibau. power level .glibau.
	# .i fanta lo nu samfli
	if [ $versiio -lt 12 ]
	then
		pilnoLv=$(echo "$pilnoLv" | jq "map_values(if . > 100 then 100 else . end)")
	else
		pilnoLv=$(echo "$pilnoLv" | jq "del(.$zbas)")
	fi

	evt2=$(echo "$evt" | jq ".users |= $pilnoLv | .content.users |= $pilnoLv | del(.event_id,.room_id,.origin_server_ts,.sender) | del(.unsigned,.prev_content)")

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/state/m.room.power_levels" -d "$evt2"
}

function over9000 {
	for i in $(ls -1 $HOME/.config/modbot/kumfaid* | perl -pe 's/^.*_(\d+)$/\1/' | grep '^[0-9]*$')
	do
		for j in $(cat $HOME/.config/modbot/kumfaid_$i)
		do
			vlipaCohe $i $j
		done
	done
}

function blam {
	plicme=$1
	krinu=$(echo $2 | sed -e 's/"/\\"/g')
	bd="{\"user_id\": \"$plicme\", \"reason\": \"$krinu\"}"

	for i in $(echo $3 | sed -e 's/,/ /g')
	do
		for kumfaId in $(cat $HOME/.config/modbot/kumfaid_$i)
		do
			c -X POST "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/ban" -d "$bd"
		done
	done
}

function deblam {
	plicme=$1
	krinu=$(echo $2 | sed -e 's/"/\\"/g')
	dbd="{\"user_id\": \"$plicme\", \"reason\": \"$krinu\"}"

	for i in $(echo $3 | sed -e 's/,/ /g')
	do
		for kumfaId in $(cat $HOME/.config/modbot/kumfaid_$i)
		do
			c -X POST "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/unban" -d "$dbd"
		done
	done
}

case "$1" in
	blam)	blam $2 $3 $4;;
	deblam)	deblam $2 $3 $4;;
	over9000)	over9000;;
	?)	exit
esac
