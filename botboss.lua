print("BotBoss Lua definitions")

-- state variables
local page = 0  -- can be any non negative integer
local halt_press = 0   -- to implement long press
local click_press = 0  -- to implement long press
local click_edit  = false  -- edit mode activated?
local click_mode  = 0   -- 0 nothing, 1 sound, 2 visual, 3 both
local click_note  = 42  -- HH by default
local click_lit   = false  -- to implement alternating LEDs

-- CONSTANTS
local CHAN_LK = 0  -- the channel at which the Launchkey listens (InControl)
local CHAN_NTS = 1 -- NTS channel
local CHAN_drums = 9
local NOTE_HH   = 42
local NOTE_KICK = 36
local NOTE_SN   = 40
local NOTE_O_HH = 46
-- constants for LED colors (Launchkey in InControl mode)
local BLACK = 0
local RED = 1
local YELLOW = 17
local GREEN = 16
local click_colors = {BLACK, RED, GREEN, YELLOW}  -- see click_mode

local LED_map = {}
LED_map["play_up"]   = 104
LED_map["play_down"] = 120
LED_map["pad_01"] =  96
LED_map["pad_02"] =  97
LED_map["pad_03"] =  98
LED_map["pad_04"] =  99
LED_map["pad_05"] = 100
LED_map["pad_06"] = 101
LED_map["pad_07"] = 102
LED_map["pad_08"] = 103
LED_map["pad_09"] = 112
LED_map["pad_10"] = 113
LED_map["pad_11"] = 114
LED_map["pad_12"] = 115
LED_map["pad_13"] = 116
LED_map["pad_14"] = 117
LED_map["pad_15"] = 118
LED_map["pad_16"] = 119

function LED(where, color)
    note_on(CHAN_LK, LED_map[where], color)
end

function click()
    if click_mode == 0 then
        return
    end
    if click_mode == 1 or click_mode == 3 then
        note_on(CHAN_drums, click_note, 127)
        note_off(CHAN_drums, click_note, 127)
    end
    if click_mode == 2 or click_mode == 3 then
        click_lit = not click_lit
        update_LEDs()
    end
end

function play_up_0(on_off)
    if on_off == 0 then  -- on release
        page = 1
        update_LEDs()
    end
end

function play_down_1(on_off)
    -- on_off == 0 is button release
    if on_off == 0 then  -- on release
        page = 0
        update_LEDs()
    end
end

function update_LEDs()
    if page == 0 then
        LED("play_up", BLACK)
        LED("play_down", YELLOW)
        -- click
        if click_lit then
            LED("pad_01", YELLOW)
            LED("pad_02", YELLOW)
            LED("pad_03", YELLOW)
            LED("pad_04", YELLOW)
            LED("pad_09", YELLOW)
            LED("pad_10", YELLOW)
            LED("pad_11", YELLOW)
            LED("pad_12", YELLOW)
        else
            LED("pad_01", BLACK)
            LED("pad_02", BLACK)
            LED("pad_03", BLACK)
            LED("pad_04", BLACK)
            LED("pad_09", BLACK)
            LED("pad_10", BLACK)
            LED("pad_11", BLACK)
            LED("pad_12", BLACK)
        end
        LED("pad_05", click_colors[click_mode + 1])
    elseif page == 1 then
        LED("play_up", YELLOW)
        LED("play_down", BLACK)
        LED("pad_01", GREEN)
        LED("pad_02", BLACK)
        LED("pad_03", BLACK)
        LED("pad_04", BLACK)
        LED("pad_05", BLACK)
        LED("pad_09", BLACK)
        LED("pad_10", BLACK)
        LED("pad_11", BLACK)
        LED("pad_12", BLACK)
    else
        LED("play_up", RED)
        LED("play_down", RED)
    end
end

-- Used to play melodies
function sleep(n)
    os.execute("sleep " .. (n/1000))
end

function incontrol()
    -- set the Launchkey in its InControl mode
    note_on(0, 12, 127)
end

-- codes for MIDI notes or CC sent by the Launchkey (InControl mode, decimal)
local cc_fns = {}
local n_fns = {}

cc_fns[106] = "track_L"
cc_fns[107] = "track_R"

cc_fns[21] = "pot_1"
cc_fns[22] = "pot_2"
cc_fns[23] = "pot_3"
cc_fns[24] = "pot_4"
cc_fns[25] = "pot_5"
cc_fns[26] = "pot_6"
cc_fns[27] = "pot_7"
cc_fns[28] = "pot_8"

n_fns[ 96] = "pad_01"
n_fns[ 97] = "pad_02"
n_fns[ 98] = "pad_03"
n_fns[ 99] = "pad_04"
n_fns[100] = "pad_05"
n_fns[101] = "pad_06"
n_fns[102] = "pad_07"
n_fns[103] = "pad_08"

n_fns[112] = "pad_09"
n_fns[113] = "pad_10"
n_fns[114] = "pad_11"
n_fns[115] = "pad_12"
n_fns[116] = "pad_13"
n_fns[117] = "pad_14"
n_fns[118] = "pad_15"
n_fns[119] = "pad_16"

n_fns[104] = "play_up"
n_fns[120] = "play_down"

cc_fns[104] = "scene_up"
cc_fns[105] = "scene_down"

--     OSC      53  FILT     42  EG      14  MOD   88    DELAY 89  REV   90
-- A   SHAPE    54  CUTOFF   43  ATTACK  16  SPEED 28    TIME  30  TIME  34
-- B   ALT      55  RESO     44  RELEASE 19  DEPTH 29    DEPTH 31  DEPTH 35
-- A+  FREQ LFO 24  FREQ cs  46  FREQ t  21     X           X         X
-- B+  DEPTH    26  DEPTH cs 45  DEPTH t 20     X        MIX   33  MIX   36
--     pitch/shape  cutoff sweep trem

local CC_map = {}
-- OSC
CC_map[117] = 53  -- shift pot 1
CC_map[101] = 54  -- pot 1
CC_map[102] = 55  -- ...
CC_map[103] = 24
CC_map[104] = 26
-- FILT
CC_map[118] = 42  -- shift pot 9
CC_map[109] = 43  -- pot 9
CC_map[110] = 44
CC_map[111] = 46
CC_map[112] = 45
-- EG
CC_map[105] = 16  -- pot 5
CC_map[113] = 19  -- pot 13
-- MOD
CC_map[106] = 88  -- pot 6
CC_map[107] = 28  -- pot 7
CC_map[108] = 29  -- pot 8
-- REV
CC_map[114] = 90  -- pot 14
CC_map[115] = 34  -- pot 15
CC_map[116] = 35  -- pot 16

function pad_05_0(on_off)
    -- click edit
    if on_off == 1 then
        click_press = os.time()
        click_edit = true
        LED("pad_05", BLACK)
    else
        click_edit = false
        local click_release = os.time()
        if click_release - click_press <= 1 then
            click_mode = (click_mode + 1) % 4
            update_LEDs()
        end
    end
end

function pad_01_1(on_off)
    -- reload or halt
    if on_off == 1 then
        LED("pad_01", YELLOW)
        halt_press = os.time()
    else
        local halt_release = os.time()
        if halt_release - halt_press >= 2 then
            LED("pad_01", RED)
            print("HALT")
            melody_down()
            LED("pad_01", BLACK)
            os.execute("sudo halt")
        else
            LED("pad_01", GREEN)
            BPM = 60
            reload_rules()
            panic()
        end
    end
end

function pot_1_0(value)
    print("pot 1:", value)
end

function send_note(on_off, chan, note, velo)
    if on_off == 1 then
        note_on(chan, note, velo)
    else
        note_off(chan, note, velo)
    end
end

function handle_note(on_off, chan, note, velo)
    if chan == 1 then
        -- chan 1(2) is from the Launchkey in normal mode, or the keys
        -- these notes are for the NTS and are meant to be bass notes
        -- except for the highest on the keyboard: drum sounds
        if note == 70 then      -- HH
            send_note(on_off, CHAN_drums, 42, velo);
        elseif note == 68 then  -- kick
            send_note(on_off, CHAN_drums, 36, velo);
        elseif note == 72 then  -- snare
            send_note(on_off, CHAN_drums, 40, velo);
        elseif note == 71 then  -- open HH
            send_note(on_off, CHAN_drums, 46, velo);
        else
            send_note(on_off, chan, note-24, velo);
        end
    elseif chan == 0 then
        -- chan 0(1) is from the Launchkey in InControl mode
        local prefix = n_fns[note]
        if prefix == nil then
            print("No prefix to handle this note:", note, "(InControl mode)")
        else
            local f_name = prefix .. "_" .. page
            local f = _G[f_name]
            if f == nil then
                print("No fn to handle a note:", f_name, "(InControl mode)")
            else
                f(on_off)  -- velocity is useless (127 for on and 0 for off)
            end
        end
    elseif chan == 9 then
        -- a tweak for my electronic drums
        -- keyboard pads are:
        -- 24 36 C1  kick
        -- 2a 42 F#1 HH
        -- 26 38 D1  snare
        -- I need to translate snare 26 38 to kick 24 36
        if note == 38 then
            send_note(on_off, 9, 36, velo);
        -- and to translate HH 2e 46 to HH 2a 42
        elseif note == 46 then
            send_note(on_off, 9, 42, velo);
        else
            send_note(on_off, chan, note, velo);
        end
    else
        -- forward
        send_note(on_off, chan, note, velo);
    end
end

function on_note_on(chan, note, velo)
    handle_note(1, chan, note, velo)
end

function on_note_off(chan, note, velo)
    handle_note(0, chan, note, velo)
end

function on_cc(chan, param, val)
    if chan == 0 then
        -- chan 0(1) is from the Launchkey in InControl mode
        local prefix = cc_fns[param]
        if prefix == nil then
            print("No prefix to handle this CC:", param, "(InControl mode)")
        else
            local f_name = prefix .. "_" .. page
            local f = _G[f_name]
            if f == nil then
                print("No fn to handle a CC:", f_name, "(InControl mode)")
            else
                f(val)
            end
        end
    end
end

function on_pc(chan, val)
    if chan == 15 and val == 127 then
        -- startup
        incontrol()
        update_LEDs()
        melody_up()
    else
        -- forward
        pc(chan, val)
    end
end

function panic()
    -- all notes off
    for n = 0, 127 do
        note_off(0, n, 127);
        print("note off chan 0(1):", n)
    end
    -- note off events  blackens LEDs so we have to update everything
    update_LEDs()
end

function melody_down()
    note_on(CHAN_NTS, 72, 120)
    sleep(200)
    note_off(CHAN_NTS, 72, 120)
    note_on(CHAN_NTS, 67, 120)
    sleep(200)
    note_off(CHAN_NTS, 67, 120)
    note_on(CHAN_NTS, 64, 120)
    sleep(200)
    note_off(CHAN_NTS, 64, 120)
    note_on(CHAN_NTS, 60, 120)
    sleep(200)
    note_off(CHAN_NTS, 60, 120)
end

function melody_up()
    note_on(1, 60, 120)
    sleep(200)
    note_off(1, 60, 120)
    note_on(1, 64, 120)
    sleep(200)
    note_off(1, 64, 120)
    note_on(1, 67, 120)
    sleep(200)
    note_off(1, 67, 120)
    note_on(1, 72, 120)
    sleep(200)
    note_off(1, 72, 120)
end
