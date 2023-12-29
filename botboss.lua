print("BotBoss Lua definitions")

-- Used to play melodies
function sleep(n)
    os.execute("sleep " .. (n/1000))
end

local LAST_HALT_PRESS = 0  -- to implement a kind of double tap

--     OSC      53  FILT     42  EG      14  MOD   88    DELAY 89  REV   90
-- A   SHAPE    54  CUTOFF   43  ATTACK  16  SPEED 28    TIME  30  TIME  34
-- B   ALT      55  RESO     44  RELEASE 19  DEPTH 29    DEPTH 31  DEPTH 35
-- A+  FREQ LFO 24  FREQ cs  46  FREQ t  21     X           X         X
-- B+  DEPTH    26  DEPTH cs 45  DEPTH t 20     X        MIX   33  MIX   36
--     pitch/shape  cutoff sweep trem

local CC_map = {}
CC_map[100] = 52
CC_map[101] = 53
CC_map[102] = 54
CC_map[103] = 23
CC_map[104] = 25

CC_map[105] = 41
CC_map[106] = 42
CC_map[107] = 43
CC_map[108] = 45
CC_map[109] = 44

CC_map[110] = 15
CC_map[111] = 18

CC_map[112] = 89
CC_map[113] = 33
CC_map[114] = 34
CC_map[115] = 35

function on_note_on(chan, note, velo)
    if chan==9 and note == 69 then
        print("ON chan 9 and note 69")
    else
        note_on(chan, note-24, velo);
    end
end

function on_note_off(chan, note, velo)
    if chan==9 and note == 69 then
        print("OFF chan 9 and note 69")
    else
        note_off(chan, note-24, velo);
    end
end

function on_cc(chan, param, val)
    if chan==0 then
        local new_param = CC_map[param]
        if new_param ~= nil then
            param = new_param
        end
    end
    cc(chan, param, val)
end

function on_pc(chan, val)
    if chan == 15 and val == 115 then
        reload_rules()
        -- all notes off
        for n = 0, 127 do
            note_off(0, n, 127);
            print("note off chan 1:", n)
        end
    elseif chan == 15 and val == 116 then
        print("HALT attempt")
        -- double tap emulation
        local THIS_HALT_PRESS = os.time()
        if THIS_HALT_PRESS - LAST_HALT_PRESS == 0 then
            print("HALT")
            note_on(0, 72, 120)
            sleep(200)
            note_off(0, 72, 120)
            note_on(0, 67, 120)
            sleep(200)
            note_off(0, 67, 120)
            note_on(0, 64, 120)
            sleep(200)
            note_off(0, 64, 120)
            note_on(0, 60, 120)
            sleep(200)
            note_off(0, 60, 120)
            os.execute("sudo halt")
        else
            LAST_HALT_PRESS = THIS_HALT_PRESS
        end
    elseif chan == 15 and val == 127 then
        -- Play a melody at startup
        note_on(0, 60, 120)
        sleep(200)
        note_off(0, 60, 120)
        note_on(0, 64, 120)
        sleep(200)
        note_off(0, 64, 120)
        note_on(0, 67, 120)
        sleep(200)
        note_off(0, 67, 120)
        note_on(0, 72, 120)
        sleep(200)
        note_off(0, 72, 120)
    else
        pc(chan, val)
    end
end
