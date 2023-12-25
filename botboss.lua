print("BotBoss Lua definitions")

function on_note_on(chan, note, velo)
    if chan==9 then print("chan 9") end
    print("on_note_on code", chan, note, velo)
end

function on_note_off(chan, note, velo)
    if chan==9 then print("chan 9") end
    print("on_note_off code", chan, note, velo)
end
