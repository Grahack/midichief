// From http://fundamental-code.com/midi/

#include <alsa/asoundlib.h>

static snd_seq_t *seq_handle;
static int client_id;
static int in_port;
static int out_port;

#define CHK(stmt, msg) if((stmt) < 0) {puts("ERROR: "#msg); exit(1);}
void midi_open(void)
{
    CHK(snd_seq_open(&seq_handle, "default", SND_SEQ_OPEN_DUPLEX, 0),
            "Could not open sequencer");

    CHK(snd_seq_set_client_name(seq_handle, "Midi Chief ALSA client"),
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
    printf("Starting with id=%d, in_port=%d, out_port=%d\n",
            client_id, in_port, out_port);
}

snd_seq_event_t *midi_read(void)
{
    snd_seq_event_t *ev = NULL;
    snd_seq_event_input(seq_handle, &ev);
    return ev;
}

int midi_process(const snd_seq_event_t *ev)
{
    if((ev->type == SND_SEQ_EVENT_NOTEON)
            ||(ev->type == SND_SEQ_EVENT_NOTEOFF)) {
        const char *type = (ev->type==SND_SEQ_EVENT_NOTEON) ? "on " : "off";
        printf("[%d] Note %s: %2x vel(%2x)\n", ev->time.tick, type,
                                               ev->data.note.note,
                                               ev->data.note.velocity);
        // With some help from
        // https://unix.stackexchange.com/questions/759660/how-to-write-raw-midi-bytes-to-linux-midi-through-client
        // and http://cowlark.com/amidimap/
        snd_seq_event_t ev2;
        int err;
        snd_seq_ev_clear(&ev2);
        // direct passing mode (i.e. no queue)
        snd_seq_ev_set_direct(&ev2);
        // id and port number of destination
        // could also subscribe to this port
        // and then use snd_seq_ev_set_subs
        // to send to subscribers
        snd_seq_ev_set_dest(&ev2, client_id, out_port);
        if(ev->type == SND_SEQ_EVENT_NOTEON)
            // 0 is the channel
            snd_seq_ev_set_noteon(&ev2, 0, ev->data.note.note,
                                           ev->data.note.velocity);
        if(ev->type == SND_SEQ_EVENT_NOTEOFF)
            // 0 is the channel
            snd_seq_ev_set_noteoff(&ev2, 0, ev->data.note.note,
                                            ev->data.note.velocity);
        snd_seq_ev_set_subs(&ev2);
        snd_seq_ev_set_source(&ev2, out_port);
        if ((err = snd_seq_event_output_direct(seq_handle, &ev2)) < 0) {
            printf("send to sequencer failed \n");
            return -1;
        }
        // call when nothing further to send:
        snd_seq_drain_output(seq_handle)+1;
    }
    else if(ev->type == SND_SEQ_EVENT_CONTROLLER)
        printf("[%d] Control:  %2x val(%2x)\n", ev->time.tick,
                                                ev->data.control.param,
                                                ev->data.control.value);
    else
        printf("[%d] Unknown:  Unhandled Event Received\n", ev->time.tick);
    return 0;
}

int main()
{
    midi_open();
    while(1)
        if(midi_process(midi_read()) < 0) printf("Error in midi_process!");
    return -1;
}

