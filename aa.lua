-- ============================================================
-- 1. تحميل المكتبة وإنشاء النافذة (WindUI - تدعم الجوال بالكامل)
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Real",
    Icon = "rbxassetid://118194721156015",
    Author = "By",
    Folder = "FishingConfig",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Name = game.Players.LocalPlayer.Name,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. game.Players.LocalPlayer.UserId .. "&w=150&h=150",
        Callback = function() end,
    },
})

Window:EditOpenButton({ Enabled = false })

-- زر عائم للجوال والكمبيوتر لفتح/إغلاق القائمة
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WindUI_Toggle"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.fromOffset(45, 45)
ToggleBtn.Position = UDim2.new(0.5, -20, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
ToggleBtn.BackgroundTransparency = 0
ToggleBtn.Image = "rbxassetid://118194721156015"
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.AutoButtonColor = false

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    ToggleBtn:TweenSize(UDim2.fromOffset(50, 50), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true, function()
        ToggleBtn:TweenSize(UDim2.fromOffset(45, 45), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
    end)
    Window:Toggle()
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.LeftControl then
        Window:Toggle()
    end
end)

-- ============================================================
-- 2. إخفاء الإكزيكيوتر فقط (بدون أي تعديل على شبكة الإرسال لتفادي الحظر)
-- ============================================================
if getgenv then getgenv().identifyexecutor = nil end
if getfenv then local env = getfenv(); env.identifyexecutor = nil end

-- ============================================================
-- 3. إعدادات القائمة والتحكم
-- ============================================================
local FishTab = Window:Tab({ Title = 'FishFarm', Icon = 'fish' })
local DevTab = Window:Tab({ Title = 'Dev', Icon = 'code' })
local AntiKickTab = Window:Tab({ Title = 'Anti-Kick', Icon = 'shield' })
local ServerTab = Window:Tab({ Title = 'Server', Icon = 'server' })

local Config = { 
    StopWalking = false, 
    Running = false, 
    Respawn = false, 
    AutoBuyEnabled = true,
    RodSelect = "Smart Select",
    BaitSelect = "Smart Select",
    BaitAmount = 10,
    WalkSpeed = 20,
    ZoneSelect = "Level 70 +",
    AutoFarmActive = false
}

local AntiKickEnabled = false
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
-- 3.1 عناصر القائمة
-- ============================================================
FishTab:Section({ Title = "إعدادات المعدات" })

FishTab:Toggle({
    Title = "تفعيل شراء المعدات تلقائياً",
    Desc = "يشتري الناقص فقط عند انتهاء الطعم",
    Icon = "check",
    Type = "Checkbox",
    Value = true,
    Callback = function(Value)
        Config.AutoBuyEnabled = Value
    end
})

FishTab:Dropdown({
    Title = "نوع السنارة",
    Values = {"Smart Select", "FishingRodUltimate", "FishingRodAdvanced", "FishingRodPro", "FishingRodRegular"},
    Value = "Smart Select",
    Callback = function(Value)
        Config.RodSelect = Value
    end
})

FishTab:Dropdown({
    Title = "نوع الطعم",
    Values = {"Smart Select", "PrawntecUltimate", "PrawntecPro", "WormtecUltimate", "WormtecPro", "WormtecRegular"},
    Value = "Smart Select",
    Callback = function(Value)
        Config.BaitSelect = Value
    end
})

FishTab:Slider({
    Title = "الحد الأقصى للطعم",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 10 },
    Callback = function(Value)
        Config.BaitAmount = Value
    end
})

FishTab:Section({ Title = "الحركة والسرعة" })

FishTab:Slider({
    Title = "سرعة المشي",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 20 },
    Callback = function(Value)
        Config.WalkSpeed = Value
    end
})

FishTab:Section({ Title = "منطقة الصيد" })

FishTab:Dropdown({
    Title = "المستوى",
    Values = {"Level 40 +", "Level 70 +"},
    Value = "Level 70 +",
    Callback = function(Value)
        Config.ZoneSelect = Value
    end
})

FishTab:Section({ Title = "التحكم" })

FishTab:Toggle({
    Title = "تشغيل Auto Farm (لا نهائي)",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        Config.AutoFarmActive = Value
        if Value then
            Config.StopWalking = false
            UpdateActivity()
            task.spawn(StartAutoFarm)
        else
            Config.StopWalking = true
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
            print("⛔ تم إيقاف النظام!")
        end
    end
})

FishTab:Toggle({
    Title = "إعادة إحياء تلقائي (Auto Respawn)",
    Desc = "يعيد إحياءك تلقائياً عند الموت ويكمل الفارم",
    Icon = "check",
    Type = "Checkbox",
    Value = true,
    Callback = function(Value)
        Config.Respawn = Value
    end
})

AntiKickTab:Section({ Title = "مانع الطرد" })
AntiKickTab:Toggle({
    Title = "تفعيل مانع الطرد",
    Desc = "يمنع الطرد التلقائي كل 15 دقيقة",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        AntiKickEnabled = Value
        if Value then
            print("🛡️ تم تفعيل مانع الطرد!")
            task.spawn(AntiKickLoop)
        else
            print("🛡️ تم إيقاف مانع الطرد!")
        end
    end
})

ServerTab:Section({ Title = "تغيير السيرفر التلقائي" })
ServerTab:Toggle({
    Title = "تفعيل تغيير السيرفر التلقائي",
    Desc = "يغير السيرفر تلقائياً للسيرفر الأقل لاعبين",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        ServerSwitchEnabled = Value
        if Value then
            LastServerSwitchTime = tick()
            print("🔄 تم تفعيل تغيير السيرفر التلقائي كل " .. ServerSwitchInterval .. " دقيقة!")
        end
    end
})

ServerTab:Slider({
    Title = "الفترة بين التغيير (دقائق)",
    Step = 1,
    Value = { Min = 5, Max = 120, Default = 30 },
    Callback = function(Value)
        ServerSwitchInterval = Value
    end
})

ServerTab:Button({
    Title = "Hop Server (Low Player) - الآن",
    Icon = "shuffle",
    Callback = function()
        task.spawn(SwitchToSmallestServer)
    end
})

ServerTab:Button({
    Title = "Rejoin نفس السيرفر",
    Icon = "refresh-ccw",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end
})

ServerTab:Section({ Title = "إدارة الإعدادات" })
ServerTab:Button({
    Title = "💾 حفظ الإعدادات",
    Icon = "save",
    Callback = function()
        SaveConfig()
    end
})
ServerTab:Button({
    Title = "📂 تحميل الإعدادات",
    Icon = "folder",
    Callback = function()
        LoadConfig()
    end
})
ServerTab:Button({
    Title = "🗑️ حذف الإعدادات",
    Icon = "trash",
    Callback = function()
        DeleteConfig()
    end
})

DevTab:Button({
    Title = "Discord",
    Icon = "link",
    Callback = function()
        setclipboard("https://discord.gg/s45h7hQugc")
    end
})

-- ============================================================
-- 4. حلقة مانع الطرد
-- ============================================================
local function AntiKickLoop()
    while AntiKickEnabled do
        task.wait(900)
        if AntiKickEnabled then
            local char = game.Players.LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Jump = true
                    print("🦘 تم القفز لمنع الطرد!")
                end
            end
            task.wait(0.5)
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local originalPos = hrp.Position
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, 1)
                task.wait(0.3)
                hrp.CFrame = CFrame.new(originalPos)
            end
        end
    end
end

-- ============================================================
-- 5. الخدمات والموديولات الرسمية (استخدام Net الأصلي بدون Bypass)
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
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
local VU = game:GetService("VirtualUser")
local Backpack = Client:WaitForChild("Backpack")

Client.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid = c:WaitForChild("Humanoid")
    RootPart = c:WaitForChild("HumanoidRootPart")
    Backpack = Client:WaitForChild("Backpack")
    UpdateActivity()
    print("🔄 تم اكتشاف إعادة ظهور الشخصية (Respawn)!")
end)

-- استخدام شبكة Net الأصلية للعبة كما هي (لتفادي الحظر)
local Net = require(RS.Modules.Core.Net)
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
        Pos = Vector3.new(71.277, 246.543, 821.295),
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
-- 6. نظام حفظ وتحميل Config
-- ============================================================
local ConfigPath = "UPVR_Fishing_Config.json"

function SaveConfig()
    local configData = {
        AutoBuyEnabled = Config.AutoBuyEnabled,
        RodSelect = Config.RodSelect,
        BaitSelect = Config.BaitSelect,
        BaitAmount = Config.BaitAmount,
        WalkSpeed = Config.WalkSpeed,
        ZoneSelect = Config.ZoneSelect,
        Respawn = Config.Respawn,
        AntiKick = AntiKickEnabled,
        ServerSwitch = ServerSwitchEnabled,
        ServerSwitchInterval = ServerSwitchInterval,
        AutoFarmActive = Config.AutoFarmActive
    }
    
    local success, err = pcall(function()
        writefile(ConfigPath, HttpService:JSONEncode(configData))
    end)
    
    if success then
        print("💾 تم حفظ الإعدادات بنجاح!")
    else
        warn("❌ فشل حفظ الإعدادات: " .. tostring(err))
    end
end

function LoadConfig()
    local success, err = pcall(function()
        if not isfile(ConfigPath) then return false end
        local data = HttpService:JSONDecode(readfile(ConfigPath))
        
        if data.AutoBuyEnabled ~= nil then Config.AutoBuyEnabled = data.AutoBuyEnabled end
        if data.RodSelect then Config.RodSelect = data.RodSelect end
        if data.BaitSelect then Config.BaitSelect = data.BaitSelect end
        if data.BaitAmount then Config.BaitAmount = data.BaitAmount end
        if data.WalkSpeed then Config.WalkSpeed = data.WalkSpeed end
        if data.ZoneSelect then Config.ZoneSelect = data.ZoneSelect end
        if data.Respawn ~= nil then Config.Respawn = data.Respawn end
        if data.AntiKick ~= nil then AntiKickEnabled = data.AntiKick end
        if data.ServerSwitch ~= nil then ServerSwitchEnabled = data.ServerSwitch end
        if data.ServerSwitchInterval then ServerSwitchInterval = data.ServerSwitchInterval end
        
        print("📂 تم تحميل الإعدادات بنجاح!")
        
        if data.AutoFarmActive then
            Config.AutoFarmActive = true
            UpdateActivity()
            task.spawn(StartAutoFarm)
            print("🚀 تم تشغيل Auto Farm تلقائياً!")
        end
        
        if AntiKickEnabled then
            task.spawn(AntiKickLoop)
        end
        return true
    end)
    
    if not success then
        warn("❌ فشل تحميل الإعدادات: " .. tostring(err))
    end
    return false
end

function DeleteConfig()
    local success, err = pcall(function()
        if isfile(ConfigPath) then
            delfile(ConfigPath)
            print("🗑️ تم حذف الإعدادات بنجاح!")
        end
    end)
end

-- ============================================================
-- 7. نظام تغيير السيرفر
-- ============================================================
function SwitchToSmallestServer()
    print("🔄 جاري البحث عن سيرفر بأقل عدد لاعبين...")
    
    local servers = {}
    local req = game:HttpGet(
        string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    )
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(req)
    end)
    
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
        print("🎯 تم اختيار سيرفر جديد! جاري الانتقال...")
        pcall(SaveConfig)
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, game.Players.LocalPlayer)
    else
        warn("❌ لم يتم العثور على سيرفر متاح!")
    end
end

task.spawn(function()
    while true do
        task.wait(30)
        if ServerSwitchEnabled and Config.AutoFarmActive then
            local elapsed = (tick() - LastServerSwitchTime) / 60
            if elapsed >= ServerSwitchInterval then
                print("⏰ حان وقت تغيير السيرفر!")
                LastServerSwitchTime = tick()
                task.spawn(SwitchToSmallestServer)
            end
        end
    end
end)

-- ============================================================
-- 8. إعدادات الـ Webhook
-- ============================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1529908007964774560/kqGFSEdJSuoYXaxCukQV3HP8-e41okzc0Fp4DPfFLsH4P57uq3JkzUy6717A5epk8ual"

local function SendWebhookMessage(message)
    local success, err = pcall(function()
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

task.spawn(function()
    while true do
        task.wait(1)
        local currentFish = GetFishNamesFromInventory()
        local oldMap = {}
        for _, name in ipairs(LastFishCount) do oldMap[name] = (oldMap[name] or 0) + 1 end
        for _, name in ipairs(currentFish) do
            if oldMap[name] then
                oldMap[name] = oldMap[name] - 1
                if oldMap[name] < 0 then
                    if name == "Tuna" or name == "Sailfish" or name == "Marlin" then
                        SendWebhookMessage("i got " .. name)
                    end
                end
            else
                if name == "Tuna" or name == "Sailfish" or name == "Marlin" then
                    SendWebhookMessage("i got " .. name)
                end
            end
        end
        LastFishCount = currentFish
    end
end)

-- ============================================================
-- 10. نظام الحماية الذكية
-- ============================================================
local isProtectionTriggered = false
local lastKnownCFrame = nil

local function SavePlayerPosition()
    if Character and RootPart then
        lastKnownCFrame = RootPart.CFrame
    end
end

local function RestorePlayerPosition()
    if Character and RootPart and lastKnownCFrame then
        RootPart.CFrame = lastKnownCFrame
        RootPart.AssemblyLinearVelocity = Vector3.zero
        RootPart.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.1)
    end
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
    print("⚠️ [الحماية] تم اكتشاف رسالة تحذيرية - إيقاف مؤقت!")
    task.wait(3)
    if Config.AutoFarmActive then
        RestorePlayerPosition()
        Config.StopWalking = false
        print("✅ [الحماية] استئناف العمل من نفس النقطة!")
    end
    isProtectionTriggered = false
end

task.spawn(function()
    local SendRemote = RS:WaitForChild("Remotes"):WaitForChild("Send")
    SendRemote.OnClientEvent:Connect(function(eventName, ...)
        if eventName == "notification" then
            local args = {...}
            local message = args[2] or ""
            local keywords = {"Anti noclip triggered", "Teleport detected", "Speed hack detected", "Exploit detected", "Cheat detected"}
            for _, keyword in ipairs(keywords) do
                if message:find(keyword) then
                    if Config.AutoFarmActive and not isProtectionTriggered then
                        task.spawn(PauseFarmingTemporarily)
                    end
                    break
                end
            end
        end
    end)
end)

-- ============================================================
-- 11. نظام المشي الذكي والحركة
-- ============================================================
local Sf = {}

function Sf:dist(pos)
    return (pos - RootPart.Position).Magnitude
end

function Sf:MoveSmoothly(startPos, endPos, speed)
    if isProtectionTriggered then return end
    Config.StopWalking = false
    Config.Running = true
    local dist = (endPos - startPos).Magnitude
    if dist < 0.5 then Config.Running = false; return end
    local dir = (endPos - startPos).Unit
    local movedDist = 0
    local startTime = tick()
    local spd = speed or Config.WalkSpeed or 20

    while movedDist < dist and Config.AutoFarmActive and not Config.StopWalking and not isProtectionTriggered do
        task.wait()
        if not Config.AutoFarmActive or Config.StopWalking or isProtectionTriggered or Humanoid.Health <= 0 then break end
        local elapsed = tick() - startTime
        movedDist = math.min(elapsed * spd, dist)
        local newPos = startPos + dir * movedDist
        if Humanoid.Sit then Humanoid.Sit = false end
        RootPart:PivotTo(CFrame.new(newPos))
        pcall(function() Net.send("set_sprinting_1", true) end)
    end
    Config.Running = false
end

function Sf:Teleport(destination, value, speed)
    if isProtectionTriggered then return end
    Config.StopWalking = false
    Config.Running = true

    local path = PathfindingService:CreatePath({
        AgentCanJump = true, AgentJumpHeight = 2.5, AgentHeight = 8, AgentRadius = 2.5, AgentMaxSlope = 90, Costs = {BlockedNode = 50, DoorArea = 1}
    })

    local success = pcall(function() path:ComputeAsync(RootPart.Position, destination) end)
    if not success or path.Status ~= Enum.PathStatus.Success then Config.Running = false; return end

    local waypoints = path:GetWaypoints()
    speed = speed or Config.WalkSpeed or 20

    for _, wp in pairs(waypoints) do
        if isProtectionTriggered or not Config.AutoFarmActive or Config.StopWalking then Config.Running = false; return end
        local offsetY = (wp.Action == Enum.PathWaypointAction.Jump) and 10 or 4
        local targetPos = wp.Position + Vector3.new(0, offsetY, 0)
        local startPos = RootPart.Position
        local dir = (targetPos - startPos).Unit
        local dist = (targetPos - startPos).Magnitude
        local movedDist = 0
        local startTime = tick()

        while movedDist < dist and Config.AutoFarmActive and not Config.StopWalking and not isProtectionTriggered do
            task.wait()
            if not value or Humanoid.Health <= 0 then break end
            local elapsed = tick() - startTime
            movedDist = math.min(elapsed * speed, dist)
            local newPos = startPos + dir * movedDist
            if Humanoid.Sit then Humanoid.Sit = false end
            RootPart:PivotTo(CFrame.new(newPos))
            pcall(function() Net.send("set_sprinting_1", true) end)
        end
        if not value or Humanoid.Health <= 0 then break end
    end
    Config.Running = false
    UpdateActivity()
end

do
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "DoorSystem" or v.Name == "BasementDoor" then
            for _, x in ipairs(v:GetDescendants()) do
                if x:IsA('BasePart') then
                    x.CanCollide = false
                    if not x:FindFirstChildOfClass("PathfindingModifier") then
                        local mod = Instance.new("PathfindingModifier")
                        mod.Label = "DoorArea"
                        mod.PassThrough = true
                        mod.Parent = x
                    end
                end
            end
        end
    end
end

-- ============================================================
-- 12. وظائف الإنونتوري والصراف والشراء والبيع
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
    pcall(function() Net.get("sell_all_fish") end)
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
    pcall(function() Net.get("transfer_funds", "hand", "bank", handMoney) end)
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
    pcall(function() Net.get("transfer_funds", "bank", "hand", needed) end)
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
                        pcall(function() Net.get("drop_item", itemUid, 1) end)
                    end
                end
            end
        end
    end
    
    local selectedRod = Config.RodSelect
    local selectedBait = Config.BaitSelect
    local targetBait = Config.BaitAmount
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
        pcall(function() Net.get("purchase_consumable", shopFolder, targetRod) end)
        task.wait(0.2)
    end
    
    if not hasBaitAfterDrop then
        for i = 1, targetBait do
            if not Config.AutoFarmActive then break end
            pcall(function() Net.get("purchase_consumable", shopFolder, targetBaitName) end)
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

function EquipRod()
    local hasRod, rodName, rodUid, _ = Sf:HasAnyRod()
    if not hasRod or not rodName then return false end
    if Sf:IsRodEquipped(rodName) then return true end
    pcall(function() Net.get("toggle_equip_item", tostring(rodUid)) end)
    task.wait(0.3)
    local char = Client.Character
    local backpack = Client:FindFirstChild("Backpack")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if char and backpack and humanoid then
        local tool = backpack:FindFirstChild(rodName)
        if tool then humanoid:EquipTool(tool) end
    end
    VU:SetKeyDown(Enum.KeyCode.Two)
    task.wait(0.1)
    VU:SetKeyUp(Enum.KeyCode.Two)
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
        pcall(function() Net.get("equip_ammo_on_item", rodUid, baitUid) end)
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

local function QuickWin()
    if SliderMinigame and SliderMinigame.win then
        if type(SliderMinigame.win) == "table" and SliderMinigame.win.Fire then
            SliderMinigame.win:Fire(true)
            return true
        end
    end
    return false
end

-- ============================================================
-- 13. نظام إعادة الإحياء التلقائي
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
                    pcall(function() Net.send("death_screen_request_respawn") end)
                    print("✅ تم إعادة الإحياء تلقائياً (بسبب الموت)!")
                end
            end
        end
    end
end)

-- ============================================================
-- 14. نظام الحماية من الخمول والتعليق
-- ============================================================
task.spawn(function()
    while true do
        task.wait(5)
        if not Config.AutoFarmActive then
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
                print("⚠️ [Anti-Stuck] تم اكتشاف خمول! جاري إعادة الإحياء لكسر التعليق...")
                pcall(function() Net.send("request_respawn") end)
                task.wait(2)
                UpdateActivity()
            end
        end
    end
end)

-- ============================================================
-- 15. الدورة الرئيسية للصيد (Auto Farm)
-- ============================================================
function StartAutoFarm()
    print("🚀 بدء تشغيل Auto Farm!")
    
    task.spawn(function()
        while Config.AutoFarmActive do
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

    if Config.AutoBuyEnabled then
        BuyEquipment()
        if not Config.AutoFarmActive then return end
    end

    EquipRod()
    if not Config.AutoFarmActive then return end

    while Config.AutoFarmActive do
        if not Client.Character or not Client.Character.Parent then
            task.wait(1)
            continue
        end
        
        Character = Client.Character
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        RootPart = Character:FindFirstChild("HumanoidRootPart")

        if isProtectionTriggered then
            while isProtectionTriggered and Config.AutoFarmActive do task.wait(0.5) end
            if not Config.AutoFarmActive then break end
            continue
        end

        EnsureRodEquipped()

        local zone = Config.ZoneSelect
        local data = Zones[zone]
        if not data then task.wait(1); continue end

        local inventoryCount = Sf:GetInventoryCount()
        local hasBait = Sf:HasAnyBait()
        
        if inventoryCount >= 17 or not hasBait then
            RootPart.Anchored = false
            
            local fishCount = Sf:GetFishCount()
            if fishCount > 0 then
                Sf:SellFishWithPath()
                task.wait(0.5)
            end
            
            DepositAllMoney()
            
            if not Config.AutoFarmActive then break end
            
            hasBait = Sf:HasAnyBait()
            if not hasBait then
                BuyEquipment()
                if not Config.AutoFarmActive then break end
                EquipRod()
            end
        end

        if Config.AutoFarmActive and inventoryCount < 17 and Sf:HasAnyBait() then
            Sf:Teleport(data.Pos, true, Config.WalkSpeed)
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
            
            if rodTool then
                pcall(function() Net.get("throw_rod", rodTool, castPos) end)
            else
                pcall(function() VU:ClickButton1(Vector2.new(500, 300)) end)
            end
            
            UpdateActivity()

            local timeout = tick() + 25
            local progressBarVisible = false
            
            while Config.AutoFarmActive and tick() < timeout do
                if isProtectionTriggered then
                    if rodTool then pcall(function() Net.send("reel_ended", rodTool, false) end) end
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
                -- ✅ تم تعديل الانتظار إلى 1.3 ثانية قبل السكب
                task.wait(1.3)
                QuickWin()
                if rodTool then
                    pcall(function() Net.send("reel_ended", rodTool, true) end)
                end
                UpdateActivity()
            else
                if rodTool then
                    pcall(function() Net.send("reel_ended", rodTool, false) end)
                end
            end
        end
        task.wait(1)
    end
    
    RootPart.Anchored = false
    print("🛑 تم إيقاف Auto Farm")
end

print("✅ تم تحميل القائمة بنجاح!")
print("⚡ تم تحسين سرعة شراء المعدات والطعم بشكل هائل!")
print("🛡️ تم تفعيل نظام الحماية من الخمول والتعليق!")
