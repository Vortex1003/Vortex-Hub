-- services
local players = game:GetService("Players")
local replicatedFirst = game:GetService("ReplicatedFirst")
local coreGui = game:GetService("CoreGui")
local runService = game:GetService("RunService")

-- cache
local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()
local currentCamera = workspace.CurrentCamera
local hitBoxes = { "Head", "Torso" }

-- libaries
local library = {
    ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vortex1003/Vortex-Hub/main/libraries/ui.lua"))(),
    flags = {},
    connections = {},
    drawings = {}
}

-- framework
local framework = {}; do
    -- modules
    for i,v in pairs(getgc(true)) do
        if typeof(v) == "table" then
            if rawget(v, "send") then
                framework.network = v
            elseif rawget(v, "basecframe") then
                framework.camera = v
            elseif rawget(v, "setmovementmode") then
                framework.char = v
            elseif rawget(v, "gammo") then
                framework.gamelogic = v
            elseif rawget(v, "thickcastplayers") then
                framework.replication = v
                framework.chartable = debug.getupvalue(v.getbodyparts, 1)
                framework.characters = debug.getupvalue(v.getplayerhit, 1)
            end
        end
    end

    framework.physics = require(replicatedFirst.SharedModules.Old.Utilities.Math.physics:Clone())

    -- utility functions
    function framework:addConnection(con, func)
        local connection = con:Connect(func)
        table.insert(library.connections, #library.connections + 1, connection)
        return connection
    end

    function framework:removeConnections()
        for i,v in pairs(library.connections) do
            v:Disconnect()
        end
    end

    function framework:addDrawing(class, properties)
        local object = Drawing.new(class)

        if properties then
            for i,v in pairs(properties) do
                object[i] = v
            end
        end

        table.insert(library.drawings, #library.drawings + 1, object)

        return object
    end

    function framework:removeDrawings()
        for i,v in pairs(library.drawings) do
            v:Remove()
        end
    end

    -- main functions
    function framework:getClosest(fov)
        local target, closest = nil, fov or math.huge

        for i,v in pairs(players:GetPlayers()) do
            if v ~= localPlayer and v.Team ~= localPlayer.Team then
                if self.chartable[v] then
                    local screenPos, onScreen = currentCamera:WorldToScreenPoint(self.chartable[v].head.Position)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude

                    if onScreen and dist < closest then
                        dist = closest
                        target = v
                    end
                end
            end
        end

        return target
    end

    function framework:moveMouse(x, y)
        local pi = math.pi
        local sensitivity = self.camera.sensitivity * self.camera.sensitivitymult * math.atan(math.tan(self.camera.basefov * (pi / 180) / 2) / 2.718281828459045 ^ self.camera.magspring.p) / (32 * pi)
        local x, y = self.camera.angles.x - sensitivity * y * self.camera.xinvert, self.camera.angles.y - sensitivity * x
        local newAngles = Vector3.new(math.clamp(x, self.camera.minangle, self.camera.maxangle), y)
        local deltaTime = debug.getupvalue(self.camera.step, 2)

        self.camera.delta = (newAngles - self.camera.angles) / deltaTime
        self.camera.angles = newAngles
    end
end

-- legit
do
    local fovCircle = framework:addDrawing("Circle")

    framework:addConnection(runService.Heartbeat, function()
        fovCircle.Visible = library.flags.legit_aimbot_enabled and library.flags.legit_aimbot_showfov or false
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 36)
        fovCircle.Radius = library.flags.legit_aimbot_fov or 0
        fovCircle.Color = library.flags.legit_aimbot_fovcolor or Color3.new(1, 1, 1)
        fovCircle.Thickness = library.flags.legit_aimbot_fovthickness or 1
        fovCircle.Transparency = (library.flags.legit_aimbot_fovtransparency or 100) / 100
        fovCircle.NumSides = library.flags.legit_aimbot_fovnumsides or 48

        if framework.char.alive and library.flags.legit_aimbot_enabled then
            if framework.gamelogic.currentgun and framework.gamelogic.currentgun.isaiming() then
                local target = framework:getClosest(library.flags.legit_aimbot_fov)

                if target and framework.chartable[target] then
                    local hitbox = library.flags.legit_aimbot_hitbox or "Head"

                    if hitbox == "Random" then
                        hitbox = hitBoxes[math.random(1, #hitBoxes)]
                    end

                    hitbox = string.lower(hitbox)

                    local screenPos, onScreen = currentCamera:WorldToScreenPoint(framework.chartable[target].head.Position)
                    local smoothing = math.clamp(library.flags.legit_aimbot_smoothing or 3, 3, 100)
                    local x, y = (screenPos.X - mouse.X) / smoothing, (screenPos.Y - mouse.Y) / smoothing

                    if onScreen then
                        framework:moveMouse(x, y)
                    end
                end
            end
        end
    end)

    local function createHitboxLoop(player, character)
        if player == localPlayer or player.Team == localPlayer.Team then
            return
        end

        local parts = {}
        local originalSizes = {}

        for i,v in pairs(character:GetChildren()) do
            if not v.Name:find("Humanoid") and v:IsA("BasePart") then
                table.insert(parts, v)
                originalSizes[v.Name] = v.Size
            end
        end

        local connection; connection = framework:addConnection(runService.Heartbeat, function()
            if not character then
                connection:Disconnect()
                return
            end

            for i,v in pairs(parts) do
                local size = library.flags.legit_hitboxexpander_size or 1
                v.Size = library.flags.legit_hitboxexpander_enabled and Vector3.new(size, size, size) or originalSizes[v.Name]
            end
        end)
    end

    local function startLoop(character)
        createHitboxLoop(framework.characters[character], character)
    end

    framework:addConnection(workspace.Players.Ghosts.ChildAdded, startLoop)
    framework:addConnection(workspace.Players.Phantoms.ChildAdded, startLoop)

    for i,v in pairs(workspace.Players.Ghosts:GetChildren()) do
        startLoop(v)
    end

    for i,v in pairs(workspace.Players.Phantoms:GetChildren()) do
        startLoop(v)
    end
end

-- ui
local window = library.ui:Window("VORTΞX HUB", "Phantom Forces", "PF")
local homeTab = window:Tab("Home")
local legitTab = window:Tab("Legit")
--[[local rageTab = window:Tab("Rage")
local gunModsTab = window:Tab("Gun Mods")
local espTab = window:Tab("Esp")
local characterTab = window:Tab("Character")
local miscTab = window:Tab("Misc")--]]
local settingsTab = window:Tab("Settings")

-- home
homeTab:Label("Made by Vortex1003 at https://github.com/Vortex1003")

-- legit
legitTab:Label("Aimbot")

legitTab:Toggle("Enable", function(state)
    library.flags.legit_aimbot_enabled = state
end)

legitTab:Dropdown("Hitbox", { "Head", "Torso", "Random" }, function(option)
    library.flags.legit_aimbot_hitbox = option
end)

legitTab:Slider("Fov", 0, 800, 0, function(value)
    library.flags.legit_aimbot_fov = value
end)

legitTab:Slider("Smoothing", 0, 100, 0, function(value)
    library.flags.legit_aimbot_smoothing = value
end)

legitTab:Toggle("Show Fov", function(state)
    library.flags.legit_aimbot_showfov = state
end)

legitTab:Label("Fov Settings")

legitTab:Colorpicker("Color", Color3.new(1, 1, 1), function(color)
    library.flags.legit_aimbot_fovcolor = color
end)

legitTab:Slider("Thickness", 1, 5, 0, function(value)
    library.flags.legit_aimbot_fovthickness = value
end)

legitTab:Slider("Transparency", 0, 100, 100, function(value)
    library.flags.legit_aimbot_fovtransparency = value
end)

legitTab:Slider("NumSides", 0, 48, 48, function(value)
    library.flags.legit_aimbot_fovnumsides = value
end)

legitTab:Label("Hitbox Expander")

legitTab:Toggle("Enable", function(state)
    library.flags.legit_hitboxexpander_enabled = state
end)

legitTab:Slider("Size", 1, 5, 1, function(value)
    library.flags.legit_hitboxexpander_size = value
end)

-- settings
settingsTab:Button("Destroy UI", function()
    coreGui.Library:Destroy()
    framework:removeConnections()
    framework:removeDrawings()
end)

settingsTab:Label("Press RightControl to toggle UI")
