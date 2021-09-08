do
    local success, script = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Vortex1003/Vortex-Hub/games/main/" .. game.GameId .. ".lua")
    end)

    if (success) then
        loadstring(script)()
    end
end
