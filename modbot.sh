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

	pilnoLv="{$(cat $HOME/.config/modbot/pwrlv_$i | perl -pe 's/^([^\s]*)/"\1":/; s/$/,/' | sed -e '$s/,//')}"

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

# | ni'o mapti lo nu jostolcru je lo nu xruti pe'a
function rblam {
	plicme=$1
	krinu=$(echo $2 | sed -e 's/"/\\"/g')
	if [ $4 = 1 ]
	then
		lidne="un"
	fi

	bd="{\"user_id\": \"$plicme\", \"reason\": \"$krinu\"}"

	for i in $3
	do
		for kumfaId in $(cat $HOME/.config/modbot/kumfaid_$i)
		do
			c -X POST "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/${lidne}ban" -d "$bd"
		done
	done
}

function viz {
	for i in $1
	do
		n=$(cat $HOME/.config/modbot/viz_$1)

		vd="{\"history_visibility\":\"$n\"}"

		for kumfaId in $(cat $HOME/.config/modbot/kumfaid_$i)
		do
			echo $vd
			c -X PUT "https://$kibysehu//_matrix/client/v3/rooms/$kumfaId/state/m.room.history_visibility/" -d "$vd"
		done
	done
}

function joinRules {
	for i in $1
	do
		vd=$(cat ~/.config/modbot/joinrules_$i | sed -e 's/^/{"room_id": "/' | sed -e 's/$/", "type": "m.room_membership"}/' | jq -s)
		vd="{\"allow\": $vd, \"join_rule\": \"restricted\"}"
		for kumfaId in $(cat $HOME/.config/modbot/kumfaid_$i)
		do
			c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/state/m.room.join_rules/" --data-raw "$vd"
		done
	done
}

case "$1" in
	blam)	rblam $2 "$3" "$4" 0;;
	deblam)	rblam $2 "$3" "$4" 1;;
	over9000)	over9000;;
	viz)	viz "$2";;
	joinRules)	joinRules "$2";;
	?)	exit
esac
