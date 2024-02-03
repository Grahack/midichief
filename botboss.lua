print("BotBoss Lua definitions")

-- CONSTANTS
local FILE_PREFIX = "/home/chri/botboss/midichief/"
local CHAN_LK = 0  -- the channel at which the Launchkey listens (InControl)
local CHAN_NTS = 1 -- NTS channel
local CHAN_drums = 9
local DUMMY_CC = 127
local NOTE_HH   = 42
local NOTE_KICK = 36
local NOTE_SN   = 40
local NOTE_O_HH = 46
local NOTE_CRASH = 49
-- constants for LED colors (Launchkey in InControl mode)
local BLACK = 0
local RED = 1
local YELLOW = 17
local GREEN = 16
local APPLE = 49
local ORANGE = 19
local click_colors = {BLACK, RED, GREEN, YELLOW}  -- see click_mode
-- synth
--     OSC      53  FILT     42  EG      14  MOD   88    DELAY 89  REV   90
-- A   SHAPE    54  CUTOFF   43  ATTACK  16  SPEED 28    TIME  30  TIME  34
-- B   ALT      55  RESO     44  RELEASE 19  DEPTH 29    DEPTH 31  DEPTH 35
-- A+  FREQ LFO 24  FREQ cs  46  FREQ t  21     X           X         X
-- B+  DEPTH    26  DEPTH cs 45  DEPTH t 20     X        MIX   33  MIX   36
--     pitch/shape  cutoff sweep trem
local INIT_PATCH =
{[ "53"] =   0, -- OSCILLATOR TYPE (vv=0,25,50,75,127)
 [ "54"] =   0, -- OSCILLATOR SHAPE (vv=0~127)
 [ "55"] =   0, -- OSCILLATOR ALT (vv=0~127)
 [ "24"] =   0, -- OSCILLATOR LFO RATE (vv=0~127)
 [ "26"] =  63, -- OSCILLATOR LFO DEPTH (vv=0~127)
 [ "42"] =   0, -- FILTER TYPE (vv=0,18,36,54,72,90,127)
 [ "43"] = 127, -- FILTER CUTOFF (vv=0~127)
 [ "44"] =   0, -- FILTER RESONANCE (vv=0~127)
 [ "46"] =  63, -- FILTER SWEEP RATE (vv=0~127)
 [ "45"] =  63, -- FILTER SWEEP DEPTH (vv=0~127)
 [ "14"] =   0, -- EG TYPE (vv=0,25,50,75,127)
 [ "16"] =   0, -- EG ATTACK (vv=0~127)
 [ "19"] =   0, -- EG RELEASE (vv=0~127)
 [ "21"] =   0, -- TREMOLO RATE (vv=0~127)
 [ "20"] =   0, -- TREMOLO DEPTH (vv=0~127)
 [ "88"] =   0, -- MOD FX TYPE (vv=0,25,50,75,127)
 [ "28"] =   0, -- MOD FX TIME (vv=0~127)
 [ "29"] =   0, -- MOD FX DEPTH (vv=0~127)
 [ "89"] =   0, -- DELAY FX TYPE (vv=0,21,42,63,84,127)
 [ "30"] =   0, -- DELAY FX TIME (vv=0~127)
 [ "31"] =   0, -- DELAY FX DEPTH (vv=0~127)
 [ "33"] =  63, -- DELAY FX MIX (vv=0~127)
 [ "90"] =   0, -- REVERB FX TYPE (vv=0,21,42,63,84,127)
 [ "34"] =   0, -- REVERB FX TIME (vv=0~127)
 [ "35"] =   0, -- REVERB FX DEPTH (vv=0~127)
 [ "36"] =  63, -- REVERB FX MIX (vv=0~127)
 ["117"] =   0, -- ARP PATTERN (vv=0,12,24,36,48,60,72,84,96,127)
 ["118"] =   0, -- ARP INTERVALS (vv=0,21,42,63,84,127)
 ["119"] =   0} -- ARP LENGTH (vv=0~127)
local CC_map = {}
CC_map["1_05"] = {54, 55, 24, 26} -- OSC
CC_map["1_06"] = {43, 44, 46, 45} -- FILT
CC_map["1_07"] = {16, 19, 21, 20} -- EG
CC_map["2_05"] = {28, 29, DUMMY_CC, DUMMY_CC} -- MOD
CC_map["2_06"] = {30, 31, DUMMY_CC, 33}       -- DELAY
CC_map["2_07"] = {34, 35, DUMMY_CC, 36}       -- REV
local CC_map_type_param = {["1_05"] = 53, ["1_06"] = 42, ["1_07"] = 14,
                           ["2_05"] = 88, ["2_06"] = 89, ["2_07"] = 90}
local CC_map_type_value = {}
CC_map_type_value[5] = {0,25,50,75,127}
CC_map_type_value[6] = {0,21,42,63,84,127}
CC_map_type_value[7] = {0,18,36,54,72,90,127}
local synth_max_type = {["1_05"] = 5, ["1_06"] = 7, ["1_07"] = 5,
                        ["2_05"] = 5, ["2_06"] = 6, ["2_07"] = 6}
-- Display constants
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
-- Pad numbers for binary display of BPM
local PADS_click = {"12", "11", "10", "09", "04", "03", "02", "01"}
-- Modifiers for binary pads
local PADS_click_bit_num = {}
PADS_click_bit_num["01"] = 8
PADS_click_bit_num["02"] = 7
PADS_click_bit_num["03"] = 6
PADS_click_bit_num["04"] = 5
PADS_click_bit_num["09"] = 4
PADS_click_bit_num["10"] = 3
PADS_click_bit_num["11"] = 2
PADS_click_bit_num["12"] = 1
local PADS_click_modif = {}
PADS_click_modif["01"] = 128
PADS_click_modif["02"] =  64
PADS_click_modif["03"] =  32
PADS_click_modif["04"] =  16
PADS_click_modif["09"] =   8
PADS_click_modif["10"] =   4
PADS_click_modif["11"] =   2
PADS_click_modif["12"] =   1
PADS_click_modif["13"] =  -1
PADS_click_modif["14"] =  -5
PADS_click_modif["15"] =   5
PADS_click_modif["16"] =   1
-- Pad numbers for binary display of synth types
local PADS_synth = {"16", "15", "14", "13"}
-- Codes for MIDI notes or CC sent by the Launchkey (InControl mode, decimal)
local cc_fns = {}  -- buttons which send control change events
local n_fns = {}   -- buttons which send note events
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

-- This function is used in the state section so is defined before it
function init_patch()
    local t = {}
    for param, value in pairs(INIT_PATCH) do
        t[param] = value
    end
    return t
end

-- State variables
local page = 0  -- can be any non negative integer
local halt_press = 0   -- to implement long press
local drums_mode = false     -- drums on higher notes of the kbd?
local parakick_mode = false  -- parallel kick on bass notes?
BPM = 60  -- global for access from midichief.c
local BPM_bits = {0, 0, 1, 1, 1, 1, 0, 0}  -- this is 60 too
local click_press = 0  -- to implement long press
local click_edit  = false  -- edit mode activated?
local click_mode  = 0   -- 0 nothing, 1 sound, 2 visual, 3 both
local click_note  = 42  -- HH by default
local click_lit   = false  -- to implement alternating LEDs
-- tweak synth sound
local synth_cur_line = 1     -- 1 is OSC FILT EG / 2 is MOD DELAY REV
                             -- used as the key of this next table
local synth_cur_pad  = {"05", "05"}  -- OSC and MOD (see below)
-- line .. "_" .. pad will be used as a key for this next table
local synth_cur_type = {["1_05"] = 1, ["1_06"] = 1, ["1_07"] = 1,
                        ["2_05"] = 1, ["2_06"] = 1, ["2_07"] = 1}
-- OSC=1_05   FILT=1_06   EG=1_07  /  MOD=2_05   DELAY=2_06   DELAY=2_07
-- patch handling
local pressed = {}  -- to implement long press for synth patches
-- current patch: pad and page
local synth_patch_pad  = nil
local synth_patch_page = nil
local current_patch = init_patch()

function click()
    print("BPM=", BPM)
    if click_mode == 0 then
        return
    end
    if click_mode == 1 or click_mode == 3 then
        note_on_off(1, CHAN_drums, click_note, 127)
        note_on_off(0, CHAN_drums, click_note, 127)
    end
    if click_mode == 2 or click_mode == 3 then
        click_lit = not click_lit
        if page == 0 then
            update_LEDs_visual_BPM()
        end
    end
end

function play_up_0(on_off)
    if on_off == 0 then  -- on release
        page = 1
        update_LEDs()
    end
end

function play_up_1(on_off)
    if on_off == 0 then  -- on release
        page = 2
        update_LEDs()
    end
end

function play_down_1(on_off)
    if on_off == 0 then  -- on release
        page = 0
        update_LEDs()
    end
end

function play_down_2(on_off)
    if on_off == 0 then  -- on release
        page = 1
        update_LEDs()
    end
end

function LED(where, color)
    note_on_off(0, CHAN_LK, LED_map[where], color)
    note_on_off(1, CHAN_LK, LED_map[where], color)
end

function update_LEDs_visual_BPM()
    if click_lit then
        LED("pad_08", APPLE)
    else
        LED("pad_08", BLACK)
    end
end

function update_LEDs_synth_patch()
    local pads = {}
    if page == 1 then
        pads = {"09", "10", "11", "12"}
    elseif page == 2 then
        pads = {"01", "02", "03", "04","05", "06", "07", "08",
                "09", "10", "11", "12","13", "14", "15", "16"}
    end
    for _, pad in ipairs(pads) do
        local filename = patch_filename(pad, page)
        if file_exists(filename) then
            LED("pad_"..pad, ORANGE)
        else
            LED("pad_"..pad, BLACK)
        end
    end
    if page == synth_patch_page then
        LED("pad_"..synth_patch_pad, GREEN)
    end
end

function update_LEDs()
    if page == 0 then
        -- click
        LED("play_up", BLACK)
        LED("play_down", YELLOW)
        LED("pad_05", click_colors[click_mode + 1])
        update_LEDs_visual_BPM()
        update_LEDs_BPM()
        -- right side of the page
        local pad_ids = {"06", "07", "13", "14", "15", "16"}
        for _, pad in pairs(pad_ids) do
            LED("pad_"..pad, BLACK)
        end
    elseif page == 1 then
        -- admin and synth
        LED("play_up", YELLOW)
        LED("play_down", BLACK)
        LED("pad_01", GREEN)
        if drums_mode then
            LED("pad_02", GREEN)
        else
            LED("pad_02", RED)
        end
        if parakick_mode then
            LED("pad_03", GREEN)
        else
            LED("pad_03", RED)
        end
        LED("pad_04", BLACK)
        update_LEDs_synth_patch()
        update_LEDs_synth()
    elseif page == 2 then
        -- patches
        LED("play_up", RED)
        LED("play_down", BLACK)
        update_LEDs_synth_patch()
    else
        LED("play_up", RED)
        LED("play_down", RED)
    end
end

function update_LEDs_BPM()
    for i, b in ipairs(BPM_bits) do
        if b > 0 then
            LED("pad_"..PADS_click[i], APPLE)
        else
            LED("pad_"..PADS_click[i], BLACK)
        end
    end
end

function update_LEDs_synth_type()
    local key = synth_cur_line.."_"..synth_cur_pad[synth_cur_line]
    local num_type = synth_cur_type[key]
    for i, b in ipairs(bits4(num_type)) do
        if b > 0 then
            LED("pad_"..PADS_synth[i], YELLOW)
        else
            LED("pad_"..PADS_synth[i], BLACK)
        end
    end
end

function update_LEDs_synth()
    LED("pad_05", BLACK)
    LED("pad_06", BLACK)
    LED("pad_07", BLACK)
    LED("pad_"..synth_cur_pad[synth_cur_line], GREEN)
    if synth_cur_line == 1 then
        LED("pad_08", APPLE)
    else
        LED("pad_08", ORANGE)
    end
    update_LEDs_synth_type()
end

function sleep(n)
    os.execute("sleep " .. (n/1000))
end

function incontrol()
    -- set the Launchkey in its InControl mode
    -- 1 for on, 0 for chan 0(1), note 12 and velo 127
    note_on_off(1, 0, 12, 127)
end

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
            if click_mode <= 1 then
                click_lit = false
            end
            update_LEDs()
        end
    end
end

function click_bin_modif(pad)
    local bit_num = PADS_click_bit_num[pad]
    local modif = PADS_click_modif[pad]
    if BPM_bits[bit_num] > 0 then
        BPM = BPM - modif
        BPM_bits[bit_num] = 0
    else
        BPM = BPM + modif
        BPM_bits[bit_num] = 1
    end
    update_LEDs_BPM()
end

function pad_01_0(on_off) if on_off == 0 then click_bin_modif("01") end end
function pad_02_0(on_off) if on_off == 0 then click_bin_modif("02") end end
function pad_03_0(on_off) if on_off == 0 then click_bin_modif("03") end end
function pad_04_0(on_off) if on_off == 0 then click_bin_modif("04") end end
function pad_09_0(on_off) if on_off == 0 then click_bin_modif("09") end end
function pad_10_0(on_off) if on_off == 0 then click_bin_modif("10") end end
function pad_11_0(on_off) if on_off == 0 then click_bin_modif("11") end end
function pad_12_0(on_off) if on_off == 0 then click_bin_modif("12") end end

function pad_06_0(on_off)
    -- half time
    if on_off == 1 then
        LED("pad_06", YELLOW)
    else
        LED("pad_06", BLACK)
        if BPM % 2 == 0 then
            local bpm = BPM_int(BPM/2)
            if bpm >= 10 then
                BPM = bpm
                BPM_bits = bits8(BPM)
                update_LEDs_BPM()
            end
        end
    end
end

function pad_07_0(on_off)
    -- double time
    if on_off == 1 then
        LED("pad_07", YELLOW)
    else
        LED("pad_07", BLACK)
        local bpm = BPM_int(BPM*2)
        if bpm <= 250 then
            BPM = bpm
            BPM_bits = bits8(BPM)
            update_LEDs_BPM()
        end
    end
end

function increment(pad, on_off)
    if on_off == 1 then
        LED("pad_"..pad, YELLOW)
    else
        LED("pad_"..pad, BLACK)
        local bpm = BPM + PADS_click_modif[pad]
        if 10 <= bpm and bpm <= 250 then
            BPM = bpm
            BPM_bits = bits8(BPM)
            update_LEDs_BPM()
        end
    end
end

function pad_13_0(on_off) increment("13", on_off) end
function pad_14_0(on_off) increment("14", on_off) end
function pad_15_0(on_off) increment("15", on_off) end
function pad_16_0(on_off) increment("16", on_off) end

function pad_08_0(on_off)
    -- tap tempo
    if on_off == 1 then
        LED("pad_08", RED)
        local old_BPM = BPM
        BPM = tap()
        if BPM ~= old_BPM then  -- midichief.c only allows BPM >= 30
            print("Tapped BPM=", BPM)
            BPM_bits = bits8(BPM)
            update_LEDs_BPM()
        end
    else
        LED("pad_08", BLACK)
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

function pad_02_1(on_off)
    -- drums high on the keyboard?
    if on_off == 1 then
        LED("pad_02", YELLOW)
    else
        drums_mode = not drums_mode
        if drums_mode then
            LED("pad_02", GREEN)
        else
            LED("pad_02", RED)
        end
    end
end

function pad_03_1(on_off)
    -- parallel kick for bass notes?
    if on_off == 1 then
        LED("pad_03", YELLOW)
    else
        parakick_mode = not parakick_mode
        if parakick_mode then
            LED("pad_03", GREEN)
        else
            LED("pad_03", RED)
        end
    end
end

function serializeTable(val, name)
    -- simplified version of
    -- https://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions
    local tmp = ""
    if name then tmp = tmp .. name .. " = " end
    if type(val) == "table" then
        tmp = tmp .. "{" .. "\n"
        for k, v in pairs(val) do
            k = "[\"" .. tostring(k) .. "\"]"
            tmp =  tmp .. serializeTable(v, k) ..  "," .. "\n"
        end
        tmp = tmp .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end

function patch_to_MIDI_content(patch)
    -- just a serialization for now
    return serializeTable(patch)
end

function MIDI_content_to_patch(content)
    -- just a deserialization for now
    return load("return "..content)()
end

function send_MIDI_content(content, chan)
    local patch = load("return "..content)()
    for param, value in pairs(patch) do
        if value ~= current_patch[param] then
            cc(chan, param, value)
            sleep(5)
        end
    end
end

function synth_pad(pad, on_off)
    if on_off == 1 then
        LED("pad_"..pad, YELLOW)
    else
        local key = synth_cur_line.."_"..synth_cur_pad[synth_cur_line]
        synth_cur_pad[synth_cur_line] = pad
        update_LEDs_synth()
    end
end

-- handling pads for synth control
function pad_05_1(on_off) synth_pad("05", on_off) end
function pad_06_1(on_off) synth_pad("06", on_off) end
function pad_07_1(on_off) synth_pad("07", on_off) end

function pad_08_1(on_off)
    if on_off == 1 then
        LED("pad_08", YELLOW)
    else
        synth_cur_line = synth_cur_line % 2 + 1  -- switch line
        update_LEDs_synth()
    end
end

function send_synth_type()
    local key = synth_cur_line.."_"..synth_cur_pad[synth_cur_line]
    local num_type = synth_cur_type[key]
    local max_type = synth_max_type[key]
    local param = CC_map_type_param[key]
    local value = CC_map_type_value[max_type][num_type]
    cc(CHAN_NTS, param, value)
    current_patch[param] = value
end

function scene_up_1(value)
    if value == 0 then  -- release
        local key = synth_cur_line.."_"..synth_cur_pad[synth_cur_line]
        local old = synth_cur_type[key]
        if old < synth_max_type[key] then
            synth_cur_type[key] = old + 1
            send_synth_type()
            update_LEDs_synth_type()
        end
    end
end

function scene_down_1(value)
    if value == 0 then  -- release
        local key = synth_cur_line.."_"..synth_cur_pad[synth_cur_line]
        local old = synth_cur_type[key]
        if old > 1 then
            synth_cur_type[key] = old - 1
            send_synth_type()
            update_LEDs_synth_type()
        end
    end
end

function bits4(n)
    -- Built-in synth types of the NTS are 5, 6 or 7
    -- Max supported is 16
    local t = {0, 0, 0, 0}
    for i = 1, 4 do
        r = n % 2
        t[i] = r
        n = (n-r) / 2
    end
    return t
end

function bits8(n)
    -- BPM from 10 to 250, so only 8 bits are necessary
    local t = {0, 0, 0, 0, 0, 0, 0, 0}
    for i = 1, 8 do
        r = n % 2
        t[i] = r
        n = (n-r) / 2
    end
    return t
end

function BPM_int(bpm)
    local int, part = math.modf(bpm)
    if part > .5 then
        return int+1
    else
        return int
    end
end

function pot_5_0(value)
    local old_BPM = BPM
    -- f(x) = ax^2 + bx + c
    -- f'(x) = 2ax + b
    -- f(0) = 10  =>  c = 10
    -- f'(0) = 1  =>  b = 1
    -- f(127) = 250  =>  16129a + 127*1 + 10 = 250  => a = 113/16129 ~ 0.007
    local bpm = BPM_int(0.007*value^2 + value + 10)
    if bpm ~= old_BPM then
        BPM = bpm
        BPM_bits = bits8(BPM)
        update_LEDs_BPM()
    end
end

function synth_pot(pot, value)
    local key = synth_cur_line.."_"..synth_cur_pad[synth_cur_line]
    param = CC_map[key][pot]
    cc(CHAN_NTS, param, value)
    current_patch[param] = value
end

function patch_filename(the_pad, the_page)
    return FILE_PREFIX .. "pad_"..the_pad.."_"..the_page..".btbs"
end

function patch(pad, on_off)
    if on_off == 1 then
        LED("pad_"..pad, YELLOW)
        pressed[pad] = os.time()
    else
        local release = os.time()
        local filename = patch_filename(pad, page)
        if pressed[pad] ~= nil and release - pressed[pad] >= 2 then
            -- switch off previous pad
            if synth_patch_pad ~= nil then
                LED("pad_"..synth_patch_pad, BLACK)
            end
            LED("pad_"..pad, RED)
            -- save
            local content = patch_to_MIDI_content(current_patch)
            save_content(content, filename)
            print(filename, "saved!")
            sleep(200)
        else
            -- load
            if file_exists(filename) then
                local content = load_content(filename)
                send_MIDI_content(content, CHAN_NTS)
                -- update the state: first the current patch
                current_patch = MIDI_content_to_patch(content)
                -- then the types of OSC FILT EG MOD DELAY REV
                for pad, param in pairs(CC_map_type_param) do
                    -- TODO: fix the mess about CC params
                    -- sometimes numbers, sometimes strings
                    local param_as_str = tostring(param)
                    local value = current_patch[param_as_str]
                    local max = synth_max_type[pad]
                    for i, v in ipairs(CC_map_type_value[max]) do
                        if v == value then
                            synth_cur_type[pad] = i
                            break
                        end
                    end
                end
                synth_patch_pad = pad
                synth_patch_page = page
                update_LEDs_synth()
            end
        end
        pressed[pad] = nil
        update_LEDs_synth_patch()
    end
end

function pad_09_1(on_off) patch("09", on_off) end
function pad_10_1(on_off) patch("10", on_off) end
function pad_11_1(on_off) patch("11", on_off) end
function pad_12_1(on_off) patch("12", on_off) end
function pad_01_2(on_off) patch("01", on_off) end
function pad_02_2(on_off) patch("02", on_off) end
function pad_03_2(on_off) patch("03", on_off) end
function pad_04_2(on_off) patch("04", on_off) end
function pad_05_2(on_off) patch("05", on_off) end
function pad_06_2(on_off) patch("06", on_off) end
function pad_07_2(on_off) patch("07", on_off) end
function pad_08_2(on_off) patch("08", on_off) end
function pad_09_2(on_off) patch("09", on_off) end
function pad_10_2(on_off) patch("10", on_off) end
function pad_11_2(on_off) patch("11", on_off) end
function pad_12_2(on_off) patch("12", on_off) end
function pad_13_2(on_off) patch("13", on_off) end
function pad_14_2(on_off) patch("14", on_off) end
function pad_15_2(on_off) patch("15", on_off) end
function pad_16_2(on_off) patch("16", on_off) end

-- handling pots for synth params
function pot_5_1(value) synth_pot(1, value) end
function pot_6_1(value) synth_pot(2, value) end
function pot_7_1(value) synth_pot(3, value) end
function pot_8_1(value) synth_pot(4, value) end

function on_note(on_off, chan, note, velo)
    if chan == 1 then
        -- chan 1(2) is from the Launchkey in normal mode, or the keys
        -- these notes are for the NTS and are meant to be bass notes
        -- except for the highest on the keyboard: drum sounds
        if drums_mode then
            if note == 68 then      -- HH
                note_on_off(on_off, CHAN_drums, NOTE_HH,   velo);
            elseif note == 70 then  -- kick
                note_on_off(on_off, CHAN_drums, NOTE_KICK, velo);
            elseif note == 72 then  -- snare
                note_on_off(on_off, CHAN_drums, NOTE_SN,   velo);
            elseif note == 71 then  -- open HH
                note_on_off(on_off, CHAN_drums, NOTE_O_HH, velo);
            elseif note == 69 then  -- crash
                note_on_off(on_off, CHAN_drums, NOTE_CRASH, velo);
            else
                note_on_off(on_off, chan, note-24, velo);
                if parakick_mode then
                    note_on_off(on_off, CHAN_drums, NOTE_KICK, velo);
                end
            end
        else
            note_on_off(on_off, chan, note-24, velo);
            if parakick_mode then
                note_on_off(on_off, CHAN_drums, NOTE_KICK, velo);
            end
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
            note_on_off(on_off, 9, 36, velo);
        -- and to translate HH 2e 46 to HH 2a 42
        elseif note == 46 then
            note_on_off(on_off, 9, 42, velo);
        else
            note_on_off(on_off, chan, note, velo);
        end
    else
        -- forward
        note_on_off(on_off, chan, note, velo);
    end
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
        panic()  -- includes update_LEDs()
        melody_up()
    else
        -- forward
        pc(chan, val)
    end
end

function panic()
    print("PANIC!")
    -- all notes off
    cc(CHAN_NTS, 123, 0)  -- not sure it works...
    -- manual all notes off
    for n = 0, 127 do
        note_on_off(0, CHAN_NTS, n, 127);
        note_on_off(0, CHAN_drums, n, 127);
    end
    -- reset synth params
    for param, value in pairs(INIT_PATCH) do
        cc(CHAN_NTS, param, value)
    end
    -- note off events blacken LEDs so we have to update everything
    update_LEDs()
end

function melody_down()
    note_on_off(1, CHAN_NTS, 72, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS, 72, 120)
    note_on_off(1, CHAN_NTS, 67, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS, 67, 120)
    note_on_off(1, CHAN_NTS, 64, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS, 64, 120)
    note_on_off(1, CHAN_NTS, 60, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS, 60, 120)
end

function melody_up()
    note_on_off(1, CHAN_NTS,  60, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS,  60, 120)
    note_on_off(1, CHAN_NTS,  64, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS,  64, 120)
    note_on_off(1, CHAN_NTS,  67, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS,  67, 120)
    note_on_off(1, CHAN_NTS,  72, 120)
    sleep(200)
    note_on_off(0, CHAN_NTS,  72, 120)
end

function save_content(content, filename)
    local file, err = io.open(filename, 'w')
    if file then
        file:write(content)
        file:close()
    else
        print("error saving content:", err)
    end
end

-- https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua
function file_exists(filename)
    local f = io.open(filename, "rb")
    if f then f:close() end
    return f ~= nil
end

-- get all lines from a file as a string
function load_content(filename)
    if not file_exists(filename) then return "" end
    local lines = ""
    for line in io.lines(filename) do
        lines = lines .. line
    end
    return lines
end
