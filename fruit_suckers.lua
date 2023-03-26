for i,v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
    v:Disable()
end

setfflag("HumanoidParallelRemoveNoPhysics", "False")
setfflag("HumanoidParallelRemoveNoPhysicsNoSimulate2", "False")

local Material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()
            
local UI = Material.Load({Title = "Fruit Warriors | Lazy Hub", Style = 1, SizeX = 500, SizeY = 350, Theme = "Dark"})

local mainTab = UI.New({Title = "Main"})
local miscTab = UI.New({Title = "Other"})

local lp = game.Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()

function getQuests()
    local questNpc = {}

    for i,v in pairs(game:GetService("Workspace").Mobs:GetChildren()) do
        if not table.find(questNpc, v.Name) then
            table.insert(questNpc, v.Name)
        end
    end

    table.sort(questNpc, function(a, s)
        local a1 = tonumber(string.match(a, "%d+"))
        local b1 = tonumber(string.match(s, "%d+"))

        return a1 < b1
    end)

    return questNpc
end

function getTools()
    local tools = {}

    for i, v in pairs(lp.Backpack:GetChildren()) do
        if not table.find(tools, v.Name) then
            table.insert(tools, v.Name)
        end
    end

    return tools
end

function get_mob(name)
    local mob, dist = nil, math.huge

    if (not lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) then return end

    for i,v in pairs(workspace:FindFirstChild("Mobs"):GetChildren()) do
        if (not name or v.Name == name) then
            local root = v:FindFirstChild("HumanoidRootPart")
            local humanoid = v:FindFirstChildWhichIsA("Humanoid")

            if (root and humanoid and humanoid.Health > 0) then
                local mag = (lp.Character:WaitForChild("HumanoidRootPart").Position - root.Position).magnitude
                
                if (mag < dist) then
                    dist = mag
                    mob = v
                end
            end
        end
    end

    return mob
end

function tpToFarm(target)
    if (not lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) then return end

    if getgenv().farm_method == "Above/Below" then
        lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(target:GetPivot().Position + Vector3.new(0,distance_from_mob,0))
    else
        lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(target:FindFirstChild("HumanoidRootPart").Position + target:FindFirstChild("HumanoidRootPart").CFrame.lookVector * -distance_from_mob, target:FindFirstChild("HumanoidRootPart").Position)
    end
end

local PlaceID = game.PlaceId
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local Deleted = false
local File = pcall(function()
    AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
end
function TPReturner()
    local Site;
    if foundAnything == "" then
        Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
    else
        Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
    end
    local ID = ""
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end
    local num = 0;
    for i,v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)
        if tonumber(v.maxPlayers) > tonumber(v.playing) then
            for _,Existing in pairs(AllIDs) do
                if num ~= 0 then
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                else
                    if tonumber(actualHour) ~= tonumber(Existing) then
                        local delFile = pcall(function()
                            delfile("NotSameServers.json")
                            AllIDs = {}
                            table.insert(AllIDs, actualHour)
                        end)
                    end
                end
                num = num + 1
            end
            if Possible == true then
                table.insert(AllIDs, ID)
                wait()
                pcall(function()
                    writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                    wait()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
                end)
                wait(4)
            end
        end
    end
end

function Teleport()
    while wait() do
        pcall(function()
            TPReturner()
            if foundAnything ~= "" then
                TPReturner()
            end
        end)
    end
end

-- main tab

mainTab.Label({Text = "Farm"})

local mobs_drop = mainTab.Dropdown({Text = "Select Mob", Callback = function(t)
    getgenv().npc_name = t
end, Options = getQuests()})

getgenv().npc_name = "Bandit (Level 1)"

mainTab.Button({Text = "Refresh dropdown", Callback = function()
    mobs_drop:SetOptions(getQuests())
end})

mainTab.Toggle({Text = "Auto TP Mob", Callback = function(t)
    task.spawn(function(t)
        getgenv().auto_tp = t

        while auto_tp do task.wait()
            if not char:IsDescendantOf(lp.Character.Parent) or not char:FindFirstChild("HumanoidRootPart") or not char then char = lp.Character wait(0.5) end

            local target_mob = get_mob(npc_name)

            if (target_mob) then
                repeat task.wait()
                    tpToFarm(target_mob)
                until auto_tp == false or target_mob:FindFirstChild("Humanoid").Health <= 0

                if target_mob:FindFirstChild("Humanoid").Health <= 0 then
                    lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(1216.3323974609, 1712.4995117188, -7681.0712890625)
                end
            end
        end
    end, t)
end})

local mobs_drop = mainTab.Dropdown({Text = "Farm Method", Callback = function(t)
    getgenv().farm_method = t
end, Options = {'Above/Below', 'Front/Behind'}})

getgenv().farm_method = "Above/Below"

mainTab.Slider({Text = "Distance from NPC", Callback = function(t)
    getgenv().distance_from_mob = t
end, Min = -15, Max = 15, Def = -9})

getgenv().distance_from_mob = -9

mainTab.Toggle({Text = "Auto Quest", Callback = function(t)
    task.spawn(function(t)
        getgenv().auto_quest = t

        while auto_quest do
            if lp.PlayerGui:WaitForChild("Quests").Main.AbsolutePosition ~= Vector2.new(0, -36) then
                game:GetService("ReplicatedStorage").Remotes.QuestRemote:FireServer("GetQuest", npc_name)
            end
            task.wait(.4)
        end
    end, t)
end})

mainTab.Toggle({Text = "Hide Name", Callback = function(t)
    task.spawn(function(t)
        getgenv().hide_name = t

        while hide_name do task.wait()
            if not char:IsDescendantOf(lp.Character.Parent) or not char:FindFirstChild("HumanoidRootPart") or not char then char = lp.Character wait(0.5) end

            if (lp.Character:WaitForChild("Head").MobGUI.GUI.Info:FindFirstChild("NPCName")) then
                lp.Character:WaitForChild("Head").MobGUI.GUI.Info:FindFirstChild("NPCName"):Destroy()
            elseif (lp.Character:WaitForChild("Head").MobGUI.BountyUI:FindFirstChild("Bounty")) then
                lp.Character:WaitForChild("Head").MobGUI.BountyUI:FindFirstChild("Bounty"):Destroy()
            end
        end
    end, t)
end})

mainTab.Label({Text = "Kill Aura"})

local tools_drop = mainTab.Dropdown({Text = "Select Tool to Attack", Callback = function(t)
    getgenv().tool_to_attack = t
end, Options = getTools()})

getgenv().tool_to_attack = "Combat"

mainTab.Button({Text = "Refresh dropdown", Callback = function()
    tools_drop:SetOptions(getTools())
end})

mainTab.Toggle({Text = "Kill Aura", Callback = function(t)
    task.spawn(function(t)
        getgenv().kill_aura = t

        while kill_aura do task.wait()
            task.spawn(function()
                for i, v in pairs(workspace:FindFirstChild("Mobs"):GetChildren()) do
                    if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
                        local closest = (lp.Character:WaitForChild("HumanoidRootPart").Position - v:FindFirstChild("HumanoidRootPart").Position).magnitude
                        
                        if closest < 50 then
                            if lp.Character:FindFirstChild(tool_to_attack) then
                                game:GetService("ReplicatedStorage").Remotes.Mouse1Combat:FireServer(tool_to_attack)
                                task.wait()
                                game:GetService("ReplicatedStorage").Remotes.M1sDamage:FireServer(tool_to_attack, v)
                            else
                                lp.Backpack:FindFirstChild(tool_to_attack).Parent = lp.Character
                            end
                        end
                    end
                end
            end)
        end
    end, t)
end})

-- misc tab

miscTab.Label({Text = "Collect"})

miscTab.Button({Text = "Collect all Chests", function()
    for i, v in pairs(game:GetService("Workspace").Chests:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("RootPart") then
            lp.Character:WaitForChild("HumanoidRootPart").CFrame = v:GetPivot()
            wait(.3)
            fireproximityprompt(v:FindFirstChild("RootPart").PromptAttachment.ProximityPrompt, 7)
        end
    end
end})

miscTab.Button({Text = "Collect all Fruits", function()
    for i, v in pairs(game:GetService("Workspace").Fruits:GetChildren()) do
        if v:IsA("Model") then
            lp.Character:WaitForChild("HumanoidRootPart").CFrame = v:GetPivot()
            wait(.3)
            fireproximityprompt(v:FindFirstChild(v.Name).PromptAttachment.ProximityPrompt, 7)
        end
    end
end})

miscTab.Button({Text = "Server Hop", function()
    Teleport()
end})

game:GetService('RunService').Stepped:Connect(function()
    if auto_tp then
        lp.Character:WaitForChild("Humanoid"):ChangeState(11)
    end
end)
