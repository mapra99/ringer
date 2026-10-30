#!/bin/zsh
# Unit tests for the parts of ringer that don't touch the Phone app or audio devices.
# Run with: zsh test/run.zsh

emulate -R zsh
export TZ=America/Bogota
export XDG_CONFIG_HOME=$(mktemp -d) XDG_STATE_HOME=$(mktemp -d)
RINGER_SOURCE_ONLY=1 source ${0:A:h}/../bin/ringer

pass=0 fail=0
check() {
	local name=$1 expected=$2 actual=$3
	if [[ $actual == "$expected" ]]; then
		(( pass++ ))
	else
		(( fail++ ))
		print -r -- "FAIL $name: expected '$expected', got '$actual'"
	fi
}
epoch() { date -j -f '%Y-%m-%d %H:%M:%S' "$1:00" +%s }

# normalize_number
check "plain intl" "+15555550123" "$(normalize_number +15555550123)"
check "formatted" "+15555550199" "$(normalize_number '+1 (555) 555-0199')"
check "dots" "5551234567" "$(normalize_number 555.123.4567)"
normalize_number "call me" >/dev/null; check "rejects words" 1 $?
normalize_number "12" >/dev/null; check "rejects too short" 1 $?

# parse_when, with "now" fixed at 2026-10-30 00:10 Bogota time
RINGER_NOW=$(epoch "2026-10-30 00:10")
check "later today" "$(epoch '2026-10-30 01:30')" "$(parse_when 01:30)"
check "single digit hour" "$(epoch '2026-10-30 09:05')" "$(parse_when 9:05)"
check "already passed rolls to tomorrow" "$(epoch '2026-10-31 00:05')" "$(parse_when 00:05)"
check "full date" "$(epoch '2026-11-02 07:00')" "$(parse_when '2026-11-02 07:00')"
check "ISO style" "$(epoch '2026-11-02 07:00')" "$(parse_when 2026-11-02T07:00)"
check "anchored date" "$(epoch '2026-12-24 23:59')" "$(parse_when 23:59 2026-12-24)"
parse_when 24:00 >/dev/null; check "rejects 24:00" 1 $?
parse_when 12:60 >/dev/null; check "rejects 12:60" 1 $?
parse_when "2026-02-30 10:00" >/dev/null; check "rejects Feb 30" 1 $?
parse_when "tomorrow" >/dev/null; check "rejects words" 1 $?
unset RINGER_NOW

# config parsing
mkdir -p $CONFIG_DIR
cat > $CONFIG_FILE <<'EOF'
# a comment
mic = "Yeti Stereo Microphone"
speaker=Logitech BT Adapter
   repeat = 5

voice = "Paulina"
EOF
load_config
check "quoted value" "Yeti Stereo Microphone" "$cfg[mic]"
check "unquoted value" "Logitech BT Adapter" "$cfg[speaker]"
check "trimmed number" "5" "$cfg[repeat]"
check "untouched default" "60" "$cfg[answer_timeout]"

write_config
cfg[mic]=changed
load_config
check "config round-trips" "Yeti Stereo Microphone" "$cfg[mic]"

# option parsing
parse_call_opts +5712345678 -m "hola" --repeat 2 -v Mónica
check "positional kept" "+5712345678" "$rest"
check "message text" "hola" "$opt_text"
check "repeat flag" "2" "$cfg[repeat]"
check "voice flag" "Mónica" "$cfg[voice]"
parse_call_opts +5712345678 01:30 01:40 --here --date 2026-11-01
check "times kept" "+5712345678 01:30 01:40" "$rest"
check "here flag" "1" "$opt_here"
check "date flag" "2026-11-01" "$opt_date"

# call arguments, with the parts that touch the phone stubbed out
preflight() { : }
do_call() { print -r -- "$1|${2:+$(<$2)}" }
cfg[voice]="" cfg[repeat]=3
check "message as argument" "+5712345678|hola pipi" "$(cmd_call +5712345678 'hola pipi')"
check "no message dials only" "+5712345678|" "$(cmd_call '+57 (1) 234-5678')"
check "message with -m" "+5712345678|hola" "$(cmd_call +5712345678 -m hola)"
print -r -- "desde archivo" > $XDG_STATE_HOME/msg-test.txt
check "message from file" "+5712345678|desde archivo" "$(cmd_call +5712345678 -f $XDG_STATE_HOME/msg-test.txt)"
( cmd_call +5712345678 hola -m otra ) 2>/dev/null; check "rejects message twice" 1 $?
( cmd_call +5712345678 hola -f $XDG_STATE_HOME/msg-test.txt ) 2>/dev/null; check "rejects message and file" 1 $?
( cmd_call +5712345678 a b ) >/dev/null 2>&1; check "rejects extra arguments" 1 $?

print "$pass passed, $fail failed"
(( fail == 0 ))
