#!/bin/bash
BB_DIR=/home/chri/botboss
MC_DIR=$BB_DIR/midichief
SM=$BB_DIR/divs-midi-utilities/bin/sendmidi
LS=$BB_DIR/divs-midi-utilities/bin/lsmidiouts
LOG=$MC_DIR/midichief-$(date '+%Y%m%d-%H%M%S').log
FONT=/usr/share/sounds/sf2/FluidR3_GM.sf2
NUM_SOUNDCARD=$(cat /proc/asound/cards | \
                grep "pisound" | \
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

check_running() {
    # min BPM is 10 so the log file should be touched at least every 6s
    sleep 7
    AGE_IN_SECONDS=$((($(date +%s) - $(date +%s -r $LOG))))
    if [ "$AGE_IN_SECONDS" -gt 7 ]; then  # min BPM is 10 so every 6s
        echo "Too old! Restarting..."
        sh $MC_DIR/setup.sh
    else
        echo "Young enough!"
        check_running
    fi
}

log "Setting up at $(date +%T)"
stdbuf -oL $MC_DIR/midichief $MC_DIR/botboss.lua >> $LOG 2>&1 &
# https://raspberrypi.stackexchange.com/questions/14987/midi-keyboard-latency-with-fluidsynth
# -c=NUM  (number of audio buffers, default 16)
# -z=SIZE (buffer size, default 64)
# TODO: https://www.dhpiggott.net/2021/03/19/running-fluidsynth-on-a-raspberry-pi-4/
fluidsynth -i --server --gain 2 --audio-driver=alsa \
           --sample-rate 48000.000 \
           --audio-bufcount=2 \
           --audio-bufsize=32 \
           -o "audio.alsa.device=hw:$NUM_SOUNDCARD" \
           $FONT >> $LOG 2>&1 &
connect_ALSA "Launchkey":0 "MIDI Chief":0
connect_ALSA "Launchkey":1 "MIDI Chief":0
connect_ALSA "MIDI Chief":1 "Launchkey":1
connect_ALSA "pisound":0 "MIDI Chief":0
connect_ALSA "MIDI Chief":1 "pisound":0
connect_ALSA "MIDI Chief":1 "FLUID Synth":0
# optionnaly connect the second keyboard
aconnect "Keystation":0 "MIDI Chief":0
# Let's silence Fluidsynth on some channels
FLUID_PORT=$($LS | grep FLUID | cut -d' ' -f3)
$SM --out $FLUID_PORT --control-change 0 7 0    # chan 0(1) (LK DAW mode)
$SM --out $FLUID_PORT --control-change 1 7 0    # chan 1(2) (NTS)
$SM --out $FLUID_PORT --control-change 15 7 0    # chan 0(1) (LK DAW mode)
# notify MIDI Chief that everything is OK
$SM --out "MIDI Chief ALSA client:listen:in" --program-change 15 127
log "Ready at $(date +%T)"
check_running
