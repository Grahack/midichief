// From http://fundamental-code.com/midi/

#include <alsa/asoundlib.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <sys/time.h>
#include <pthread.h>

static snd_seq_t *seq_handle;
static int client_id;
static int in_port;
static int out_port;

static char *filename;

static int on_note_defined = 0;
static int on_cc_defined = 0;
static int on_pc_defined = 0;
static int click_defined = 0;

static double BPM = 120;
// TOD is 'time of day', as is called the function from time.h
struct timeval last_TOD, TOD;
double elapsed = 0;

// https://lucasklassmann.com/blog/2019-02-02-embedding-lua-in-c/
static lua_State *L;
lua_State *L2;  // child state for the emit_click thread

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

int note_on_off(int on_off, int channel, int note, int velocity) {
    snd_seq_event_t ev = new_event();
    if (on_off) {
        snd_seq_ev_set_noteon(&ev, channel, note, velocity);
    } else {
        snd_seq_ev_set_noteoff(&ev, channel, note, velocity);
    }
    return send_event(ev);
}

int pb(int channel, int value) {
    snd_seq_event_t ev = new_event();
    snd_seq_ev_set_pitchbend(&ev, channel, value);
    return send_event(ev);
}

int keypress(int channel, int note, int velocity) {
    // aftertouch
    snd_seq_event_t ev = new_event();
    snd_seq_ev_set_keypress(&ev, channel, note, velocity);
    return send_event(ev);
}

int cc(int channel, int param, int value) {
    snd_seq_event_t ev = new_event();
    snd_seq_ev_set_controller(&ev, channel, param, value);
    return send_event(ev);
}

int pc(int channel, int value) {
    snd_seq_event_t ev = new_event();
    snd_seq_ev_set_pgmchange(&ev, channel, value);
    return send_event(ev);
}

// All Lua MIDI functions take 2, 3 or 4 integers so we assume 4
void call_lua_fn(char fn_name[], int arg1, int arg2, int arg3, int arg4) {
    lua_getglobal(L, fn_name);
    if (lua_isfunction(L, -1)) printf("Call Lua fn: %s\n", fn_name);
    lua_pushinteger(L, arg1);
    lua_pushinteger(L, arg2);
    lua_pushinteger(L, arg3);
    lua_pushinteger(L, arg4);
    if (lua_pcall(L, 4, 1, 0) == LUA_OK) {
        lua_pop(L, lua_gettop(L));
    } else {
        printf("Error in Lua function %s:\n", fn_name);
        puts(lua_tostring(L, lua_gettop(L)));
        lua_pop(L, lua_gettop(L));
    }
}

int note_on_off_for_lua(lua_State *L) {
    int on_off = luaL_checkinteger(L, 1);
    int chan   = luaL_checkinteger(L, 2);
    int note   = luaL_checkinteger(L, 3);
    int velo   = luaL_checkinteger(L, 4);
    note_on_off(on_off, chan, note, velo);
    return 0; // The number of returned values
}

int cc_for_lua(lua_State *L) {
    int chan  = luaL_checkinteger(L, 1);
    int param = luaL_checkinteger(L, 2);
    int value = luaL_checkinteger(L, 3);
    cc(chan, param, value);
    return 0; // The number of returned values
}

int pc_for_lua(lua_State *L) {
    int chan  = luaL_checkinteger(L, 1);
    int value = luaL_checkinteger(L, 2);
    pc(chan, value);
    return 0; // The number of returned values
}

int load_lua_rules() {
    // Read Lua file: check if it exists first
    FILE *file;
    if((file = fopen(filename, "r"))!=NULL) {
        // File exists, we close it then read it with the Lua tools
        fclose(file);
        printf("Reading MIDI logic from '%s'.\n", filename);
        if (luaL_dofile(L, filename) == LUA_OK) {
            lua_pop(L, lua_gettop(L));
        } else {
            puts("Error in Lua file:");
            puts(lua_tostring(L, lua_gettop(L)));
            lua_pop(L, lua_gettop(L));
        }
        // Check if the relevant functions are defined
        lua_getglobal(L, "on_note");
        if (lua_isfunction(L, -1)) on_note_defined = 1;
        else on_note_defined = 0;
        lua_pop(L, lua_gettop(L));
        lua_getglobal(L, "on_cc");
        if (lua_isfunction(L, -1)) on_cc_defined = 1;
        else on_cc_defined = 0;
        lua_pop(L, lua_gettop(L));
        lua_getglobal(L, "on_pc");
        if (lua_isfunction(L, -1)) on_pc_defined = 1;
        else on_pc_defined = 0;
        lua_pop(L, lua_gettop(L));
        lua_getglobal(L, "click");
        if (lua_isfunction(L, -1)) click_defined = 1;
        else click_defined = 0;
        lua_pop(L, lua_gettop(L));
        printf("In %s are defined:\n", filename);
        printf("  on_note:%d on_cc:%d on_pc:%d click:%d\n",
            on_note_defined, on_cc_defined, on_pc_defined, click_defined);
        // Thank you Lua!!!
        // We do not close the Lua state L for subsequent use
        // lua_close()
    } else {
        printf("File '%s' does not exist, raw-forwarding everything.\n",
                filename);
    }
}

int reload_for_lua(lua_State *L) {
    load_lua_rules();
    return 0; // The number of returned values
}

int midi_process(const snd_seq_event_t *ev) {
    if((ev->type==SND_SEQ_EVENT_NOTEON)||(ev->type==SND_SEQ_EVENT_NOTEOFF)) {
        int on_off = (ev->type==SND_SEQ_EVENT_NOTEON) ? 1 : 0;
        int chan = ev->data.note.channel;
        int note = ev->data.note.note;
        int velo = ev->data.note.velocity;
        const char *type = on_off ? "on " : "off";
        printf("Ch:%2d Note %s: %2x vel(%2x)\n", chan, type, note, velo);
        if(on_note_defined) {
            call_lua_fn("on_note", on_off, chan, note, velo);
            return 0;
        } else {
            return note_on_off(on_off, chan, note, velo);
        }
    } else if(ev->type == SND_SEQ_EVENT_PITCHBEND) {
        int chan = ev->data.control.channel;
        int val = ev->data.control.value;
        printf("Ch:%2d PitchB.: %5d\n", chan, val);
        // Direct forward, no logic
        pb(chan, val);
    } else if(ev->type == SND_SEQ_EVENT_KEYPRESS) {
        int chan = ev->data.note.channel;
        int note = ev->data.note.note;
        int velo = ev->data.note.velocity;
        printf("Ch:%2d Aftert.: %2x val(%2x)\n", chan, note, velo);
        // Direct forward, no logic
        keypress(chan, note, velo);
    } else if(ev->type == SND_SEQ_EVENT_CONTROLLER) {
        int chan  = ev->data.control.channel;
        int param = ev->data.control.param;
        int val   = ev->data.control.value;
        printf("Ch:%2d Control: %2x val(%2x)\n", chan, param, val);
        if(on_cc_defined) {
            call_lua_fn("on_cc", chan, param, val, 0);
            return 0;
        } else {
            return cc(chan, param, val);
        }
    } else if(ev->type == SND_SEQ_EVENT_PGMCHANGE) {
        int chan = ev->data.control.channel;
        int val  = ev->data.control.value;
        printf("Ch:%2d PGM ch.: %2x\n", chan, val);
        if(on_pc_defined) {
            call_lua_fn("on_pc", chan, val, 0, 0);
            return 0;
        } else {
            return pc(chan, val);
        }
    } else if(ev->type == SND_SEQ_EVENT_SYSEX)
        puts("Ignored: SYSEX event");
    else
        printf("Unhandled Event Received: %2x (hex)\n", ev->type);
    return 0;
}

void *read_and_process_midi(void *vargp) {
    while(1) {
        if(midi_process(midi_read()) < 0) puts("Error in midi_process!");
    }
}

void *emit_click(void *vargp) {
    while(1) {
        gettimeofday(&TOD, NULL);
        elapsed = (TOD.tv_sec - last_TOD.tv_sec) * 1000.0;    // s to ms
        elapsed += (TOD.tv_usec - last_TOD.tv_usec) / 1000.0; // us to ms
        if(elapsed > 60000/BPM) {
            lua_getglobal(L2, "click");
            if (lua_isfunction(L2, -1)) puts("Call Lua click");
            if (lua_pcall(L2, 0, 1, 0) == LUA_OK) lua_pop(L2, lua_gettop(L2));
            last_TOD = TOD;
            // grab the BPM in the Lua state
            lua_getglobal(L2, "BPM");
            if (lua_isnumber(L2, -1)) {
                BPM = lua_tonumber(L2, -1);
                lua_pop(L2, 1);
            } else {
                puts("No global var 'BPM' in the Lua state!");
            }
        }
    }
}

int main(int argc, char *argv[]) {
    L = luaL_newstate();
    luaL_openlibs(L);
    // expose some C code to Lua
    lua_pushcfunction(L, reload_for_lua);
    lua_setglobal(L, "reload_rules");
    lua_pushcfunction(L, note_on_off_for_lua);
    lua_setglobal(L, "note_on_off");
    lua_pushcfunction(L, cc_for_lua);
    lua_setglobal(L, "cc");
    lua_pushcfunction(L, pc_for_lua);
    lua_setglobal(L, "pc");
    // this is for the emit_click thread
    L2 = lua_newthread(L);
    luaL_openlibs(L2);
    // Check command line args
    if (argc == 1) {
        puts("No Lua file provided, raw-forwarding everything.");
    } else {
        filename = argv[1];
        load_lua_rules();
    }
    // Commect to ALSA and process events
    midi_open();
    // a thread for reading and processing MIDI in
    pthread_t tid1;
    pthread_create(&tid1, NULL, read_and_process_midi, (void *)&tid1);
    // a thread (if needed) for a click
    if (click_defined) {
        // start timer
        gettimeofday(&last_TOD, NULL);
        pthread_t tid2;
        pthread_create(&tid2, NULL, emit_click, (void *)&tid2);
    }
    pthread_exit(NULL);
    return 0;
}
