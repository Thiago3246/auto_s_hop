-- Verificação para impedir execuções duplicadas
if _G.ServerHopPlayerFinder then
    return
end

pcall(function() getgenv().ServerHopPlayerFinder = true end)

-- Verifica se o jogo já foi carregado
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Configurações e serviços
local playerNameToFind = "NomeDoJogador" -- Substitua pelo Username do jogador desejado (não o Display Name)
local checkInterval = 3 -- Tempo de verificação inicial (segundos)
local recheckDelay = 5 -- Tempo extra para verificar se realmente mudou de servidor
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = game.Players.LocalPlayer
local PlaceId = game.PlaceId
local currentJobId = game.JobId

-- URL onde seu script está hospedado (substitua pela URL real)
local teleportScriptURL = "https://raw.githubusercontent.com/Thiago3246/auto_s_hop/refs/heads/main/auto_s_hop.lua"

-- Função para enfileirar o script para execução após o teleporte
local function queueScriptOnTeleport()
    local codeToQueue = "loadstring(game:HttpGet('" .. teleportScriptURL .. "', true))()"
    queue_on_teleport(codeToQueue)
end

-- Função para exibir uma mensagem temporária na tela
local function showMessage(text)
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    local TextLabel = Instance.new("TextLabel", ScreenGui)
    
    TextLabel.Size = UDim2.new(0, 300, 0, 50)
    TextLabel.Position = UDim2.new(0.5, -150, 0.4, 0) -- Um pouco acima do centro da tela
    TextLabel.BackgroundTransparency = 0.5
    TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.TextSize = 20
    TextLabel.Text = text

    -- Remove a mensagem após 3 segundos
    game:GetService("Debris"):AddItem(ScreenGui, 3)
end

-- Função para verificar se o jogador está presente no servidor
local function findPlayer()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Name == playerNameToFind then -- Usa o Username, não o Display Name
            showMessage(playerNameToFind .. " encontrado!")
            return true
        end
    end
    return false
end

-- Função para buscar um novo servidor e realizar o server hop
local function serverHop()
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", PlaceId)
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and response and response.data then
        for _, server in ipairs(response.data) do
            if server.id ~= currentJobId then
                -- Enfileira o script para execução após o teleporte
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
    else
        warn("Erro ao obter servidores")
    end
end

-- Loop de verificação dos jogadores por checkInterval segundos
local function checkForPlayer()
    local found = false
    local startTime = tick()
    
    while tick() - startTime < checkInterval do
        if findPlayer() then
            found = true
            break
        end
        wait(0.5) -- Verifica a cada meio segundo
    end

    -- Se o jogador não for encontrado, tenta o server hop
    if not found then
        serverHop()

        -- Espera recheckDelay segundos para verificar se o teleporte ocorreu
        wait(recheckDelay)
        if game.JobId == currentJobId then
            warn("Ainda no mesmo servidor após teleportar. Tentando novamente...")
            serverHop()
        end
    end
end

-- Inicia a verificação do jogador
checkForPlayer()
