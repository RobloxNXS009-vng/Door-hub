_G.ESPKeys = false
_G.ESPItems = false
_G.ESPEntity = false
_G.AutoPickKey = false
_G.AutoUseCrucifix = false
_G.AntiScreech = false
_G.NoclipEnabled = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = function() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end

local function SafeWaitForChild(parent, childName)
    local success, result = pcall(function() return parent:WaitForChild(childName, 5) end)
    return result
end

local function WaitChilds(path, ...)
    local last = path
    for _, child in ipairs({...}) do
        last = last:FindFirstChild(child) or SafeWaitForChild(last, child)
        if not last then break end
    end
    return last
end

local function round(n) return math.floor(tonumber(n) + 0.5) end

local TweenSpeed = 350
local function TweenToCFrame(targetCFrame)
    if not targetCFrame then return end
    local hrp = Character():FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distance = (targetCFrame.Position - hrp.Position).Magnitude
    local tweenInfo = TweenInfo.new(math.max(0.2, distance / TweenSpeed), Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

local KeyESP = {}
local ItemESP = {}
local EntityESP = {}

local function CreateHighlightForPart(part, tbl, labelText, color)
    if not part or not part:IsA("BasePart") then return end
    if tbl[part] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "BF_Doors_Hl"
    highlight.Adornee = part
    highlight.FillTransparency = 0.6
    if color then highlight.FillColor = color end
    highlight.Parent = part
    local bill = Instance.new("BillboardGui")
    bill.Name = "BF_Doors_Bill"
    bill.Adornee = part
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0,180,0,40)
    bill.StudsOffset = Vector3.new(0, 2.2, 0)
    bill.Parent = part
    local lbl = Instance.new("TextLabel", bill)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextWrapped = true
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.Text = labelText or part.Name
    tbl[part] = {highlight = highlight, bill = bill}
end

local function RemoveHighlightForPart(part, tbl)
    if not part then return end
    local entry = tbl[part]
    if entry then
        if entry.highlight and entry.highlight.Parent then entry.highlight:Destroy() end
        if entry.bill and entry.bill.Parent then entry.bill:Destroy() end
        tbl[part] = nil
    end
end

local function IsKey(obj)
    return (obj.Name:lower():find("key") ~= nil) and obj:IsA("BasePart")
end

local function IsItem(obj)
    local n = obj.Name:lower()
    if not obj:IsA("BasePart") then return false end
    return n:find("crucifix") or n:find("candle") or n:find("lockpick") or n:find("lighter") or n:find("knife") or n:find("vitamin")
end

local function IsEntity(obj)
    local n = obj.Name:lower()
    return (n:find("rush") or n:find("screech") or n:find("ambush") or n:find("figure") or n:find("seek") or n:find("ambush")) and obj:FindFirstChild("HumanoidRootPart")
end

local function UpdateESPLabels(tbl)
    for part,entry in pairs(tbl) do
        if part and part.Parent and entry and entry.bill and entry.bill:FindFirstChildOfClass("TextLabel") then
            local lbl = entry.bill:FindFirstChildOfClass("TextLabel")
            local hrp = Character():FindFirstChild("HumanoidRootPart")
            if lbl and hrp then
                local dist = round((hrp.Position - part.Position).Magnitude)
                lbl.Text = part.Name .. "\n" .. tostring(dist) .. " studs"
            end
        else
            tbl[part] = nil
        end
    end
end

local function ScanWorkspaceAndMakeESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if _G.ESPKeys and IsKey(obj) then CreateHighlightForPart(obj, KeyESP, "Key", Color3.fromRGB(0,255,0)) end
            if _G.ESPItems and IsItem(obj) then CreateHighlightForPart(obj, ItemESP, obj.Name, Color3.fromRGB(255,200,0)) end
            if _G.ESPEntity and IsEntity(obj) then CreateHighlightForPart(obj.HumanoidRootPart or obj, EntityESP, obj.Name, Color3.fromRGB(255,50,50)) end
        end)
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    pcall(function()
        if _G.ESPKeys and IsKey(obj) then CreateHighlightForPart(obj, KeyESP, "Key", Color3.fromRGB(0,255,0)) end
        if _G.ESPItems and IsItem(obj) then CreateHighlightForPart(obj, ItemESP, obj.Name, Color3.fromRGB(255,200,0)) end
        if _G.ESPEntity and IsEntity(obj) then CreateHighlightForPart(obj.HumanoidRootPart or obj, EntityESP, obj.Name, Color3.fromRGB(255,50,50)) end
    end)
end)

Workspace.DescendantRemoving:Connect(function(obj)
    pcall(function()
        if KeyESP[obj] then RemoveHighlightForPart(obj, KeyESP) end
        if ItemESP[obj] then RemoveHighlightForPart(obj, ItemESP) end
        for part, _ in pairs(EntityESP) do
            if part == obj or part.Parent == nil then RemoveHighlightForPart(part, EntityESP) end
        end
    end)
end)

local function TryPickKeyOn(part)
    if not part or not part.Parent then return end
    local prompt = part:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then pcall(function() prompt:InputHoldBegin() task.wait(0.05) prompt:InputHoldEnd() end) end
end

local function FindCrucifixTool()
    local char = Character()
    if char then
        for _,v in ipairs(char:GetChildren()) do if v:IsA("Tool") and v.Name:lower():find("crucifix") then return v end end
    end
    for _,v in ipairs(LocalPlayer.Backpack:GetChildren()) do if v:IsA("Tool") and v.Name:lower():find("crucifix") then return v end end
    return nil
end

local function TryAutoUseCrucifixIfNeeded()
    if not _G.AutoUseCrucifix then return end
    local char = Character()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _,ent in ipairs(Workspace:GetDescendants()) do
        if IsEntity(ent) then
            local entityRoot = ent:FindFirstChild("HumanoidRootPart") or ent
            if entityRoot and (entityRoot.Position - hrp.Position).Magnitude <= 20 then
                local tool = FindCrucifixTool()
                if tool then
                    pcall(function()
                        if LocalPlayer.Backpack:FindFirstChild(tool.Name) then
                            LocalPlayer.Character.Humanoid:EquipTool(tool)
                            task.wait(0.05)
                        end
                        if tool and tool.Parent == LocalPlayer.Character then
                            if tool.Activate then tool:Activate() else pcall(function() tool:FireServer() end) end
                        end
                    end)
                end
            end
        end
    end
end

local function HandleScreechSpawn(screechModel)
    pcall(function() print("[DoorsHub] Screech detected! Taking evasive action.") end)
    local hrp = Character():FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local closet = nil
    for _,v in ipairs(Workspace:GetDescendants()) do
        local ln = v.Name:lower()
        if (ln:find("wardrobe") or ln:find("closet") or ln:find("wardrobe")) and v:IsA("BasePart") then
            closet = v
            break
        end
    end
    if closet then TweenToCFrame(closet.CFrame + Vector3.new(0,3,0)) else TweenToCFrame(hrp.CFrame * CFrame.new(0,0,-10)) end
end

Workspace.DescendantAdded:Connect(function(obj)
    pcall(function()
        if _G.AntiScreech then
            local name = obj.Name:lower()
            if name:find("screech") or name:find("screechentity") then HandleScreechSpawn(obj) end
        end
        if _G.AutoPickKey and IsKey(obj) then
            if obj:FindFirstChildOfClass("ProximityPrompt") then TryPickKeyOn(obj)
            else for _,p in ipairs(obj:GetDescendants()) do if p:IsA("BasePart") and p:FindFirstChildOfClass("ProximityPrompt") then TryPickKeyOn(p) break end end
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if _G.ESPKeys then UpdateESPLabels(KeyESP) end
    if _G.ESPItems then UpdateESPLabels(ItemESP) end
    if _G.ESPEntity then UpdateESPLabels(EntityESP) end
    if _G.AutoPickKey then for part,_ in pairs(KeyESP) do pcall(function() TryPickKeyOn(part) end) end end
    if _G.AutoUseCrucifix then pcall(TryAutoUseCrucifixIfNeeded) end
    if _G.NoclipEnabled then
        local char = Character()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    end
end)

ScanWorkspaceAndMakeESP()