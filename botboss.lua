print("BotBoss Lua definitions")

-- state variables
local page = 0  -- can be any non negative integer

-- CONSTANTS
local CHAN_LK = 0  -- the channel at which the Launchkey listens (InControl)
-- constants for LED colors (Launchkey in InControl mode)
local BLACK = 0
local RED = 1
local YELLOW = 17
local GREEN = 16

local LED_map = {}
LED_map["play_up"] = 104
LED_map["play_down"] = 120

function LED(where, color)
    note_on(CHAN_LK, LED_map[where], color)
end

function click()
    print("click from Lua", BPM)
end

function play_up_0(on_off)
    if on_off == 0 then  -- on release
        page = 1
        update_LEDs_page()
    end
end

function play_down_1(on_off)
    -- on_off == 0 is button release
    if on_off == 0 then  -- on release
        page = 0
        update_LEDs_page()
    end
end

function update_LEDs_page()
    if page == 0 then
        LED("play_up", BLACK)
        LED("play_down", YELLOW)
    elseif page == 1 then
        LED("play_up", YELLOW)
        LED("play_down", BLACK)
    else
        LED("play_up", RED)
        LED("play_down", RED)
    end
end

-- Used to play melodies
function sleep(n)
    os.execute("sleep " .. (n/1000))
end

function halt_attempt()
    print("HALT attempt")
    -- double tap emulation
    local THIS_HALT_PRESS = os.time()
    if THIS_HALT_PRESS - LAST_HALT_PRESS == 0 then
        print("HALT")
        note_on(1, 72, 120)
        sleep(200)
        note_off(1, 72, 120)
        note_on(1, 67, 120)
        sleep(200)
        note_off(1, 67, 120)
        note_on(1, 64, 120)
        sleep(200)
        note_off(1, 64, 120)
        note_on(1, 60, 120)
        sleep(200)
        note_off(1, 60, 120)
        os.execute("sudo halt")
    else
        LAST_HALT_PRESS = THIS_HALT_PRESS
    end
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

local LAST_HALT_PRESS = 0  -- to implement a kind of double tap

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

function pad_01_0(on_off)
    print("pad 1", on_off)
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
        send_note(on_off, chan, note-24, velo);
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
    if chan == 15 and val == 115 then
        incontrol()
        reload_rules()
        BPM = 60  -- just a test
        -- all notes off
        for n = 0, 127 do
            note_off(0, n, 127);
            print("note off chan 0(1):", n)
        end
        update_LEDs_page()
    elseif chan == 15 and val == 116 then
        halt_attempt()
    elseif chan == 15 and val == 127 then
        incontrol()
        -- Play a melody at startup
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
    else
        pc(chan, val)
    end
end
