if _G.ServerHopPlayerFinder then
    return
end

pcall(function() getgenv().ServerHopPlayerFinder = true end)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Se o PlayerName ainda não foi definido após um teleporte, recupera da queue_on_teleport
if not getgenv().PlayerName or getgenv().PlayerName == "" then
    warn("Erro: Você deve definir getgenv().PlayerName antes de rodar o script!")
    return
end

local playerNameToFind = getgenv().PlayerName

local checkInterval = 3
local recheckDelay = 5
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = game.Players.LocalPlayer
local PlaceId = game.PlaceId
local currentJobId = game.JobId

local function queueScriptOnTeleport()
    queue_on_teleport("getgenv().PlayerName = '" .. playerNameToFind .. "'\nloadstring(game:HttpGet('https://raw.githubusercontent.com/Thiago3246/auto_s_hop/refs/heads/main/auto_s_hop.lua', true))()")
end

local function showMessage(text)
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    local TextLabel = Instance.new("TextLabel", ScreenGui)
    
    TextLabel.Size = UDim2.new(0, 300, 0, 50)
    TextLabel.Position = UDim2.new(0.5, -150, 0.4, 0)
    TextLabel.BackgroundTransparency = 0.5
    TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.TextSize = 20
    TextLabel.Text = text

    game:GetService("Debris"):AddItem(ScreenGui, 3)
end

local function findPlayer()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Name == playerNameToFind then
            showMessage(playerNameToFind .. " encontrado!")
            return true
        end
    end
    return false
end

local function getAvailableServers()
    while true do
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", PlaceId)
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and response and response.data and #response.data > 0 then
            return response.data
        else
            warn("Erro ao obter servidores. Tentando novamente...")
            task.wait(1)
        end
    end
end

local function serverHop()
    local servers = getAvailableServers()

    for _, server in ipairs(servers) do
        if server.id ~= currentJobId then
            queueScriptOnTeleport()
            
            local teleportSuccess, errorMsg = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            end)
            
            if teleportSuccess then
                return
            else
                warn("Erro ao teleportar: " .. errorMsg)
            end
        end
    end
end

local function checkForPlayer()
    local found = false
    local startTime = tick()
    
    while tick() - startTime < checkInterval do
        if findPlayer() then
            found = true
            break
        end
        task.wait(0.5)
    end

    if not found then
        serverHop()

        task.wait(recheckDelay)
        if game.JobId == currentJobId then
            warn("Ainda no mesmo servidor após teleportar. Tentando novamente...")
            serverHop()
        end
    end
end

checkForPlayer()
