print("BotBoss Lua definitions")

function click()
    print("click from Lua", BPM)
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

function send_note(on_off, chan, note, velo)
    if on_off == 1 then
        note_on(chan, note, velo)
    else
        note_off(chan, note, velo)
    end
end

function handle_note(on_off, chan, note, velo)
    if chan == 9 then
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
        -- other notes are meant to be bass notes
        send_note(on_off, chan, note-24, velo);
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
        local new_param = CC_map[param]
        if new_param ~= nil then
            param = new_param
        end
    end
    cc(chan, param, val)
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
