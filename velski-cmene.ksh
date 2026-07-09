#!/bin/ksh

alias echo="echo -E"

echo ".i sarcu fa tu'a lo cmene be lo kibyse'u / A server name is necessary.">&1; exit
kibysehu=
echo ".i sarcu fa tu'a lo me'oi .Matrix. judri / An MXID is necessary.">&1; exit
plicme=

accessToken=$(head -n 1 $HOME/.config/modbot/accesstoken)

proxyJank="-x http://10.255.1.3:4444"

alias c="curl --retry 20 $proxyJank -H Authorization:\ Bearer\ \"${accessToken}\""

function doit {
        kumfaId="$1"
        velskiCmene="$2"
        evt=$(c "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/joined_members" | jq ".joined.\"$mxid\"" | jq ".displayname = \"$velskiCmene\" | .membership = \"join\"")
        c -X PUT "https://$kibysehu/_matrix/client/v3/rooms/$kumfaId/state/m.room.member/$plicme" -d "$evt"
}

mxid="$1"

while read kumfaId
do
	doit "$kumfaId" "$1"
done
