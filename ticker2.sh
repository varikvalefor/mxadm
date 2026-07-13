#!/bin/ksh

alias echo="echo -E"

set -x

kibysehu=matrix.catgirl.cloud

kumfaId_ticketSpc=$(cat $HOME/.config/modbot/xkumfaid_ticketspc)
kumfaId_oTicketSpc=$(cat $HOME/.config/modbot/xkumfaid_oticketspc)
kumfaId_jatna=$(cat $HOME/.config/modbot/xkumfaid_jatna)

accessToken=$(head -n 1 $HOME/.config/modbot/accesstoken)

alias c="curl --retry-all-errors --retry 255 -x socks5h://10.255.1.3:9050 -H Authorization:\ Bearer\ \"${accessToken}\""
#alias c="curl --retry-all-errors --retry 100 -x http://10.255.1.3:4444 -H Authorization:\ Bearer\ \"${accessToken}\""

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
	evtId=$3;
	benji=$4;
	kumfaId0=$5;

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
		c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId0/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \".i .indika lo du'u zasti fa lo me'oi .ticket. pu lo nu benji\n\nStuff indicates that that (a ticket exists) precedes sending the message.\", \"m.relates_to\": {\"m.in_reply_to\": {\"event_id\": \"$evtId\"}}, \"m.mentions\": {\"user_ids\": [\"$benji\"]}}"
		exit
	fi

	dv="{\"invite\":[\"$mxid\"], \"name\": \"$klesiX Ticket for $mxid\", \"room_version\": \"12\", \"preset\": \"private_chat\", \"additional_creators\": [\"@vvx:tchncs.de\"]}"
	echo "$dv"

	evt=$(c -X POST "https://$kibysehu/_matrix/client/v3/createRoom" -d "$dv")
	echo "$evt"
	kumfaId=$(echo "$evt" | jq -r '.room_id')

	./modbot.sh viz "$kumfaId" cotf-tik1 &
	./modbot.sh joinRules "$kumfaId" cotf-tik1 &
	./modbot.sh over9000 "$kumfaId" cotf-tik1 &

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId_ticketSpc/state/m.space.child/$kumfaId" -d "{\"suggested\": \"false\", \"via\": [\"catgirl.cloud\"]}" &
	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId_oTicketSpc/state/m.space.child/$kumfaId" -d "{\"suggested\": \"false\", \"via\": [\"catgirl.cloud\"]}" &

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId_jatna/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \"new ($klesi ticket) for $mxid\nhttps://matrix.to/#/$kumfaId?via=catgirl.cloud\\ncotfNewTicketKeyword\"}" &

	if [ "$klesiX" = "Verification" ]
	then
		echo "$mxid" >> $HOME/.config/modbot/vrici-veritas
	fi

	wait

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId0/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \".i .indika lo du'u snada joi lo du'u benji lo vi'ecpe notci pe lo me'oi .ticket. ke tavla kumfa pe'a  .i la .varik. cu djica curmi lo nu cusku fi vo'a fe lo se du'u na snada kei kei vo'a kei va'o lo nu na snada  .i la .varik. ci ci'au xo'o nai la'e di'u\n\nStuff indicates that the thing is successful, and an invite message for the ticket chatroom is sent.  In the event of failure, VARIK welcomes stating (to VARIK) that the thing is unsuccessful. to VARIK.  VARIK sincerely writes the preceding sentence.\", \"m.relates_to\": {\"m.in_reply_to\": {\"event_id\": \"$evtId\"}}, \"m.mentions\": {\"user_ids\": [\"$benji\"]}}"
}

function isTicketRequest {
	echo "$1" | pcregrep "^\!mxadm ticket \w+$"
}

function spuda {
	kumfaId="$1"
	evtId="$2"
	benji="$3"
	bod="$4"

	if [ "$5" = "1" ]
	then
		V="$4"
	else
		V="{\"msgtype\": \"m.text\", \"body\": \"$bod\"}"

	fi

	V=$(echo "$V" | jq ".\"m.relates_to\".\"m.in_reply_to\".event_id = \"$evtId\" | .\"m.mentions\".user_ids = [\"$benji\"]")

	c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "$V"
}

function slowmode {
        msg=$1
	benji=$(echo "$msg" | jq '.sender')
	kumfaId=$(echo "$msg" | jq '.roomid')
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

function powerLevel {
	pilnoId=$1
	x=$(grep ^"$pilnoId " "$HOME/.config/modbot/pwrlv_cotf-jatna1" | cut -f 2 -d\ )
	if [ "$x" ]; then echo "$x"; else echo "0"; fi
}

function isModerator {
	pilnoId=$1

	[ "$(powerLevel \"$pilnoId\")" -ge 50 ]
}

function isPrivilegedUser {
	pilnoId=$1
	[ "$(powerLevel \"$pilnoId\")" -gt 0 ]
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
		kumfaId=$(echo -E "$i" | jq -r '.roomid')
		klesi=$(echo "$i" | jq -r '.type')
		evtId=$(echo "$i" | jq -rc '.event_id')
		benji=$(echo "$i" | jq -rc '.sender')
		echo -E "$kumfaId"

		#slowmode "$i"

		if echo "$kumfaId" | pcregrep '^\!(1_lk3HyvX3yeRwbGRyDNzsw6efoN6yoGJRk_YFUCrjo|utnlbJeRBwvqLUFltM:matrix.org|AI8S21lU11g8rZLtN7IAJmI52017iSOljVkdiQriDHs)$'
		then
			echo "test pass"
			if isTicketRequest "$bod"
			then
				klesi=$(echo -E "$bod" | sed -e 's/^.* //g');
				mxid=$(echo "$i" | jq -r '.sender')
				evtId=$(echo "$i" | jq -r '.event_id')
				benji=$(echo "$i" | jq -r '.sender')
				mkTik "$klesi" "$mxid" "$evtId" "$benji" "$kumfaId" &
			elif echo "$bod" | pcregrep '^\!mxadm (divinationbyquote|hoot)$'
			then
				glutamate=$(/usr/games/fortune quot | jq -R)
				spuda "$kumfaId" "$evtId" "$benji" "$glutamate"
			elif [ "$bod" = "!mxadm help" ]
			then
				notci="!mxadm help - displays commands\\n!mxadm ticket moderator - creates moderator ticket\\n!mxadm ticket verify - creates verification ticket\\n!mxadm ticket incident - creates incident ticket\\n!mxadm divinationbyquote - outputs quote from varik's quote list\\n!mxadm hoot - ditto\\n!mxadm [secret] - easter eggs and whatnot\\n\\n.i la .varik. cu kajde fi zo'e joi le su'u le proga cu co'e ja tolmapti lo se stika pe'a je notci... je cu milxe le ka ce'u masno\\n\\nVARIK cautions.  The bot is incompatible/whatever with messages which are \\\"edited\\\".  Additionally, the bot is somewhat slow."
				spuda "$kumfaId" "$evtId" "$benji" "$notci"
			elif echo "$bod" | pcregrep '^!mxadm ping$'
			then
				set -x
				spuda "$kumfaId" "$evtId" "$benji" "pong"
			elif echo "$bod" | pcregrep '^!mxadm flush$'
			then
				set -x
				spuda "$kumfaId" "$evtId" "$benji" "Your business is appreciated."
			fi
		fi
		if echo "$klesi" | pcregrep "m\\.room\\.redaction" # .i la'oi .[. smimlu fi le ka ce'u co'e ja tolmapti  .i na jimpe fa la .varik.
		then
			set -x
			notciId=$(echo "$i" | jq -rc '.content.redacts')
			V=$(cat $HOME/.syncs/* | jq ".value.timeline.events[] += {room_id: .key} | .value.timeline.events[] | select(.event_id == \"$notciId\")") #base64 | perl -0777pe 's/\s//g')
			if [ "$V" ]
			then
				D=$(echo "$i" | jq)
				V=$(jq -n --arg var "$V" --arg dvar "$D" "{\"msgtype\": \"m.text\", \"body\": \"ni'o vimcu pe'a ko'a goi lo notci  .i ku'i benji le velcki be ko'a\n\nA message is \\\"deleted\\\".  But the definition of the event is sent.\n\n\" + \$var + \"\n\n\" + \$dvar }")
				c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/!z9OfPbvrq1riCqwxqIQ9QEdttteNjSFTDswwneMEphE/send/m.room.message/$(guido 32)" -d "$V"
			fi
		elif (echo "$bod" | grep -i 'sounds like a lot of$')
		then
			spuda "$kumfaId" "$evtId" "$benji" "HOOPLA!"
		elif [ "$bod" = "!mxadm slowmode enable" ] && isModerator "$(echo -E \"$i\" | jq -r '.sender')"
		then
			mkdir -p "$HOME/.config/modbot/slowmode/"
			echo "$kumfaId" > "$HOME/.config/modbot/slowmode/enabled"
			notci="ni'o tolcru lo nu sutra benji lo notci  .i .aktigau le me'oi .slowmode. co'e\n\nQuickly sending messages is forbidden.  The slowmode thing is enabled."
			spuda "$kumfaId" "$evtId" "$benji" "$notci"
		elif [ "$bod" = "!mxadm slowmode disable" ]; then if isModerator "$(echo \"$i\" | jq -r '.sender')"
		then
			mkdir -p "$HOME/.config/mxadm/modbot/slowmode/"
			foo=$(cat "$HOME/.config/modbot/slowmode/enabled" | grep -v "kumfaId")
			echo "$foo" > "$HOME/.config/modbot/slowmode/enabled"
			notci="ni'o curmi lo nu sutra benji lo notci  .i to'e .aktigau le me'oi .slowmode. co'e\n\nQuickly sending messages is permitted.  The slowmode thing is disabled."
			spuda "$kumfaId" "$evtId" "$benji" "$notci"
		fi # isModerator
		elif [ "$bod" = "!mxadm brick" ]
		then
			spuda "$kumfaId" "$evtId" "$benji" "$(cat brick)" 1
		elif echo "$bod" | pcregrep '^\!mxadm yesreallyban @.*:[^\s]+ \w.*$'
		then
			mxid=$(echo "$bod" | cut -f 3 -d\ )
			krinu=$(echo "$bod" | perl -pe 's/^\!mxadm yesreallyban [^\s]+[\s]//')
			plb=$(powerLevel "$benji")
			plm=$(powerLevel "$mxid")

			if ! (isModerator "$benji" && [ "$plb" -gt "$plm" ])
			then
				c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/send/m.room.message/$(guido 32)" -d "{\"msgtype\": \"m.text\", \"body\": \".i rivyzu'e pe'a\\n\\nThe thing is \\\"refused\\\".\", \"m.relates_to\": {\"m.in_reply_to\": {\"event_id\": \"$evtId\"}}, \"m.mentions\": {\"user_ids\": [\"$benji\"]}}"
			else
				if [ "$krinu" ] # echo "$bod" | pcregrep '^!yesreallyban @.+*:[^\s]+\s+[^\s]'
				then
					spuda "$kumfaId" "$evtId" "$benji" ".i zoi zoi. !mxadm yesreallyunban .zoi. jai fili'a lo nu xruti... pe'a\\n\\n\\\"!mxadm yesreallyunban\\\" facilitates \\\"reverting\\\"."
	
					for kumfaKlesi in $(ls -1 $HOME/.config/modbot/kumfaid_cotf-* | grep -o 'cotf-.*$'); do
						./modbot.sh blam "$mxid" "$krinu" "$kumfaKlesi" &
					done
				else
					spuda "$kumfaId" "$evtId" "$benji" ".i co'e ja djica lo nu cusku lo se du'u ma kau krinu\\n\\nExplaining the reason is desired/whatever."
				fi
			fi
		elif echo "$bod" | pcregrep '^\!mxadm yesreallyunban @.*:[^\s]+ \w.*$'
		then
			mxid=$(echo "$bod" | cut -f 3 -d\ )
			krinu=$(echo "$bod" | perl -pe 's/^\!mxadm yesreallyban [^\s]+[\s]//')
			#plb=$(powerLevel "$benji")
			#plm=$(powerLevel "$mxid")

			if ! (isModerator "$benji") # && [ "$plb" -gt "$plm" ])
			then
				spuda "$kumfaId" "$evtId" "$benji" ".i rivyzu'e pe'a\\n\\nThe thing is \\\"refused\\\"."
			else
				if [ "$krinu" ] # echo "$bod" | pcregrep '^!yesreallyban @.+*:[^\s]+\s+[^\s]'
				then
					spuda "$kumfaId" "$evtId" "$benji" "Yeehaw!"
					for kumfaKlesi in $(ls -1 $HOME/.config/modbot/kumfaid_cotf-* | grep -o 'cotf-.*$'); do
						./modbot.sh deblam "$mxid" "$krinu" "$kumfaKlesi" &
					done
				else
					spuda "$kumfaId" "$evtId" "$benji" ".i co'e ja djica lo nu cusku lo se du'u ma kau krinu\\n\\nExplaining the reason is desired/whatever."
				fi
			fi
		fi
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
