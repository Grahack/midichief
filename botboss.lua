print("BotBoss Lua definitions")

--     OSC      53  FILT     42  EG      14  MOD   88    DELAY 89  REV   90
-- A   SHAPE    54  CUTOFF   43  ATTACK  16  SPEED 28    TIME  30  TIME  34
-- B   ALT      55  RESO     44  RELEASE 19  DEPTH 29    DEPTH 31  DEPTH 35
-- A+  FREQ LFO 24  FREQ cs  46  FREQ t  21     X           X         X
-- B+  DEPTH    26  DEPTH cs 45  DEPTH t 20     X        MIX   33  MIX   36
--     pitch/shape  cutoff sweep trem

local CC_map = {}
CC_map[ 90] = 52  -- test
CC_map[100] = 52
-- ...

function on_note_on(chan, note, velo)
    if chan==9 and note == 69 then
        print("ON chan 9 and note 69")
    else
        note_on(chan, note, velo);
    end
end

function on_note_off(chan, note, velo)
    if chan==9 and note == 69 then
        print("OFF chan 9 and note 69")
    else
        note_off(chan, note, velo);
    end
end

function on_cc(chan, param, val)
    if chan==0 then
        cc(chan, CC_map[param], val);
    else
        cc(chan, param, val);
    end
end
