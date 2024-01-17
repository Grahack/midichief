#!/bin/bash
BB_DIR=/home/chri/botboss
MC_DIR=$BB_DIR/midichief
LOG=$MC_DIR/midichief.log

log() {
    echo $1 >> $LOG 2>&1
}

connect_ALSA() {
    log "Trying to connect $1 to $2"
    log "  at $(date +%T)"
    if aconnect "$1" "$2"; then
        log "Connected  at $(date +%T)!"
    else
        sleep 1
        connect_ALSA "$1" "$2"
    fi
}

log "Setting up at $(date +%T)"
stdbuf -oL $MC_DIR/midichief $MC_DIR/botboss.lua >> $LOG 2>&1 &
connect_ALSA "Launchkey":0 "MIDI Chief":0
connect_ALSA "Launchkey":1 "MIDI Chief":0
connect_ALSA "MIDI Chief":1 "Launchkey":1
connect_ALSA "UM-1":0 "MIDI Chief":0
connect_ALSA "MIDI Chief":1 "UM-1":0
$BB_DIR/divs-midi-utilities/bin/sendmidi --out "MIDI Chief ALSA client:listen:in" --program-change 15 127
log "Ready at $(date +%T)"
