set -x

kibysehu=matrix.catgirl.cloud

accessToken=$(head -n 1 $HOME/.config/modbot/accesstoken)
kumfaId="$(cat ~/prgs/kumfaid)"

echo $accessToken

alias c="curl --socks5 127.0.0.1:9050 -H 'Authorization: Bearer $accessToken'"

function evtId {
	evtId=$(c "https://$kibysehu/_matrix/client/v3/rooms/$1/state")
	evtId=$(echo $evtId | jq '.[] | select(.type == "m.room.power_levels") | .event_id')
}

function ningau {
	kumfaId="$1"
	evtx=$(c "https://$kibysehu/_matrix/client/v3/rooms/$1/state")
	echo "$evtx"
	evt=$(echo "$evtx" | jq '.[] | select(.type == "m.room.power_levels")') || echo "shit"
	zbas=$(echo "$evtx" | jq '.[] | select(.type == "m.room.create") | .sender')
	versiio=$(echo "$evtx" | jq '.[] | select(.type == "m.room.create") | .room_version')
	evtId="$(echo "$evt" | jq '.event_id')"

	pilnoLv={$(cat ~/prgs/pwrlv_1 | perl -pe 's/^([^\s]*)/"\1":/; s/$/,/' | grep -v "$zbas" | sed -e '$s/,//')}

	# ni'o lo so'i versiio co'e na mapti tu'a lo barda je mu'oi glibau. power level .glibau.
	# .i fanta lo nu samfli
	if [ $versiio -lt 12 ]
	then
		pilnoLv=$(echo "$pilnoLv" | jq 'map_values(if . > 100 then 100 else . end)')
	fi

	# debug crap
	echo $pilnoLv

	evt2=$(echo "$evt" | jq ".users |= $pilnoLv | del(.event_id,.room_id,.origin_server_ts,.sender)")
	echo "$evt2" #| jq '.content.users'

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/state/m.room.power_levels" -d "$evt2"

}

for i in $(cat ~/prgs/kumfaid)
do
	ningau $i
done
