# MIDI Chief

ALSA C client with MIDI logic written in Lua.

You can filter, route, split, anything you dream to do...

## Files

Still very alpha, I try to write clean code but the project is not as
modulable as it should be: it's mostly structured for my own use.

### midichief.c

This one is the core of the project. But, as planned, is not the one I
change very often since this project is meant to be scriptable.

It reads a Lua file which should contain functions that are triggered
by MIDI events. Those functions can, in turn, send MIDI events.

BEWARE: since reading MIDI events is blocking I had to use pthreads,
which it seems I'm not very good at. Some mem bugs could occur because I try
to share a Lua state between the two threads.

- `double free or corruption (!prev)` (when setting the click mode to
  visual + sound)
- `corrupted double-linked list (not small)` ?

### setup.sh

Sets everything up:

- starts `midichief`
- connects the MIDI over USB and PiSound DIN5 devices

It also regularly writes to `/tmp/midichief.log` to check for a potential
freeze, then restarts everything if this file has been written too long ago.

### botboss.lua

This is where I write the *filter/route/split/you name it* rules but you
could rename it (see `setup.sh`). My rules are like an app for a Novation
Launchkey MK3 to control the Fluidsynth instance which runs in the Pi and a
Korg NTS. I'll try to shoot a video soonish about this.

## Hints for your Lua file

No Lua file, no rules: if no Lua file is provided every MIDI event will be
forwarded as is.

### Functions to define in your Lua file

`midichief` tests the existence of the four following functions. If there is
no relevant function for a MIDI event it is forwarded as is. If the function
exists it is triggered and may trigger another event (or several).

- `on_note on_off chan note vel`
- `on_cc chan num val`
- `on_pc chan val`

`click`, if defined, is triggered 120 times per minute. BPM can be set thanks
to the `BPM` global variable living in the Lua file.

### Functions you can use in your Lua file

- trigger MIDI events:
  - `note_on_off`, `cc` and `pc` trigger the corresponding events, with the
    relevant parameters above,
  - `pb` triggers a pitch bend event (channel and value)
- other functions
  - `tap` (no parameter) will return the computed BPM when called repeatedly.
  - `reload_rules` will read the rules file and update the functions

## Install

### Prerequisites

```sh
# MIDI rules are written in a Lua file
sudo apt install lua5.3 liblua5.3-dev
# sendmidi is used to tell MIDI Chief that everything is set up
git clone --depth 1 git@github.com:dgslomin/divs-midi-utilities.git
cd divs-midi-utilities/src/sendmidi/
mkdir ../../bin
mv Makefile.unix Makefile
make
# you may need lsmidiouts of the same project to check for listeners
```

### Compile and trigger at boot time

```sh
cd midichief
make
# if needed at startup:
crontab -e
# where you write:
@reboot sh /home/chri/botboss/midichief/setup.sh >> /tmp/midichief.log 2>&1
```

## Doc for botboss.lua

NTS patches: press=select, hold=save (needs confirm)

- all pages
  - pot 1: Fluidsynth bass volume
  - pot 2: Fluidsynth drums volume
  - pot 3: Crash sensitivity
  - pot 4: Foot HH sensitivity in foot mode
- page 0
  - pot 5: BPM
  - pot 6: click note (hihat, foot hihat, ride, clap, cowbell, kick}
  - pot 7: click velocity (volume still controlled by pot 2)
  - pad 1: BPM = BPM / 2
  - pad 2: BPM = BPM * 2
  - pads 3 to 6: BPM change (-5, +5, -1, +1)
  - pad 7: click mode (nothing, sound, light, sound+light)
  - pad 8: tap tempo
  - pads 9 to 16: binary display+tweak of the BPM
- page 1
  - pots 5 to 8: NTS values (A, A+, B, B+)
  - pad 1: reload rules, hold to halt the RPi (needs confirm)
  - pad 2: drums on/off, hold to change the octave
  - pad 3: parallel kick (adds a kick to any note)
  - pad 4: foot HH (light HH means foot HH + sustain pedal is foot HH)
  - pads 5 to 7: NTS controls
  - pad 8: change page of NTS controls
  - pads 9 to 12: NTS patches
- page 2
  - pot 5: Program Change (PC)
  - pot 6: Fine tuning with a pitch bend tweak (0 is 0, else PB = 100(V-64)
    which gives us approx. two semitones each side
  - pads 1 to 4: GM category-1, GM category+1, PC-1, PC+1
  - pads 5 to 8: GM category (display only)
  - pads 9 to 16: binary display+tweak of the GM program
- page 3
  - pads 1 to 16: NTS patches

# French

## Fonctionnement

Pas de fichier Lua, pas de règle (retransmission directe des événements).

### Fonctions à définir côté Lua

Test de l’existence des 4 fonctions suivantes, sinon retransmission de
l’événement brut.

Selon ev entrant,
déclenchement de la fonction Lua correspondant au type de l’ev,
avec en paramètre les données:

- `on_note_on_off chan note vel`
- `on_cc chan num val`
- `on_pc chan val`

`click`, si définie dans le fichier Lua, est déclenchée 120 fois par minute.
Le tempo peut être fixé grâce à la variable globale `BPM` dans le fichier Lua.

### Fonctions utilisables depuis votre fichier Lua

Les fonctions fonctions `note_on_off`, `cc` et `pc` déclenchent les évènements
correspondants (avec les mêmes paramètres que ci-dessus).

La fonction `tap` (sans paramètre) calcule le BPM après plusieurs appels.
