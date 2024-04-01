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
which it seems I'm not very good at. Some mem bugs could occur.

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
  `note_on_off`, `cc` and `pc` trigger the corresponding events, with the
  relevant parameters above,
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
