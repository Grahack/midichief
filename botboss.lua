print("BotBoss Lua definitions")

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
