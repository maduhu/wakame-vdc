#!/bin/bash

[ -d "$CODEDIR" ] && [ -n "$DATADIR" ] || {
    echo "($0)" 1>&2
    echo "This step expects calling script to set up environment" 1>&2
    exit 255
}

# This must be set by the caller.  Exit if not set:
: ${CENTOSISO:?} ${DISKSIZE:?} ${MEMSIZE:?}

$starting_checks "Install minimal image with kickstart"
[ -f "$DATADIR/minimal-image.raw" ] || \
    [ -f "$DATADIR/minimal-image.raw.tar.gz" ]
$skip_rest_if_already_done
set -e
cd "$DATADIR"  # centos-kickstart-build.sh creates files in the current $(pwd)
time "$CODEDIR/bin/centos-kickstart-build.sh" \
     "$CENTOSISO" "ks-sshpair.cfg" "tmp.raw" "$MEMSIZE" "$DISKSIZE"
cp -al "tmp.raw" "minimal-image.raw"
