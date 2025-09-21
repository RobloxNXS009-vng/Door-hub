_G.ESPKeys = true
_G.ESPItems = true
_G.ESPEntity = true
_G.AutoPickKey = true
_G.AutoUseCrucifix = true
_G.AntiScreech = true
_G.NoclipEnabled = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local function Character() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function round(n) return math.floor(tonumber(n)+0.5) end
local TweenSpeed = 350
local function TweenToCFrame(cframe)
    local hrp = Character():FindFirstChild("HumanoidRootPart")
    if not hrp or not cframe then return end
    local dist = (cframe.Position - hrp.Position).Magnitude
    local tween = TweenService:Create(hrp,TweenInfo.new(math.max(0.2,dist/TweenSpeed),Enum.EasingStyle.Linear),{CFrame=cframe})
    tween:Play()
end

local KeyESP,ItemESP,EntityESP = {},{},{}
local function CreateHighlightForPart(part,tbl,label,color)
    if not part or tbl[part] then return end
    local h = Instance.new("Highlight")
    h.Adornee = part
    h.FillTransparency = 0.6
    if color then h.FillColor=color end
    h.Parent = part
    local b = Instance.new("BillboardGui",part)
    b.Adornee = part
    b.AlwaysOnTop = true
    b.Size = UDim2.new(0,180,0,40)
    b.StudsOffset = Vector3.new(0,2.2,0)
    local l = Instance.new("TextLabel",b)
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1
    l.TextWrapped=true
    l.Font=Enum.Font.GothamSemibold
    l.TextSize=14
    l.Text=label or part.Name
    tbl[part]={highlight=h,bill=b}
end

local function RemoveHighlightForPart(part,tbl)
    if not part or not tbl[part] then return end
    local e=tbl[part]
    if e.highlight then e.highlight:Destroy() end
    if e.bill then e.bill:Destroy() end
    tbl[part]=nil
end

local function IsKey(obj) return obj:IsA("BasePart") and obj.Name:lower():find("key") end
local function IsItem(obj)
    local n=obj.Name:lower()
    return obj:IsA("BasePart") and (n:find("crucifix") or n:find("candle") or n:find("lockpick") or n:find("knife") or n:find("vitamin"))
end
local function IsEntity(obj)
    local n=obj.Name:lower()
    return obj:FindFirstChild("HumanoidRootPart") and (n:find("rush") or n:find("screech") or n:find("ambush") or n:find("figure") or n:find("seek"))
end

local function UpdateESP(tbl)
    for part,e in pairs(tbl) do
        if part and part.Parent and e and e.bill and e.bill:FindFirstChildOfClass("TextLabel") then
            local l=e.bill:FindFirstChildOfClass("TextLabel")
            local hrp=Character():FindFirstChild("HumanoidRootPart")
            if l and hrp then
                l.Text=part.Name.."\n"..tostring(round((hrp.Position-part.Position).Magnitude)).." studs"
            end
        else tbl[part]=nil end
    end
end

local function ScanWorkspace()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if _G.ESPKeys and IsKey(obj) then CreateHighlightForPart(obj,KeyESP,"Key",Color3.fromRGB(0,255,0)) end
            if _G.ESPItems and IsItem(obj) then CreateHighlightForPart(obj,ItemESP,obj.Name,Color3.fromRGB(255,200,0)) end
            if _G.ESPEntity and IsEntity(obj) then CreateHighlightForPart(obj.HumanoidRootPart,obj.Name,EntityESP,Color3.fromRGB(255,50,50)) end
        end)
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    pcall(function()
        if _G.ESPKeys and IsKey(obj) then CreateHighlightForPart(obj,KeyESP,"Key",Color3.fromRGB(0,255,0)) end
        if _G.ESPItems and IsItem(obj) then CreateHighlightForPart(obj,ItemESP,obj.Name,Color3.fromRGB(255,200,0)) end
        if _G.ESPEntity and IsEntity(obj) then CreateHighlightForPart(obj.HumanoidRootPart,obj.Name,EntityESP,Color3.fromRGB(255,50,50)) end
        if _G.AutoPickKey and IsKey(obj) then
            local prompt=obj:FindFirstChildOfClass("ProximityPrompt")
            if prompt then pcall(function() prompt:InputHoldBegin();task.wait(0.05);prompt:InputHoldEnd() end) end
        end
        if _G.AntiScreech and obj.Name:lower():find("screech") then
            local hrp=Character():FindFirstChild("HumanoidRootPart")
            if hrp then TweenToCFrame(hrp.CFrame*CFrame.new(0,0,-10)) end
        end
    end)
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if KeyESP[obj] then RemoveHighlightForPart(obj,KeyESP) end
    if ItemESP[obj] then RemoveHighlightForPart(obj,ItemESP) end
    for p,_ in pairs(EntityESP) do if p==obj or p.Parent==nil then RemoveHighlightForPart(p,EntityESP) end end
end)

local function FindCrucifix()
    local c=Character()
    for _,v in ipairs(c:GetChildren()) do if v:IsA("Tool") and v.Name:lower():find("crucifix") then return v end end
    for _,v in ipairs(LocalPlayer.Backpack:GetChildren()) do if v:IsA("Tool") and v.Name:lower():find("crucifix") then return v end
    return nil
end

local function AutoUseCrucifix()
    if not _G.AutoUseCrucifix then return end
    local hrp=Character():FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _,ent in ipairs(Workspace:GetDescendants()) do
        if IsEntity(ent) then
            local eHRP=ent:FindFirstChild("HumanoidRootPart") or ent
            if eHRP and (eHRP.Position-hrp.Position).Magnitude<=20 then
                local t=FindCrucifix()
                if t then pcall(function() LocalPlayer.Character.Humanoid:EquipTool(t);task.wait(0.05);if t.Activate then t:Activate() end end) end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if _G.ESPKeys then UpdateESP(KeyESP) end
    if _G.ESPItems then UpdateESP(ItemESP) end
    if _G.ESPEntity then UpdateESP(EntityESP) end
    if _G.AutoPickKey then for p,_ in pairs(KeyESP) do pcall(function() local prm=p:FindFirstChildOfClass("ProximityPrompt"); if prm then prm:InputHoldBegin();task.wait(0.05);prm:InputHoldEnd() end end) end end
    AutoUseCrucifix()
    if _G.NoclipEnabled then local c=Character();if c then for _,v in ipairs(c:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end end
end)

ScanWorkspace()

local success,Fluent=pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if success and Fluent then
    local W=Fluent:CreateWindow({Title="Then Hub",SubTitle="Doors",TabWidth=150,Theme="Darker",Acrylic=false,Size=UDim2.fromOffset(520,320),MinimizeKey=Enum.KeyCode.LeftControl})
    local T={Main=W:AddTab({Title="Main"}),Player=W:AddTab({Title="Player"}),Visual=W:AddTab({Title="Visual"}),Entity=W:AddTab({Title="Entity"}),Misc=W:AddTab({Title="Misc"})}
    local S=T.Main:AddSection("Tự động")
    S:AddToggle("AutoPickKeyToggle",{Title="Auto Pick Key",Default=true}):OnChanged(function(v)_G.AutoPickKey=v end)
    S:AddToggle("AutoUseCrucifixToggle",{Title="Auto Use Crucifix",Default=true}):OnChanged(function(v)_G.AutoUseCrucifix=v end)
    local SP=T.Player:AddSection("Người chơi")
    SP:AddSlider("WalkSpeed",{Title="WalkSpeed",Min=16,Max=150,Default=16,Rounding=1}):OnChanged(function(v) pcall(function() local c=Character();if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=v end end) end)
    SP:AddToggle("NoclipToggle",{Title="Noclip (Auto)",Default=false}):OnChanged(function(v)_G.NoclipEnabled=v end)
    local SV=T.Visual:AddSection("ESP")
    SV:AddToggle("ESPKeysToggle",{Title="ESP Keys",Default=true}):OnChanged(function(v)_G.ESPKeys=v; if v then ScanWorkspace() else for p,_ in pairs(KeyESP) do RemoveHighlightForPart(p,KeyESP) end end end)
    SV:AddToggle("ESPItemsToggle",{Title="ESP Items",Default=true}):OnChanged(function(v)_G.ESPItems=v; if v then ScanWorkspace() else for p,_ in pairs(ItemESP) do RemoveHighlightForPart(p,ItemESP) end end end)
    SV:AddToggle("ESPEntityToggle",{Title="ESP Entities",Default=true}):OnChanged(function(v)_G.ESPEntity=v;if v then ScanWorkspace() else for p,_ in pairs(EntityESP) do RemoveHighlightForPart(p,EntityESP) end end end)
    local SE=T.Entity:AddSection("Entity")
    SE:AddToggle("AntiScreechToggle",{Title="Anti Screech",Default=true}):OnChanged(function(v)_G.AntiScreech=v end)
    SE:AddButton("Teleport to nearest entity",function()
        local hrp=Character():FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local n,d=nil,math.huge
        for _,e in ipairs(Workspace:GetDescendants()) do
            if IsEntity(e) then
                local r=e:FindFirstChild("HumanoidRootPart")
                if r then local dist=(r.Position-hrp.Position).Magnitude;if dist<d then d=dist;n=r end
                end
            end
        end
        if n then TweenToCFrame(n.CFrame+Vector3.new(0,3,0)) end
    end)
    local SM=T.Misc:AddSection("Misc")
    SM:AddButton("Refresh ESP scan",function() ScanWorkspace() end)
    SM:AddButton("Remove all ESP",function()
        for k,_ in pairs(KeyESP) do RemoveHighlightForPart(k,KeyESP) end
        for k,_ in pairs(ItemESP) do RemoveHighlightForPart(k,ItemESP) end
        for k,_ in pairs(EntityESP) do RemoveHighlightForPart(k,EntityESP) end
    end)
end

print("[DoorsHub] Base loaded")