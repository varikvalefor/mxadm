#!/bin/ksh

alias echo="echo -E"

set -x

kibysehu=matrix.catgirl.cloud

kumfaId_ticketSpc=$(cat $HOME/.config/modbot/xkumfaid_ticketspc)
kumfaId_oTicketSpc=$(cat $HOME/.config/modbot/xkumfaid_oticketspc)
kumfaId_jatna=$(cat $HOME/.config/modbot/xkumfaid_jatna)

accessToken=$(head -n 1 $HOME/.config/modbot/accesstoken)

#alias c="curl --retry 100 -x socks5h://10.255.1.3:9050 -H Authorization:\ Bearer\ \"${accessToken}\""
alias c="curl --retry 100 -x http://10.255.1.3:4444 -H Authorization:\ Bearer\ \"${accessToken}\""

function guido {
        # | ni'o pilno ko'a goi la'o zoi. dd(1) .zoi. ki'u le
        # su'u ko'a me'oi .lazy.
        tr -dc A-Za-z0-9 < /dev/random | dd if=/dev/stdin of=/dev/stdout bs=1 "count=$1" status=none;
        echo "";
}

function SYNC {
	set -x

	SINCE=$(cat ~/.config/modbot/since1)
	#evt=$(c "https://matrix.catgirl.cloud/_matrix/client/v3/sync?filter=4&since=$SINCE")
	evt=$(c "https://matrix.catgirl.cloud/_matrix/client/v3/sync?filter=8&since=$SINCE")
	nb=$(echo "$evt" | jq -r '.next_batch')
	if [ "$nb" ]
	then
		echo $nb > ~/.config/modbot/since1
	fi
	echo "$evt"
}

function syncRq {
	set -x
	SYNC |\
		jq -c '.rooms.join | to_entries[]' | tee "$HOME/.syncs/$(date +%Y%m%d%H%M%S).sync" | jq -cr '.value.timeline.events[] += {roomid: .key} | .value.timeline.events[] | . += {body: .content.body}';
}

function mkTik {
	set -x
	#set -e

	klesi=$1;
	mxid=$2;

	if [ "$klesi" = "verify" ]
	then
		klesiX="Verification"
	elif [ "$klesi" = "incident" ]
	then	
		klesiX="Incident"
	else
		klesiX="Moderator"
	fi

	if (grep "^$mxid\$" $HOME/.config/modbot/vrici-veritas && [ "$klesiX" = "Verification" ])
	then
		exit
	fi

	dv="{\"invite\":[\"$mxid\"], \"name\": \"$klesiX Ticket for $mxid\", \"room_version\": \"12\", \"preset\": \"private_chat\", \"additional_creators\": [\"@vvx:tchncs.de\"]}"
	echo "$dv"

	evt=$(c -X POST "https://$kibysehu/_matrix/client/v3/createRoom" -d "$dv")
	echo "$evt"
	kumfaId=$(echo "$evt" | jq -r '.room_id')

	./modbot.sh viz "$kumfaId" cotf-tik1
	./modbot.sh joinRules "$kumfaId" cotf-tik1
	./modbot.sh over9000 "$kumfaId" cotf-tik1

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId_ticketSpc/state/m.space.child/$kumfaId" -d "{\"suggested\": \"false\", \"via\": [\"catgirl.cloud\"]}"
	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId_oTicketSpc/state/m.space.child/$kumfaId" -d "{\"suggested\": \"false\", \"via\": [\"catgirl.cloud\"]}"

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId_jatna/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \"new ($klesi ticket) for $mxid\nhttps://matrix.to/#/$kumfaId?via=catgirl.cloud\\ncotfNewTicketKeyword\"}"

	if [ "$klesiX" = "Verification" ]
	then
		echo "$mxid" >> $HOME/.config/modbot/vrici-veritas
	fi
}

function isTicketRequest {
	echo "$1" | pcregrep "^\!mxadm ticket \w+$"
}

function slowmode {
        msg=$1
	benji=$(echo "$msg" | jq '.sender')
	kumfaId=$(echo "$msg" | jq '.room_id')
	#kumfaId=$(echo "$msg" | jq '.origin_server_ts')

        if (isPrivilegedUser "$(echo \"$msg\" | jq '.sender')")
        then
		:;
	else
		klesi=$(grep -r "$kumfaId" $HOME/.config/modbot/kumfaid_* | pcregrep "(zanru|gubni|cipra|makcu|jatna|sivni)" | head -n 1 | sed -e 's/:.*$//;s/^.*-//')
		if [ -e "$HOME/.config/modbot/pwrlvl_$(echo "$kumfaId" | sha256)" ]
		then
			:;
		else
			cp $HOME/.config/modbot/pwrlvl_$klesi $HOME/.config/modbot/pwrlvl_$(echo "$kumfaId" | sha256)
			cp $HOME/.config/modbot/pwrlv_$klesi $HOME/.config/modbot/pwrlv_$(echo "$kumfaId" | sha256)
		fi

		if [ $(($(date +%s) * 1000 + 300 * 1000)) -le $timestamp ]
		then
			echo "$benji $kumfaId $timestamp" > "$HOME/.config/modbot/slowmode/$kumfaId"
			echo "$benji -1" > $HOME/.config/modbot/slowmode/pwrlv_$(echo "$kumfaId" | sha256)
		fi

		./modbot.sh over9000 "$kumfaId" "$(echo \"$kumfaId\" | sha256)"
        fi
}

function isModerator {
	pilnoId=$1

	[ $(grep "$pilnoId" "$HOME/.config/modbot/pwrlv_cotf-jatna1" | cut -f 2 -d\ ) -gt 50 ]
}

function isPrivilegedUser {
	pilnoId=$1

	[ $(grep "$pilnoId" "$HOME/.config/modbot/pwrlv_cotf-jatna1" | cut -f 2 -d\ ) -gt 0 ]
}

function slowmodeReset {
	kumfaId="$1"
	cur=$(($(date +%s) * 1000))
	
	cat "$HOME/.config/mxadm/modbot/slowmode/enabled" |\
	while read kumfaId
	do
		benji=$(cat "$HOME/.config/modbot/slowmode/$kumfaId" | cut -f 1 -d\ )
		namcu=$(cat "$HOME/.config/modbot/slowmode/$kumfaId" | cut -f 3 -d\ )

		if [ $cur -ge $((namcu + 300)) ]
		then
			foo=$(cat $HOME/.config/modbot/pwrlv_$(echo "$kumfaId" | sha256) | grep -v "$benji")
			echo "$foo" > $HOME/.config/modbot/pwrlv_$(echo "$kumfaId" | sha256)

			./modbot.sh over9000 "$kumfaId" "$(echo "$kumfaId" | sha256)"
		fi
			
	done
}

function lupe {
	set -x

	sort -u | while read i
	do
		echo -E "$i"

		set -x
		bod=$(echo -E "$i" | jq -r '.body')
		kumfaId=$(echo -E "$i" | jq '.roomid')
		klesi=$(echo "$i" | jq '.type')

		#slowmode "$i"

		if true # [ "$kumfaId" = "!1_lk3HyvX3yeRwbGRyDNzsw6efoN6yoGJRk_YFUCrjo" ] || [ "$kumfaId" = "!utnlbJeRBwvqLUFltM:matrix.org" ]
		then
		echo "test pass"
		if isTicketRequest "$bod"
		then
			klesi=$(echo -E "$bod" | sed -e 's/^.* //g');
			mxid=$(echo "$i" | jq -r '.sender')
			mkTik "$klesi" "$mxid";
		elif echo "$klesi" | pcregrep "m\\.room\\.redaction" # .i la'oi .[. smimlu fi le ka ce'u co'e ja tolmapti  .i na jimpe fa la .varik.
		then
			set -x
			notciId=$(echo "$i" | jq -rc '.content.redacts')
			V=$(cat $HOME/.syncs/* | jq ".value.timeline.events[] | select(.event_id == \"$notciId\")") #base64 | perl -0777pe 's/\s//g')
			if [ "$V" ]
			then
				V=$(jq -n --arg var "$V" "{\"msgtype\": \"m.text\", \"body\": \"ni'o vimcu pe'a lo notci  .i ku'i benji le velcki be le notci\n\nA message is \\\"deleted\\\".  But the definition of the event is sent.\n\n\" + \$var }")
				c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/!z9OfPbvrq1riCqwxqIQ9QEdttteNjSFTDswwneMEphE/send/m.room.message/$(guido 32)" -d "$V"
			fi
		fi
		elif (echo "$bod" | grep -i 'sounds like a lot of$')
		then
			c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \"HOOPLA!\"}"
		elif [ "$bod" = "!mxadm help" ]
		then
			kumfaId=$(echo "$i" | jq -r '.roomid')
			notci="!mxadm help - displays commands\\n!mxadm ticket moderator - creates moderator ticket\\n!mxadm ticket verify - creates verification ticket\\n!mxadm ticket incident - creates incident ticket\\n!mxadm divinationbyquote - outputs quote from varik's quote list\\n!mxadm [secret] - easter eggs and whatnot\\n\\n.i la .varik. cu kajde fi zo'e joi le su'u le proga cu co'e ja tolmapti lo se stika pe'a je notci... je cu milxe le ka ce'u masno\\n\\nVARIK cautions.  The bot is incompatible/whatever with messages which are \\\"edited\\\".  Additionally, the bot is somewhat slow."
			c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \"$notci\"}"
		elif [ "$bod" = "!mxadm slowmode enable" ]; then if isModerator "$(echo -E $i | jq -r '.sender')"
		then
			kumfaId=$(echo "$i" | jq -r '.roomid')
			mkdir -p "$HOME/.config/modbot/slowmode/"
			echo "$kumfaId" > "$HOME/.config/modbot/slowmode/enabled"
			notci="ni'o tolcru lo nu sutra benji lo notci  .i .aktigau le me'oi .slowmode. co'e\n\nQuickly sending messages is forbidden.  The slowmode thing is enabled."
			c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \"$notci\"}"
		fi # isModerator
		elif [ "$bod" = "!mxadm slowmode disable" ]; then if isModerator "$(echo \"$i\" | jq -r '.sender')"
		then
			kumfaId=$(echo "$i" | jq -r '.roomid')
			mkdir -p "$HOME/.config/mxadm/modbot/slowmode/"
			foo=$(cat "$HOME/.config/modbot/slowmode/enabled" | grep -v "kumfaId")
			echo "$foo" > "$HOME/.config/modbot/slowmode/enabled"
			notci="ni'o curmi lo nu sutra benji lo notci  .i to'e .aktigau le me'oi .slowmode. co'e\n\nQuickly sending messages is permitted.  The slowmode thing is disabled."
			c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \"$notci\"}"
		fi # isModerator
		elif [ "$bod" = "!mxadm brick" ]
		then
			kumfaId=$(echo "$i" | jq -r '.roomid')
			c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "$(cat brick)"
		elif [ "$bod" = "!mxadm divinationbyquote" ]
		then
			kumfaId=$(echo "$i" | jq -r '.roomid')
			glutamate=$(/usr/games/fortune quot | jq -R)
			c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": $glutamate}"
#		elif echo "$bod" | pcregrep '^!yesreallyban @.+*:[^\s]+'
#		then
#			if echo "$bod" | pcregrep '^!yesreallyban @.+*:[^\s]+\s+[^\s]'
#			then
#				c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": .i zoi zoi. !yesreallyunban .zoi. jai fili'a lo nu xruti... pe'a\\n\\n\\\"!unban\\\" facilitates \\\"reverting\\\".\"}"
#				mxid=$(echo "$bod" | pcregrep -o '@.+*:[^\s]+$')
#				krinu=$(echo "$bod" | perl -pe 's/^[^\s]+ [^\s]+\s+//')
#
#				for jl in $(ls -l $HOME/.config/modbot/pwrlv_cotf-*)
#				do
#					./modbot blam "$mxid" "$krinu" "$jl"
#				done
#			else
#				c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": .i co'e ja djica lo nu cpedu lo se du'u ma kau krinu\\n\\nExplaining the reason is desired/whatever.\"}"
#			fi
#		fi
		fi # kumfaId
	done
}

function mane {
	set -x

	while true
	do
		syncRq | lupe;

		cat "$HOME/.config/modbot/slowmode/enabled" | \
		#while read fuck
		#do
			#slowmodeReset "fuck";
		#done

		sleep 30;
	done
}

mane
