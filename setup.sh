#!/bin/bash
BB_DIR=/home/chri/botboss
MC_DIR=$BB_DIR/midichief
SM=$BB_DIR/divs-midi-utilities/bin/sendmidi
LOG=$MC_DIR/midichief.log
FONT=/usr/share/sounds/sf2/FluidR3_GM.sf2
NUM_SOUNDCARD=$(cat /proc/asound/cards | \
                grep "USB-Audio - USB Audio CODEC" | \
                cut -d' ' -f2)

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
fluidsynth -i --server --audio-driver=alsa -o audio.alsa.device=hw:$NUM_SOUNDCARD $FONT >> $LOG 2>&1 &
connect_ALSA "Launchkey":0 "MIDI Chief":0
connect_ALSA "Launchkey":1 "MIDI Chief":0
connect_ALSA "MIDI Chief":1 "Launchkey":1
connect_ALSA "UM-1":0 "MIDI Chief":0
connect_ALSA "MIDI Chief":1 "UM-1":0
connect_ALSA "MIDI Chief":1 "FLUID Synth":0
# Let's silence Fluidsynth on some channels
$SM --out "FLUID Synth" --control-change 0 7 0    # chan 0(1) (InControl)
$SM --out "FLUID Synth" --control-change 1 7 0    # chan 1(2) (NTS)
# Let's boost Fluidsynth's drums
$SM --out "FLUID Synth" --control-change 9 7 127
# alert MIDI Chief that everything is OK
$SM --out "MIDI Chief ALSA client:listen:in" --program-change 15 127
log "Ready at $(date +%T)"
