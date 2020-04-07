#! /bin/sh

# Universal wrapper

PROGNAME="$(basename $0)"
INNER_PROGNAME="/usr/bin/$PROGNAME"
LOGNAME="$PROGNAME"
LOG="$HOME/uniwrapper.log/$LOGNAME.log"

STDOUT="$(mktemp)"
STDERR="$(mktemp)"

trap 'rm -f $STDOUT $STDERR; exit' INT

LOGDIR=$(dirname $LOG)
mkdir -p "$LOGDIR"

date >> "$LOG"
echo "Directory: $PWD" >> "$LOG"
echo "$@" >> "$LOG"

$INNER_PROGNAME "$@" >"$STDOUT" 2>"$STDERR"

rc=$?
cat "$STDOUT"
cat "$STDERR" >> "$LOG"
echo "Return: $rc" >> "$LOG"
cat "$STDERR" >&2
echo "---------------------------------" >> "$LOG"

rm -f "$STDOUT" "$STDERR"
exit $rc
