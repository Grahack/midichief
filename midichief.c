// From http://fundamental-code.com/midi/

#include <alsa/asoundlib.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

static snd_seq_t *seq_handle;
static int client_id;
static int in_port;
static int out_port;

static int on_note_on_defined = 0;
static int on_note_off_defined = 0;
static int on_cc_defined = 0;
static int on_pc_defined = 0;

static lua_State *L;

#define CHK(stmt, msg) if((stmt) < 0) {puts("ERROR: "#msg); exit(1);}
void midi_open(void) {
    CHK(snd_seq_open(&seq_handle, "default", SND_SEQ_OPEN_DUPLEX, 0),
            "Could not open sequencer");

    CHK(snd_seq_set_client_name(seq_handle, "MIDI Chief ALSA client"),
            "Could not set client name");
    CHK(client_id = snd_seq_client_id(seq_handle),
            "Could not set client id");
    CHK(in_port = snd_seq_create_simple_port(seq_handle, "listen:in",
                SND_SEQ_PORT_CAP_WRITE|SND_SEQ_PORT_CAP_SUBS_WRITE,
                SND_SEQ_PORT_TYPE_APPLICATION),
            "Could not open in port");
    CHK(out_port = snd_seq_create_simple_port(seq_handle, "emit:out",
                SND_SEQ_PORT_CAP_READ|SND_SEQ_PORT_CAP_SUBS_READ,
                SND_SEQ_PORT_TYPE_APPLICATION),
            "Could not open out port");
    puts("MIDI Chief ALSA client started with");
    printf("  id=%d, in_port=%d, out_port=%d\n", client_id, in_port, out_port);
}

snd_seq_event_t *midi_read(void) {
    snd_seq_event_t *ev = NULL;
    snd_seq_event_input(seq_handle, &ev);
    return ev;
}

// Event sending with some help from
// https://unix.stackexchange.com/questions/759660/how-to-write-raw-midi-bytes-to-linux-midi-through-client
// and http://cowlark.com/amidimap/
snd_seq_event_t new_event() {
    snd_seq_event_t ev;
    snd_seq_ev_clear(&ev);
    snd_seq_ev_set_direct(&ev);
    snd_seq_ev_set_dest(&ev, client_id, out_port);
    return ev;
}

int send_event(snd_seq_event_t ev) {
    int err;
    snd_seq_ev_set_subs(&ev);
    snd_seq_ev_set_source(&ev, out_port);
    if ((err = snd_seq_event_output_direct(seq_handle, &ev)) < 0) {
        puts("send to sequencer failed");
        return -1;
    }
    snd_seq_drain_output(seq_handle);
    return 0;
}

int note_on(int channel, int note, int velocity) {
    snd_seq_event_t ev = new_event();
    snd_seq_ev_set_noteon(&ev, channel, note, velocity);
    return send_event(ev);
}

int note_off(int channel, int note, int velocity) {
    snd_seq_event_t ev = new_event();
    snd_seq_ev_set_noteoff(&ev, channel, note, velocity);
    return send_event(ev);
}

int midi_process(const snd_seq_event_t *ev) {
    if((ev->type==SND_SEQ_EVENT_NOTEON)||(ev->type==SND_SEQ_EVENT_NOTEOFF)) {
        int chan = ev->data.note.channel;
        int note = ev->data.note.note;
        int velo = ev->data.note.velocity;
        const char *type = (ev->type==SND_SEQ_EVENT_NOTEON) ? "on " : "off";
        printf("Ch:%2d Note %s: %2x vel(%2x)\n", chan, type, note, velo);
        if(ev->type == SND_SEQ_EVENT_NOTEON)
            return note_on(ev->data.note.channel,
                           ev->data.note.note,
                           ev->data.note.velocity);
        if(ev->type == SND_SEQ_EVENT_NOTEOFF)
            return note_off(ev->data.note.channel,
                            ev->data.note.note,
                            ev->data.note.velocity);
    }
    else if(ev->type == SND_SEQ_EVENT_PITCHBEND)
        printf("Ch:%2d PitchB.: %5d\n",
                    ev->data.control.channel,
                    ev->data.control.value);
    else if(ev->type == SND_SEQ_EVENT_CONTROLLER)
        printf("Ch:%2d Control: %2x val(%2x)\n",
                ev->data.control.channel,
                ev->data.control.param,
                ev->data.control.value);
    else if(ev->type == SND_SEQ_EVENT_PGMCHANGE)
        printf("Ch:%2d PGM ch.: %2x\n",
                ev->data.control.channel,
                ev->data.control.value);
    else if(ev->type == SND_SEQ_EVENT_KEYPRESS)
        printf("Ch:%2d Aftert.: %2x val(%2x)\n",
                    ev->data.note.channel,
                    ev->data.note.note,
                    ev->data.note.velocity);
    else if(ev->type == SND_SEQ_EVENT_SYSEX)
        puts("Ignored: SYSEX event");
    else
        printf("Unhandled Event Received: %2x (hex)\n", ev->type);
    return 0;
}

int main(int argc, char *argv[]) {
    L = luaL_newstate();
    // Check command line args
    if (argc == 1) {
        puts("No Lua file provided, raw-forwarding everything.");
    } else {
        // Read Lua file: check if it exists first
        char *filename = argv[1];
        FILE *file;
        if((file = fopen(filename, "r"))!=NULL) {
            // File exists, we close it then read it with the Lua tools
            fclose(file);
            printf("Reading MIDI logic from '%s'.\n", filename);
            luaL_openlibs(L);
            if (luaL_dofile(L, filename) == LUA_OK) {
                lua_pop(L, lua_gettop(L));
            } else {
                puts("Error in Lua file:");
                puts(lua_tostring(L, lua_gettop(L)));
                lua_pop(L, lua_gettop(L));
            }
            // Check if the relevant functions are defined
            lua_getglobal(L, "on_note_on");
            if (lua_isfunction(L, -1)) on_note_on_defined = 1;
            lua_pop(L, lua_gettop(L));
            lua_getglobal(L, "on_note_off");
            if (lua_isfunction(L, -1)) on_note_off_defined = 1;
            lua_pop(L, lua_gettop(L));
            lua_getglobal(L, "on_cc");
            if (lua_isfunction(L, -1)) on_cc_defined = 1;
            lua_pop(L, lua_gettop(L));
            lua_getglobal(L, "on_pc");
            if (lua_isfunction(L, -1)) on_pc_defined = 1;
            lua_pop(L, lua_gettop(L));
            printf("In %s are defined:\n", filename);
            printf("  on_note_on:%d, on_note_off:%d, on_cc:%d, on_pc:%d\n",
                on_note_on_defined, on_note_off_defined,
                on_cc_defined, on_pc_defined);
            // Thank you Lua!!!
            // We do note close the Lua state L for subsequent use
            // lua_close()
        } else {
            printf("File '%s' does not exist, raw-forwarding everything.\n",
                    filename);
        }
    }
    // Commect to ALSA and process events
    midi_open();
    while(1)
        if(midi_process(midi_read()) < 0) puts("Error in midi_process!");
    return -1;
}

