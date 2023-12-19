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

void midi_process(const snd_seq_event_t *ev)
{
    if((ev->type == SND_SEQ_EVENT_NOTEON)
            ||(ev->type == SND_SEQ_EVENT_NOTEOFF)) {
        const char *type = (ev->type==SND_SEQ_EVENT_NOTEON) ? "on " : "off";
        printf("[%d] Note %s: %2x vel(%2x)\n", ev->time.tick, type,
                                               ev->data.note.note,
                                               ev->data.note.velocity);
    }
    else if(ev->type == SND_SEQ_EVENT_CONTROLLER)
        printf("[%d] Control:  %2x val(%2x)\n", ev->time.tick,
                                                ev->data.control.param,
                                                ev->data.control.value);
    else
        printf("[%d] Unknown:  Unhandled Event Received\n", ev->time.tick);
}

int main()
{
    midi_open();
    while(1)
        midi_process(midi_read());
    return -1;
}

