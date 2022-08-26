if game:GetService("CoreGui"):FindFirstChild("ui") then
    game:GetService("CoreGui"):FindFirstChild("ui"):Destroy()
end

local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(
function()
    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end) -- anti afk

local lib = loadstring(game:HttpGet"https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt")()

local win = lib:Window("One Punch Fighters | Lazy Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.RightControl)

local mainTab = win:Tab("Main Tab")
local eggTab = win:Tab("Egg Tab")

getgenv().AutoFarm = nil
getgenv().lvlFarm = nil
getgenv().Area = nil
getgenv().AreaEgg = nil
getgenv().AreaEggTog = nil
getgenv().click = nil
getgenv().collect = nil
getgenv().FarmDistance = 5

local lp = game.Players.LocalPlayer
local char = lp.Character

setfflag("HumanoidParallelRemoveNoPhysics", "False")
setfflag("HumanoidParallelRemoveNoPhysicsNoSimulate2", "False")

function getAreas()
    local t = {}

    for i,v in pairs(game:GetService("Workspace")["__TrainingZones"]:GetChildren()) do
        if v.Name:match("Area") and not table.find(t, v.Name) then
            table.insert(t, v.Name)
        end
    end

    table.sort(t, function(a, s)
        local a1 = tonumber(string.match(a, "%d+"))
        local b1 = tonumber(string.match(s, "%d+"))

        return a1 < b1
    end)
    
    return t
end

function getEggs()
    local t = {}
    
    for i, v in pairs(game:GetService("Workspace")["__Zones"]["__Summons"]:GetChildren()) do
        if v:IsA("Part") and not table.find(t, v.Name) then
            table.insert(t, v.Name)
        end
    end
    
    table.sort(t, function(a, s)
        local a1 = tonumber(string.match(a, "%d+"))
        local b1 = tonumber(string.match(s, "%d+"))

        return a1 < b1
    end)
    
    return t
end


mainTab:Dropdown("Select Area", getAreas(), function(t)
    getgenv().Area = t
    
    game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = game:GetService("Workspace")["__TrainingZones"][getgenv().Area].CFrame
    
    local args = {
        [1] = "BuyWorld",
        [2] = tostring(getgenv().Area)
    }
    
    game:GetService("ReplicatedStorage").Game.__Remotes.RemoteEvent:FireServer(unpack(args))
end)

mainTab:Toggle("Auto Farm", false, function(t)
    getgenv().AutoFarm = t

    game:GetService('RunService').Stepped:connect(function()
        if getgenv().AutoFarm then
            lp.Character:WaitForChild("Humanoid"):ChangeState(11)
        end
    end)

    while getgenv().AutoFarm do task.wait()
        if not char:IsDescendantOf(lp.Character.Parent) or not char:FindFirstChild("HumanoidRootPart") or not char then char = lp.Character wait(0.5) end
        
        for i,v in pairs(workspace.__GAME.__Mobs:WaitForChild(getgenv().Area):GetChildren()) do
            if v:IsA("Model") then
	           if v:FindFirstChild("NpcConfiguration").Health.Value > 0 then
	               local args = {
	                   [1] = "Attack",
	                   [2] = v
	               }
	                    
	               game:GetService("ReplicatedStorage").Game.__Remotes.AttackEvent:FireServer(unpack(args))
                   lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(v:GetModelCFrame().Position + Vector3.new(0,-tonumber(getgenv().FarmDistance),0))
                end
            end
        end
    end
end)

mainTab:Slider("Distance From NPC", 1, 50, 5, function(t)
    getgenv().FarmDistance = t
end)

mainTab:Toggle("Auto Click", false, function(t)
    getgenv().click = t

    while getgenv().click do task.wait(.1)
        local args = {
            [1] = "Normal"
        }
        
        game:GetService("ReplicatedStorage").Game.__Remotes.ClickEvent:FireServer(unpack(args))
    end
end)

mainTab:Toggle("Auto Collect", false, function(t)
    getgenv().collect = t
    
    while getgenv().collect do task.wait(.2)
        if not char:IsDescendantOf(lp.Character.Parent) or not char:FindFirstChild("HumanoidRootPart") or not char then char = lp.Character wait(0.5) end
        
        for i,v in pairs(game:GetService("Workspace")["__Cache"]:GetChildren()) do
            if v.Name == "CollisionPart" then
                if v:IsA("Part") and v.Position == Vector3.new(0, 1e+09, 0) then
                    v.Size = Vector3.new(0.5,0.5,0.5)
                else
                    v.Size = Vector3.new(0.5,0.5,0.5)
                    v.CFrame = lp.Character:WaitForChild("HumanoidRootPart").CFrame
                end
            end
        end
    end
end)

mainTab:Button("Rejoin", function()
    game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId)
end)

eggTab:Dropdown("Select Area", getEggs(), function(t)
    getgenv().AreaEgg = t
end)

eggTab:Toggle("Auto Open", false, function(t)
    getgenv().AreaEggTog = t
    
    while getgenv().AreaEggTog do task.wait(.4)
        local args = {
            [1] = "Summon",
            [2] = {
                ["Quanty"] = 1,
                ["World"] = tostring(getgenv().AreaEgg)
            }
        }
        
        game:GetService("ReplicatedStorage").Game.__Remotes.HeroEvent:FireServer(unpack(args))
    end
end)
