-- ============================================================
-- 1. نظام فك الحماية (Bypass) وإخفاء الإكسبلويت
-- ============================================================
if getgenv then getgenv().identifyexecutor = nil end
if getfenv then getfenv().identifyexecutor = nil end

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- تجاوز شاشات التحميل وإنشاء الشخصية
pcall(function()
    local TransitionModule = require(RS.Modules.Game.UI.TransitionUI)
    TransitionModule.transition = function() return end
end)
pcall(function()
    local CharCreator = require(RS.Modules.Game.CharacterCreator.CharacterCreator)
    if CharCreator.start then
        CharCreator.start = function(...) while true do task.wait(1) end end
    end
end)

-- حذف الأبواب والمعوقات لتسهيل الـ Pathfinding
for _, v in pairs(workspace:GetDescendants()) do
    if v.Name == "DoorSystem" or v.Name == "BasementDoor" or v.Name == "VehicleBlockers" then
        v:Destroy()
    end
end

-- حذف المقاعد غير المحمية لتجنب التعطيل
local VehiclesFolder = workspace:FindFirstChild("Vehicles")
local protectedVehicles = {}
if VehiclesFolder then
    for _, model in ipairs(VehiclesFolder:GetDescendants()) do
        if model:IsA("VehicleSeat") and model.Name == "DriverSeat" then
            local vehicle = model:FindFirstAncestorOfClass("Model")
            if vehicle then protectedVehicles[vehicle] = true end
        end
    end
end
for _, seat in ipairs(workspace:GetDescendants()) do
    if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
        local vehicle = seat:FindFirstAncestorOfClass("Model")
        if not (vehicle and protectedVehicles[vehicle]) then
            seat:Destroy()
        end
    end
end

-- ============================================================
-- 2. إعدادات القائمة والواجهة (Fluent)
-- ============================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "By",
    SubTitle = "Real",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local FishTab = Window:AddTab({ Title = "FishFarm", Icon = "fish" })
local DevTab = Window:AddTab({ Title = "Dev", Icon = "code" })
local AntiKickTab = Window:AddTab({ Title = "Anti-Kick", Icon = "shield" })
local ServerTab = Window:AddTab({ Title = "Server", Icon = "server" })

local IsFarmingActive = false
local Config = { StopWalking = false, Running = false, Respawn = false }
local AntiKickEnabled = false
local IsUnderground = false

local ServerSwitchEnabled = false
local ServerSwitchInterval = 30
local LastServerSwitchTime = tick()

local LastActivityTime = tick()
local LastCheckedPosition = Vector3.new(0, 0, 0)
local IdleThreshold = 600

local function UpdateActivity()
    LastActivityTime = tick()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        LastCheckedPosition = char.HumanoidRootPart.Position
    end
end

-- ============================================================
-- 3. عناصر القائمة
-- ============================================================
FishTab:AddSection("إعدادات المعدات")
local AutoBuyToggle = FishTab:AddToggle("AutoBuyEnabled", {
    Title = "تفعيل شراء المعدات تلقائياً",
    Description = "يشتري الناقص فقط عند انتهاء الطعم",
    Default = true
})
local RodDropdown = FishTab:AddDropdown("RodSelect", {
    Title = "نوع السنارة",
    Values = {"Smart Select", "FishingRodUltimate", "FishingRodAdvanced", "FishingRodPro", "FishingRodRegular"},
    Multi = false,
    Default = "Smart Select"
})
local BaitDropdown = FishTab:AddDropdown("BaitSelect", {
    Title = "نوع الطعم",
    Values = {"Smart Select", "PrawntecUltimate", "PrawntecPro", "WormtecUltimate", "WormtecPro", "WormtecRegular"},
    Multi = false,
    Default = "Smart Select"
})
local BaitAmount = FishTab:AddSlider("BaitAmount", {
    Title = "الحد الأقصى للطعم",
    Min = 1,
    Max = 100,
    Rounding = 1,
    Default = 10
})

FishTab:AddSection("الحركة والسرعة")
local WalkSpeedSlider = FishTab:AddSlider("WalkSpeed", {
    Title = "سرعة المشي",
    Min = 10,
    Max = 100,
    Rounding = 1,
    Default = 20
})

FishTab:AddSection("منطقة الصيد")
local ZoneDropdown = FishTab:AddDropdown("ZoneSelect", {
    Title = "المستوى",
    Values = {"Level 40 +", "Level 70 +"},
    Multi = false,
    Default = "Level 70 +"
})

FishTab:AddSection("التحكم")
FishTab:AddButton({
    Title = "تشغيل Auto Farm (لا نهائي)",
    Callback = function()
        if not IsFarmingActive then
            IsFarmingActive = true
            UpdateActivity()
            task.spawn(StartAutoFarm)
        end
    end
})
FishTab:AddToggle("StopFarmToggle", {
    Title = "إيقاف فوري",
    Default = false,
    Callback = function(Value)
        if Value then
            IsFarmingActive = false
            Config.StopWalking = true
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        else
            Config.StopWalking = false
        end
    end
})

FishTab:AddSection("إعدادات إضافية")
FishTab:AddToggle("RespawnToggle", {
    Title = "إعادة إحياء تلقائي (Auto Respawn)",
    Description = "يعيد إحياءك تلقائياً عند الموت ويكمل الفارم",
    Default = true,
    Callback = function(Value)
        Config.Respawn = Value
    end
})

AntiKickTab:AddSection("مانع الطرد")
AntiKickTab:AddToggle("AntiKickToggle", {
    Title = "تفعيل مانع الطرد",
    Description = "يمنع الطرد التلقائي كل 15 دقيقة",
    Default = false,
    Callback = function(Value)
        AntiKickEnabled = Value
        if Value then
            task.spawn(AntiKickLoop)
        end
    end
})

ServerTab:AddSection("تغيير السيرفر التلقائي")
ServerTab:AddToggle("ServerSwitchToggle", {
    Title = "تفعيل تغيير السيرفر التلقائي",
    Description = "يغير السيرفر تلقائياً للسيرفر الأقل لاعبين",
    Default = false,
    Callback = function(Value)
        ServerSwitchEnabled = Value
        if Value then
            LastServerSwitchTime = tick()
        end
    end
})
ServerTab:AddSlider("ServerSwitchIntervalSlider", {
    Title = "الفترة بين التغيير (دقائق)",
    Min = 5,
    Max = 120,
    Rounding = 1,
    Default = 30,
    Callback = function(Value)
        ServerSwitchInterval = Value
    end
})
ServerTab:AddButton({
    Title = "🎯 Hop Server (Low Player) - الآن",
    Callback = function()
        task.spawn(SwitchToSmallestServer)
    end
})
ServerTab:AddButton({
    Title = "🔄 Rejoin نفس السيرفر",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end
})

ServerTab:AddSection("💾 إدارة الإعدادات")
ServerTab:AddButton({
    Title = "💾 حفظ الإعدادات",
    Callback = function() SaveConfig() end
})
ServerTab:AddButton({
    Title = "📂 تحميل الإعدادات",
    Callback = function() LoadConfig() end
})
ServerTab:AddButton({
    Title = "🗑️ حذف الإعدادات",
    Callback = function() DeleteConfig() end
})

DevTab:AddButton({
    Title = "Discord",
    Callback = function()
        setclipboard("https://discord.gg/bd9vDqc8wk")
    end
})

-- ============================================================
-- 4. الخدمات والموديولات الرسمية
-- ============================================================
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local Client = Players.LocalPlayer
local Character = Client.Character or Client.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local PlayerGui = Client:WaitForChild("PlayerGui")
local Backpack = Client:WaitForChild("Backpack")

Client.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid = c:WaitForChild("Humanoid")
    RootPart = c:WaitForChild("HumanoidRootPart")
    Backpack = Client:WaitForChild("Backpack")
    IsUnderground = false
    UpdateActivity()
end)

local Net_upvr = require(RS.Modules.Core.Net)
local Data_upvr = require(RS.Modules.Core.Data)
local Util_upvr = require(RS.Modules.Core.Util)

local ShopLocation = Vector3.new(-135.802, 251.81, 153.361)
local SellBeaconPos = Vector3.new(-252.746, 252.839, 379.64)

local Zones = {
    ["Level 40 +"] = {
        Pos = Vector3.new(-487.582, 243.031, 821.429),
        CastPos = nil
    },
    ["Level 70 +"] = {
        SurfacePos = Vector3.new(5.618, 250.901, 671.135),
        UndergroundPos = Vector3.new(5.618, 240.915, 670.612),
        Pos = Vector3.new(5.618, 250.901, 671.135),
        CastPos = Vector3.new(82.113189697266, 245.16184997559, 922.22076416016)
    }
}

local FishingRods = {
    {Name = "FishingRodUltimate", Level = 60, Price = 5000},
    {Name = "FishingRodAdvanced", Level = 35, Price = 2300},
    {Name = "FishingRodPro", Level = 20, Price = 800},
    {Name = "FishingRodRegular", Level = 1, Price = 100}
}
local FishingBaits = {
    {Name = "PrawntecUltimate", Level = 45, Price = 45},
    {Name = "PrawntecPro", Level = 30, Price = 40},
    {Name = "PrawntecRegular", Level = 25, Price = 35},
    {Name = "WormtecUltimate", Level = 15, Price = 30},
    {Name = "WormtecPro", Level = 8, Price = 25},
    {Name = "WormtecRegular", Level = 1, Price = 20}
}

-- ============================================================
-- 5. نظام حفظ وتحميل Config
-- ============================================================
local ConfigPath = "UPVR_Fishing_Config.json"
function SaveConfig()
    local configData = {
        AutoBuyEnabled = AutoBuyToggle.Value,
        RodSelect = RodDropdown.Value,
        BaitSelect = BaitDropdown.Value,
        BaitAmount = BaitAmount.Value,
        WalkSpeed = WalkSpeedSlider.Value,
        ZoneSelect = ZoneDropdown.Value,
        Respawn = Config.Respawn,
        AntiKick = AntiKickEnabled,
        ServerSwitch = ServerSwitchEnabled,
        ServerSwitchInterval = ServerSwitchInterval,
        AutoFarmActive = IsFarmingActive
    }
    pcall(function()
        writefile(ConfigPath, HttpService:JSONEncode(configData))
    end)
end

function LoadConfig()
    local success, err = pcall(function()
        if not isfile(ConfigPath) then return false end
        local data = HttpService:JSONDecode(readfile(ConfigPath))
        if data.AutoBuyEnabled ~= nil then AutoBuyToggle:Set(data.AutoBuyEnabled) end
        if data.RodSelect then RodDropdown:Set(data.RodSelect) end
        if data.BaitSelect then BaitDropdown:Set(data.BaitSelect) end
        if data.BaitAmount then BaitAmount:Set(data.BaitAmount) end
        if data.WalkSpeed then WalkSpeedSlider:Set(data.WalkSpeed) end
        if data.ZoneSelect then ZoneDropdown:Set(data.ZoneSelect) end
        if data.Respawn ~= nil then Config.Respawn = data.Respawn end
        if data.AntiKick ~= nil then AntiKickEnabled = data.AntiKick end
        if data.ServerSwitch ~= nil then ServerSwitchEnabled = data.ServerSwitch end
        if data.ServerSwitchInterval then ServerSwitchInterval = data.ServerSwitchInterval end
        if data.AutoFarmActive then
            IsFarmingActive = true
            UpdateActivity()
            task.spawn(StartAutoFarm)
        end
        if AntiKickEnabled then task.spawn(AntiKickLoop) end
        return true
    end)
    return false
end

function DeleteConfig()
    pcall(function()
        if isfile(ConfigPath) then delfile(ConfigPath) end
    end)
end

-- ============================================================
-- 6. نظام تغيير السيرفر
-- ============================================================
function SwitchToSmallestServer()
    local servers = {}
    local req = game:HttpGet(string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
    local success, data = pcall(function() return HttpService:JSONDecode(req) end)
    if success and data and data.data then
        local currentJobId = game.JobId
        for _, v in pairs(data.data) do
            if v.playing < v.maxPlayers and v.id ~= currentJobId then
                table.insert(servers, v.id)
            end
        end
    end
    if #servers > 0 then
        local targetJobId = servers[math.random(1, #servers)]
        pcall(SaveConfig)
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, game.Players.LocalPlayer)
    end
end

task.spawn(function()
    while true do
        task.wait(30)
        if ServerSwitchEnabled and IsFarmingActive then
            local elapsed = (tick() - LastServerSwitchTime) / 60
            if elapsed >= ServerSwitchInterval then
                LastServerSwitchTime = tick()
                task.spawn(SwitchToSmallestServer)
            end
        end
    end
end)

-- ============================================================
-- 7. نظام الانتظار للواجهة البدائية وبدء الفارم
-- ============================================================
function WaitForLoadingScreenAndStart()
    local loadingScreen = PlayerGui:WaitForChild("LoadingScreen", 30)
    if loadingScreen then
        task.wait(3)
        pcall(function() Net_upvr.get("loading_screen_camera_part", false) end)
        task.wait(1)
        pcall(function() Net_upvr.send("leave_character_creator") end)
        task.wait(2)
        Character = Client.Character or Client.CharacterAdded:Wait()
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        task.wait(2)
        local loaded = LoadConfig()
        if loaded and IsFarmingActive then
            UpdateActivity()
            task.spawn(StartAutoFarm)
        end
    end
end

task.spawn(function()
    task.wait(3)
    if not Client.Character or not Client.Character:FindFirstChild("HumanoidRootPart") then
        WaitForLoadingScreenAndStart()
    else
        task.wait(2)
        LoadConfig()
    end
end)

-- ============================================================
-- 8. إعدادات الـ Webhook
-- ============================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1529908007964774560/kqGFSEdJSuoYXaxCukQV3HP8-e41okzc0Fp4DPfFLsH4P57uq3JkzUy6717A5epk8ual"
local function SendWebhookMessage(message)
    pcall(function()
        local data = {["content"] = message}
        local body = HttpService:JSONEncode(data)
        local requestFunc = syn and syn.request or fluxus and fluxus.request or http_request or request
        if requestFunc then
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = body
            })
        else
            pcall(function() game:HttpGet(WEBHOOK_URL, true, body) end)
        end
    end)
end

task.spawn(function()
    task.wait(2)
    SendWebhookMessage("✅ النظام يعمل ويرسل ويب هوك بنجاح!")
end)

-- ============================================================
-- 9. نظام مراقبة الإنونتوري للأسماك
-- ============================================================
local LastFishCount = {}
local function GetFishNamesFromInventory()
    local fishList = {}
    local Items = PlayerGui:FindFirstChild("Items")
    local Holding = Items and Items:FindFirstChild("ItemsHolder") and Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame")
    if not Holding then return fishList end
    for _, v in pairs(Holding:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
            local itemType = v:GetAttribute("ItemType")
            if itemType and string.lower(tostring(itemType)) == "fish" then
                local nameLbl = v:FindFirstChild("ItemName")
                if nameLbl and nameLbl.Text then
                    table.insert(fishList, nameLbl.Text)
                end
            end
        end
    end
    return fishList
end

local function GetNewFish(oldList, newList)
    local newFish = {}
    local oldMap = {}
    for _, name in ipairs(oldList) do oldMap[name] = (oldMap[name] or 0) + 1 end
    for _, name in ipairs(newList) do
        if oldMap[name] then
            oldMap[name] = oldMap[name] - 1
            if oldMap[name] < 0 then table.insert(newFish, name) end
        else
            table.insert(newFish, name)
        end
    end
    return newFish
end

local function MonitorInventoryForFish()
    task.spawn(function()
        while true do
            task.wait(1)
            local currentFish = GetFishNamesFromInventory()
            local newFish = GetNewFish(LastFishCount, currentFish)
            for _, fishName in ipairs(newFish) do
                if fishName == "Tuna" or fishName == "Sailfish" or fishName == "Marlin" then
                    SendWebhookMessage("i got " .. fishName)
                end
            end
            LastFishCount = currentFish
        end
    end)
end
MonitorInventoryForFish()

-- ============================================================
-- 10. نظام مراقبة الرسائل المتطور (الحماية الذكية)
-- ============================================================
local isProtectionTriggered = false
local lastKnownPosition = nil
local lastKnownCFrame = nil

local function SavePlayerPosition()
    if Character and RootPart then
        lastKnownPosition = RootPart.Position
        lastKnownCFrame = RootPart.CFrame
    end
end

local function RestorePlayerPosition()
    if Character and RootPart and lastKnownCFrame then
        RootPart.CFrame = lastKnownCFrame
        RootPart.AssemblyLinearVelocity = Vector3.zero
        RootPart.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.1)
        return true
    end
    return false
end

local function PauseFarmingTemporarily()
    if isProtectionTriggered then return end
    isProtectionTriggered = true
    SavePlayerPosition()
    Config.StopWalking = true
    Config.Running = false
    if RootPart then
        RootPart.Anchored = false
        RootPart.AssemblyLinearVelocity = Vector3.zero
        RootPart.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(3)
    if IsFarmingActive then
        RestorePlayerPosition()
        Config.StopWalking = false
    end
    isProtectionTriggered = false
end

local function SetupNotificationMonitor()
    local SendRemote = RS:WaitForChild("Remotes"):WaitForChild("Send")
    SendRemote.OnClientEvent:Connect(function(eventName, ...)
        if eventName == "notification" then
            local args = {...}
            local message = args[2] or ""
            local keywords = {"Anti noclip triggered", "Teleport detected", "Speed hack detected", "Exploit detected", "Cheat detected"}
            for _, keyword in ipairs(keywords) do
                if message:find(keyword) then
                    if IsFarmingActive and not isProtectionTriggered then
                        task.spawn(PauseFarmingTemporarily)
                    end
                    break
                end
            end
        end
    end)
end
SetupNotificationMonitor()

-- ============================================================
-- 11. نظام حظر Remote الطرد
-- ============================================================
local SendRemote = RS:WaitForChild("Remotes"):WaitForChild("Send")
local oldFireServer
oldFireServer = hookfunction(SendRemote.FireServer, function(self, ...)
    local args = { ... }
    if args[2] == "crashed_car" then return nil end
    return oldFireServer(self, ...)
end)

-- ============================================================
-- 12. نظام المشي الذكي
-- ============================================================
local Sf = {}
function Sf:dist(pos)
    return (pos - RootPart.Position).Magnitude
end

function Sf:MoveSmoothly(startPos, endPos, speed)
    if isProtectionTriggered then return end
    Config.StopWalking = false
    Config.Running = true
    local char = Client.Character or Client.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    local dist = (endPos - startPos).Magnitude
    if dist < 0.5 then Config.Running = false; return end
    local dir = (endPos - startPos).Unit
    local movedDist = 0
    local startTime = tick()
    local spd = speed or WalkSpeedSlider.Value or 20
    while movedDist < dist and IsFarmingActive and not Config.StopWalking and not isProtectionTriggered do
        task.wait()
        if not IsFarmingActive or Config.StopWalking or isProtectionTriggered or hum.Health <= 0 then break end
        local elapsed = tick() - startTime
        movedDist = math.min(elapsed * spd, dist)
        local newPos = startPos + dir * movedDist
        if hum.Sit then hum.Sit = false end
        hrp:PivotTo(CFrame.new(newPos))
        pcall(function() Net_upvr.send("set_sprinting_1", true) end)
    end
    Config.Running = false
end

function Sf:GoUnderground()
    local zone = Zones["Level 70 +"]
    if not zone or IsUnderground then return end
    Sf:Teleport(zone.SurfacePos, true, WalkSpeedSlider.Value)
    task.wait(0.3)
    Sf:MoveSmoothly(zone.SurfacePos, zone.UndergroundPos, WalkSpeedSlider.Value)
    task.wait(0.3)
    IsUnderground = true
    UpdateActivity()
end

function Sf:GoToSurface()
    local zone = Zones["Level 70 +"]
    if not zone or not IsUnderground then return end
    Sf:MoveSmoothly(RootPart.Position, zone.SurfacePos, WalkSpeedSlider.Value)
    task.wait(0.3)
    IsUnderground = false
    UpdateActivity()
end

function Sf:Teleport(destination, value, speed)
    if isProtectionTriggered then return end
    Config.StopWalking = false
    Config.Running = true
    local char = Client.Character or Client.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    local path = PathfindingService:CreatePath({
        AgentCanJump = true, AgentJumpHeight = 2.5, AgentHeight = 8, AgentRadius = 2.5, AgentMaxSlope = 90, Costs = {BlockedNode = 50, DoorArea = 1}
    })
    local success = pcall(function() path:ComputeAsync(hrp.Position, destination) end)
    if not success or path.Status ~= Enum.PathStatus.Success then Config.Running = false; return end
    local waypoints = path:GetWaypoints()
    speed = speed or WalkSpeedSlider.Value or 20
    for _, wp in pairs(waypoints) do
        if isProtectionTriggered or not IsFarmingActive or Config.StopWalking then Config.Running = false; return end
        local offsetY = (wp.Action == Enum.PathWaypointAction.Jump) and 10 or 4
        local targetPos = wp.Position + Vector3.new(0, offsetY, 0)
        local startPos = hrp.Position
        local dir = (targetPos - startPos).Unit
        local dist = (targetPos - startPos).Magnitude
        local movedDist = 0
        local startTime = tick()
        while movedDist < dist and IsFarmingActive and not Config.StopWalking and not isProtectionTriggered do
            task.wait()
            if not value or hum.Health <= 0 then break end
            local elapsed = tick() - startTime
            movedDist = math.min(elapsed * speed, dist)
            local newPos = startPos + dir * movedDist
            if hum.Sit then hum.Sit = false end
            hrp:PivotTo(CFrame.new(newPos))
            pcall(function() Net_upvr.send("set_sprinting_1", true) end)
        end
        if not value or hum.Health <= 0 then break end
    end
    Config.Running = false
    UpdateActivity()
end

-- ============================================================
-- 13. وظائف الإنونتوري والصراف والشراء والبيع
-- ============================================================
function Sf:GetMoney()
    local moneyData = Data_upvr.money
    return (moneyData and moneyData.hand) and moneyData.hand or 0
end

function Sf:GetBankMoney()
    local moneyData = Data_upvr.money
    return (moneyData and moneyData.bank) and moneyData.bank or 0
end

function Sf:GetSkill(skillname)
    local OptionsSkill = PlayerGui:FindFirstChild('Skills')
    if not OptionsSkill then return 0 end
    local Holder = OptionsSkill:FindFirstChild('SkillsHolder').SkillsScrollingFrame
    for _, v in pairs(Holder:GetChildren()) do
        if v.Name == "SkillOptionTemplate" and string.find(v:FindFirstChild('SkillTitle').Text, skillname) then
            return tonumber(v:FindFirstChild('SkillTitle').Text:match("%d+")) or 0
        end
    end
    return 0
end

function Sf:HasAnyRod()
    local Items = PlayerGui:FindFirstChild("Items")
    local Holding = Items and Items:FindFirstChild("ItemsHolder") and Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame")
    if not Holding then return false, nil, nil, false end
    for _, v in pairs(Holding:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
            local nameLbl = v:FindFirstChild("ItemName")
            if nameLbl and nameLbl.Text and string.find(string.lower(nameLbl.Text), "rod") then
                return true, nameLbl.Text, v.Name, v:FindFirstChild("ItemEquipped") and v.ItemEquipped.Visible or false
            end
        end
    end
    return false, nil, nil, false
end

function Sf:HasAnyBait()
    local Items = PlayerGui:FindFirstChild("Items")
    local Holding = Items and Items:FindFirstChild("ItemsHolder") and Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame")
    if not Holding then return false, nil, nil end
    for _, v in pairs(Holding:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
            local nameLbl = v:FindFirstChild("ItemName")
            if nameLbl and nameLbl.Text and (string.find(string.lower(nameLbl.Text), "wormtec") or string.find(string.lower(nameLbl.Text), "prawntec")) then
                return true, nameLbl.Text, v.Name
            end
        end
    end
    return false, nil, nil
end

function Sf:GetFishCount()
    local count = 0
    local Items = PlayerGui:FindFirstChild("Items")
    local Holding = Items and Items:FindFirstChild("ItemsHolder") and Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame")
    if not Holding then return 0 end
    for _, v in pairs(Holding:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
            local itemType = v:GetAttribute("ItemType")
            if itemType and string.lower(tostring(itemType)) == "fish" then count = count + 1 end
        end
    end
    return count
end

function Sf:GetInventoryCount()
    local count = 0
    local Items = PlayerGui:FindFirstChild("Items")
    local Holding = Items and Items:FindFirstChild("ItemsHolder") and Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame")
    if not Holding then return 0 end
    for _, v in pairs(Holding:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then count = count + 1 end
    end
    return count
end

function Sf:SellAllFish()
    task.wait(0.5)
    pcall(function() Net_upvr.get("sell_all_fish") end)
    task.wait(0.5)
end

function Sf:SellFishWithPath()
    local Point1 = Vector3.new(-274.923, 252.856, 431.378)
    local Point2 = Vector3.new(-305.648, 251.648, 434.429)
    Sf:Teleport(Point2, true, 25)
    Sf:Teleport(Point1, true, 25)
    Sf:Teleport(SellBeaconPos, true, 25)
    Sf:SellAllFish()
    Sf:Teleport(Point1, true, 25)
    Sf:Teleport(Point2, true, 25)
    UpdateActivity()
    return true
end

function Sf:FindClosestAvailableATM()
    local atmFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Props") and workspace.Map.Props:FindFirstChild("ATMs")
    if not atmFolder then return nil end
    local closest, shortest = nil, math.huge
    for _, atm in pairs(atmFolder:GetChildren()) do
        if atm.Name == "ATM" and atm:IsA("Model") then
            local keys = {}
            for k in pairs(atm:GetAttributes()) do table.insert(keys, k) end
            table.sort(keys)
            if keys[3] and atm:GetAttribute(keys[3]) == false then
                local d = Sf:dist(atm.Area.Position)
                if d < shortest then closest = atm; shortest = d end
            end
        end
    end
    return closest
end

function DepositAllMoney()
    local handMoney = Sf:GetMoney()
    if handMoney <= 0 then return true end
    local atm = Sf:FindClosestAvailableATM()
    if not atm then return false end
    Sf:Teleport(atm.Area.Position, true, 20)
    task.wait(0.5)
    pcall(function() Net_upvr.get("transfer_funds", "hand", "bank", handMoney) end)
    task.wait(0.5)
    return true
end

function WithdrawSpecificAmount(amount)
    if amount <= 0 then return true end
    local currentHand = Sf:GetMoney()
    if currentHand >= amount then return true end
    local needed = amount - currentHand
    if Sf:GetBankMoney() < needed then return false end
    local atm = Sf:FindClosestAvailableATM()
    if not atm then return false end
    Sf:Teleport(atm.Area.Position, true, 20)
    task.wait(0.5)
    pcall(function() Net_upvr.get("transfer_funds", "bank", "hand", needed) end)
    task.wait(0.5)
    return true
end

function BuyEquipment()
    local hasRod, currentRodName, currentRodUid, _ = Sf:HasAnyRod()
    local hasBait, currentBaitName, currentBaitUid = Sf:HasAnyBait()
    local Items = PlayerGui:FindFirstChild("Items")
    local Holding = Items and Items:FindFirstChild("ItemsHolder") and Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame")
    
    if Holding then
        for _, v in pairs(Holding:GetChildren()) do
            if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
                local nameLbl = v:FindFirstChild("ItemName")
                if nameLbl and nameLbl.Text then
                    local itemUid = v.Name
                    if not ((hasRod and itemUid == currentRodUid) or (hasBait and itemUid == currentBaitUid)) then
                        pcall(function() Net_upvr.get("drop_item", itemUid, 1) end)
                    end
                end
            end
        end
    end

    local selectedRod = RodDropdown.Value
    local selectedBait = BaitDropdown.Value
    local targetBait = BaitAmount.Value
    local fishingLevel = Sf:GetSkill("Fishing")
    local targetRod = selectedRod
    if targetRod == "Smart Select" then
        for _, rod in ipairs(FishingRods) do if fishingLevel >= rod.Level then targetRod = rod.Name; break end end
    end
    local targetBaitName = selectedBait
    if targetBaitName == "Smart Select" then
        for _, bait in ipairs(FishingBaits) do if fishingLevel >= bait.Level then targetBaitName = bait.Name; break end end
    end

    local hasRodAfterDrop, _, _, _ = Sf:HasAnyRod()
    local hasBaitAfterDrop, _, _ = Sf:HasAnyBait()
    local totalCost = 0
    if not hasRodAfterDrop then
        for _, rod in ipairs(FishingRods) do if rod.Name == targetRod then totalCost = totalCost + rod.Price; break end end
    end
    if not hasBaitAfterDrop then
        for _, bait in ipairs(FishingBaits) do if bait.Name == targetBaitName then totalCost = totalCost + (bait.Price * targetBait); break end end
    end

    if totalCost <= 0 then return true end
    if not WithdrawSpecificAmount(totalCost) then return false end
    Sf:Teleport(ShopLocation, true, 30)
    task.wait(0.3)
    local shopFolder = workspace:FindFirstChild("ShopZone_Hardware")
    if not shopFolder then return false end
    if not hasRodAfterDrop then
        pcall(function() Net_upvr.get("purchase_consumable", shopFolder, targetRod) end)
        task.wait(0.2)
    end
    if not hasBaitAfterDrop then
        for i = 1, targetBait do
            if not IsFarmingActive then break end
            pcall(function() Net_upvr.get("purchase_consumable", shopFolder, targetBaitName) end)
        end
        task.wait(0.5)
    end
    UpdateActivity()
    return true
end

function Sf:IsRodEquipped(rodName)
    local Items = PlayerGui:FindFirstChild("Items")
    local Holding = Items and Items:FindFirstChild("ItemsHolder") and Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame")
    if not Holding then return false end
    for _, v in pairs(Holding:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
            local nameLbl = v:FindFirstChild("ItemName")
            if nameLbl and nameLbl.Text == rodName then
                local equipped = v:FindFirstChild("ItemEquipped")
                if equipped and equipped.Visible then return true end
            end
        end
    end
    return false
end

-- ✅ تم إصلاحEquipRod ليعمل على الجوال بدون VirtualUser
function EquipRod()
    local hasRod, rodName, rodUid, _ = Sf:HasAnyRod()
    if not hasRod or not rodName then return false end
    if Sf:IsRodEquipped(rodName) then return true end
    
    pcall(function() Net_upvr.get("toggle_equip_item", tostring(rodUid)) end)
    task.wait(0.2)
    
    local char = Client.Character
    local backpack = Client:FindFirstChild("Backpack")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if char and backpack and humanoid then
        local tool = backpack:FindFirstChild(rodName) or char:FindFirstChild(rodName)
        if tool then 
            humanoid:EquipTool(tool) 
        end
    end
    UpdateActivity()
    return true
end

function EnsureRodEquipped()
    local hasRod, rodName, _, _ = Sf:HasAnyRod()
    if not hasRod or not rodName or not Sf:IsRodEquipped(rodName) then
        return EquipRod()
    end
    return true
end

function EquipBaitOnRod()
    local hasRod, _, rodUid = Sf:HasAnyRod()
    local hasBait, _, baitUid = Sf:HasAnyBait()
    if hasRod and rodUid and hasBait and baitUid then
        pcall(function() Net_upvr.get("equip_ammo_on_item", rodUid, baitUid) end)
        task.wait(0.2)
        return true
    end
    return false
end

local SliderMinigame = nil
for _, module in ipairs(RS:GetDescendants()) do
    if module:IsA("ModuleScript") and module.Name == "SliderMinigame" then
        local success, result = pcall(require, module)
        if success then SliderMinigame = result end
    end
end

local function isSliderOpen()
    if SliderMinigame and SliderMinigame.enabled and SliderMinigame.enabled.get then
        return SliderMinigame.enabled.get() == true
    end
    local sliderGui = PlayerGui:FindFirstChild("SliderMinigame")
    if sliderGui then
        local frame = sliderGui:FindFirstChildOfClass("Frame")
        if frame and frame.Visible then return true end
    end
    return false
end

-- ✅ تم إصلاح QuickWin ليعمل على الجوال عبر إرسال الـ Remote مباشرة
local function QuickWin(rodTool)
    if SliderMinigame and SliderMinigame.win then
        if type(SliderMinigame.win) == "table" and SliderMinigame.win.Fire then
            pcall(function() SliderMinigame.win:Fire(true) end)
        end
    end
    if rodTool then
        pcall(function() Net_upvr.send("reel_ended", rodTool, true) end)
    end
    return true
end

-- ============================================================
-- 14. نظام إعادة الإحياء التلقائي
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if not Config.Respawn then continue end
        local deathscreen = PlayerGui:FindFirstChild("DeathScreen")
        if deathscreen then
            local holder = deathscreen:FindFirstChild("DeathScreenHolder")
            if holder and holder.Visible then
                local btn = holder:FindFirstChild("Frame") and holder.Frame:FindFirstChild("RespawnButtonFrame") and holder.Frame.RespawnButtonFrame:FindFirstChild("RespawnButton") and holder.Frame.RespawnButtonFrame.RespawnButton:FindFirstChild("TextLabel")
                if btn and btn.Text == "Respawn" then
                    pcall(function() Net_upvr.send("death_screen_request_respawn") end)
                end
            end
        end
    end
end)

-- ============================================================
-- 15. نظام الحماية من الخمول والتعليق
-- ============================================================
task.spawn(function()
    while true do
        task.wait(5)
        if not IsFarmingActive then
            UpdateActivity()
            continue
        end
        local currentTime = tick()
        local timeSinceActivity = currentTime - LastActivityTime
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local currentPos = char.HumanoidRootPart.Position
            local distanceMoved = (currentPos - LastCheckedPosition).Magnitude
            if distanceMoved > 3 then
                UpdateActivity()
            elseif timeSinceActivity >= IdleThreshold then
                pcall(function() Net_upvr.send("request_respawn") end)
                task.wait(2)
                UpdateActivity()
            end
        end
    end
end)

-- ============================================================
-- 16. الدورة الرئيسية للصيد
-- ============================================================
function StartAutoFarm()
    IsFarmingActive = true
    task.spawn(function()
        while IsFarmingActive do
            pcall(function()
                local char = Client.Character or Client.CharacterAdded:Wait()
                local backpack = Client:FindFirstChild("Backpack")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local toolNames = {"FishingRodUltimate", "FishingRodAdvanced", "FishingRodPro", "FishingRodRegular"}
                if backpack and humanoid then
                    local mainTool = nil
                    for _, name in ipairs(toolNames) do
                        mainTool = char:FindFirstChild(name) or backpack:FindFirstChild(name)
                        if mainTool then break end
                    end
                    if mainTool and mainTool.Parent == backpack then
                        humanoid:EquipTool(mainTool)
                    end
                end
            end)
            task.wait(2)
        end
    end)

    if AutoBuyToggle.Value then
        BuyEquipment()
        if not IsFarmingActive then return end
    end
    EquipRod()
    if not IsFarmingActive then return end

    while IsFarmingActive do
        if not Client.Character or not Client.Character.Parent then
            task.wait(1)
            continue
        end
        Character = Client.Character
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        RootPart = Character:FindFirstChild("HumanoidRootPart")

        if isProtectionTriggered then
            while isProtectionTriggered and IsFarmingActive do task.wait(0.5) end
            if not IsFarmingActive then break end
            continue
        end

        EnsureRodEquipped()
        local zone = ZoneDropdown.Value
        local data = Zones[zone]
        if not data then task.wait(1); continue end

        local inventoryCount = Sf:GetInventoryCount()
        local hasBait = Sf:HasAnyBait()

        if inventoryCount >= 17 or not hasBait then
            RootPart.Anchored = false
            if zone == "Level 70 +" and IsUnderground then
                Sf:GoToSurface()
            end
            local fishCount = Sf:GetFishCount()
            if fishCount > 0 then
                Sf:SellFishWithPath()
                task.wait(0.5)
            end
            DepositAllMoney()
            if not IsFarmingActive then break end
            hasBait = Sf:HasAnyBait()
            if not hasBait then
                BuyEquipment()
                if not IsFarmingActive then break end
                EquipRod()
            end
        end

        if IsFarmingActive and inventoryCount < 17 and Sf:HasAnyBait() then
            if zone == "Level 70 +" and not IsUnderground then
                Sf:GoUnderground()
            elseif zone == "Level 40 +" then
                Sf:Teleport(data.Pos, true, WalkSpeedSlider.Value)
            end
            task.wait(0.5)
            if not Sf:HasAnyBait() then continue end
            EnsureRodEquipped()
            RootPart.Anchored = true
            task.wait(0.2)
            EquipBaitOnRod()
            task.wait(0.3)

            local castPos
            if zone == "Level 70 +" then
                castPos = Zones["Level 70 +"].CastPos
            else
                local offset = Vector3.new(math.random(-50, -10), 0, math.random(-20, 20))
                castPos = RootPart.Position + offset
            end
            RootPart.CFrame = CFrame.lookAt(RootPart.Position, castPos)
            task.wait(0.2)

            local hasRod, rodName = Sf:HasAnyRod()
            local rodTool = nil
            if hasRod and rodName then
                rodTool = Character:FindFirstChild(rodName) or Backpack:FindFirstChild(rodName)
            end

            -- ✅ إرسال الرمية مباشرة عبر الـ Remote (يدعم الجوال)
            if rodTool then
                pcall(function() Net_upvr.get("throw_rod", rodTool, castPos) end)
            end
            UpdateActivity()

            local timeout = tick() + 25
            local progressBarVisible = false
            while IsFarmingActive and tick() < timeout do
                if isProtectionTriggered then
                    if rodTool then pcall(function() Net_upvr.send("reel_ended", rodTool, false) end) end
                    break
                end
                task.wait(0.1)
                if isSliderOpen() then
                    progressBarVisible = true
                    UpdateActivity()
                    break
                end
            end

            if isProtectionTriggered then continue end

            if progressBarVisible then
                task.wait(0.3)
                QuickWin(rodTool) -- ✅ الفوز وإرسال الـ Remote مباشرة
                UpdateActivity()
            else
                if rodTool then
                    pcall(function() Net_upvr.send("reel_ended", rodTool, false) end)
                end
            end
        end
        task.wait(1)
    end
    RootPart.Anchored = false
end

print("Real Is Here - Mobile & Bypass Enabled")
