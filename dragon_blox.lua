local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(
function()
    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end) -- anti afk

setfflag("HumanoidParallelRemoveNoPhysics", "False")
setfflag("HumanoidParallelRemoveNoPhysicsNoSimulate2", "False")

function acceptQuest()
    local questAccept

    for i, v in pairs(game:GetService("ReplicatedStorage").Data.Dialog["NPCQuest_"..tostring(getgenv().questNPC):split("_")[2]].Welcome:GetChildren()) do
        if v.Name == "AnswerBye" then continue end
        if tostring(v) == getgenv().questNumber.."-"..tostring(v):split("-")[2] then
            questAccept = v.QuestDetails.Accept
        end
    end

    return questAccept
end

local lp = game.Players.LocalPlayer
local char = lp.Character

function isQuest()
    if not char:IsDescendantOf(lp.Character.Parent) or not char:FindFirstChild("HumanoidRootPart") or not char then char = lp.Character wait(0.5) end

    local quest
    for i, v in pairs(lp:WaitForChild("PlayerGui"):WaitForChild("MainGui").Frame.RightDisplay.Quests:GetChildren()) do
        if v.Name == "Template" and v:FindFirstChildWhichIsA("TextLabel") then
            if tostring(v:FindFirstChildWhichIsA("TextLabel").Text):split(" ")[3] == tostring(getgenv().npcName:split(" ")[1]) then
                quest = true
            else
                quest = nil
            end
        end
    end

    return quest
end

task.spawn(function()
    while getgenv().AutoFarm do task.wait()
        if not char:IsDescendantOf(lp.Character.Parent) or not char:FindFirstChild("HumanoidRootPart") or not char then char = lp.Character wait(0.5) end

        local quest = isQuest()

        if quest == true then
            for i, v in pairs(game:GetService("Workspace")["World Mobs"].Mobs:GetChildren()) do
                if v:IsA("Model") and v.Name == getgenv().npcName and v:FindFirstChild("HumanoidRootPart") then
                    if v:WaitForChild("Humanoid").Health > 0 then
                        repeat task.wait()
                            if getgenv().FarmMeth == "Above" then
                                lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(v:WaitForChild("HumanoidRootPart").Position + Vector3.new(0,tonumber(getgenv().FarmDistance),0))
                            else
                                lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(v:WaitForChild("HumanoidRootPart").Position + Vector3.new(0,-tonumber(getgenv().FarmDistance),0))
                            end
                        until v:WaitForChild("Humanoid").Health <= 0 or quest ~= true or getgenv().AutoFarm == false
                        lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(getgenv().questNPC:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0,-15,0))
                    end
                end
            end
        else
            lp.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(getgenv().questNPC:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0,-15,0))
            wait(.2)
            game:GetService("ReplicatedStorage").Aero.AeroRemoteServices.Props.DialogService.Answer:InvokeServer(acceptQuest(), getgenv().questNPC)
        end
    end
end)

task.spawn(function()
    while getgenv().AutoPunch do task.wait(.2)
        if isQuest() == true then
            game:GetService("ReplicatedStorage").Remotes.SkillRemote:FireServer({["Type"] = 1, ["Began"] = true, ["Name"] = "Combat"})
        end
    end
end)

task.spawn(function()
    while true do task.wait(.3)
        game:GetService("ReplicatedStorage").Aero.AeroRemoteServices.StatsService.RebirthUp:FireServer()
    end
end)

task.spawn(function()
    while true do task.wait()
        if not char:IsDescendantOf(lp.Character.Parent) or not char:FindFirstChild("HumanoidRootPart") or not char then char = lp.Character wait(0.5) end
        
        for i,v in pairs(lp.Character:GetChildren()) do
            if v.Name == "Head" and v:FindFirstChildWhichIsA("BillboardGui") then
                v:FindFirstChildWhichIsA("BillboardGui"):Destroy()
            end
        end
    end
end)

game:GetService('RunService').Stepped:connect(function()
    if getgenv().AutoFarm then
        lp.Character:WaitForChild("Humanoid"):ChangeState(11)
    end
end)
