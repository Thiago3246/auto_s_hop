if _G.ServerHopPlayerFinder then
    return
end

pcall(function() getgenv().ServerHopPlayerFinder = true end)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not getgenv().PlayerName or getgenv().PlayerName == "" then
    warn("[Erro] Você deve definir getgenv().PlayerName antes de rodar o script!")
    return
end

local playerNameToFind = getgenv().PlayerName
local checkInterval = 5
local recheckDelay = 3
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
        print("[DEBUG] Obtendo lista de servidores de:", url)

        local success, response = pcall(function()
            local res = game:HttpGet(url)
            return HttpService:JSONDecode(res), res
        end)

        if success and response and response[1] and response[1].data then
            print("[DEBUG] Servidores obtidos com sucesso! Quantidade de servidores:", #response[1].data)
            return response[1].data
        else
            print("[ERRO] Falha ao obter servidores!")

            if not success then
                warn("[ERRO] Falha na requisição HTTP. Possível motivo: Exploit incompatível ou falha na API.")
            elseif not response then
                warn("[ERRO] Resposta vazia da API.")
            elseif response[2] then
                warn("[ERRO] Resposta completa da API:\n", response[2])
            else
                warn("[ERRO] Resposta da API não contém 'data'. Estrutura inesperada.")
            end
            
            task.wait(2)
        end
    end
end

local function serverHop()
    local servers = getAvailableServers()

    for _, server in ipairs(servers) do
        if server.id ~= currentJobId then
            print("[DEBUG] Tentando teleportar para o servidor:", server.id)

            queueScriptOnTeleport()
            
            local teleportSuccess, errorMsg = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            end)
            
            if teleportSuccess then
                print("[DEBUG] Teleporte bem-sucedido para:", server.id)
                return
            else
                warn("[ERRO] Falha ao teleportar para o servidor:", server.id)
                warn("[ERRO] Mensagem de erro:", errorMsg)
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
        print("[DEBUG] Jogador não encontrado. Fazendo server hop...")
        serverHop()

        task.wait(recheckDelay)
        if game.JobId == currentJobId then
            warn("[ERRO] Ainda no mesmo servidor após tentar teleportar. Tentando novamente...")
            serverHop()
        end
    else
        print("[DEBUG] Jogador encontrado! Permanecendo no servidor.")
    end
end

checkForPlayer()
