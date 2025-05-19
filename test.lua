
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

local Events = ReplicatedStorage:WaitForChild("Events")
local CodeData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CodeData"))
local TrainModuleFunctions = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EatAtTableModules"):WaitForChild("EatAtTableSharedFunctions"))

local function WaitForChildRecursive(parent, path)
	for _, name in ipairs(path) do
		parent = parent:WaitForChild(name)
	end
	return parent
end

local RebirthLabel = WaitForChildRecursive(LocalPlayer.PlayerGui, {
	"MainUi", "Right", "Currency", "Rebirths", "TextLabel"
})
local Power = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("Power")

getgenv().AutoTrain = false
getgenv().CurrentRebirths = tonumber(RebirthLabel.Text)
getgenv().CurrentDamage = Power.Value
getgenv().CurrentStage = 1
getgenv().CurrentTreadmill = 1

getgenv().conn = getgenv().conn or {}
for _, connection in pairs(getgenv().conn) do
	if typeof(connection) == "RBXScriptConnection" then
		connection:Disconnect()
	end
end
getgenv().conn = {}

getgenv().conn.RebirthListener = RebirthLabel:GetPropertyChangedSignal("Text"):Connect(function()
	getgenv().CurrentRebirths = tonumber(RebirthLabel.Text)
end)

getgenv().conn.DamageListener = Power:GetPropertyChangedSignal("Value"):Connect(function()
	getgenv().CurrentDamage = Power.Value
end)

function GetCurrentRebirth()
	while getgenv().CurrentRebirths == nil do task.wait() end
	return getgenv().CurrentRebirths
end

function GetCurrentDamage()
	while getgenv().CurrentDamage == nil do task.wait() end
	return getgenv().CurrentDamage
end

function CalculateBestByRebirth()
	for i = 1, tonumber(TrainModuleFunctions.NumberOfTables) do
		local required = TrainModuleFunctions.getTableRebirthRequirement(1, i)
		if GetCurrentRebirth() < required then
			return math.max(i - 1, 1)
		end
	end
	return TrainModuleFunctions.NumberOfTables
end

function CalculateBestByDamage()
	for i = 1, tonumber(TrainModuleFunctions.NumberOfTables) do
		local required = TrainModuleFunctions.getTableDamageRequirement(1, i)
		if GetCurrentDamage() < required then
			return math.max(i - 1, 1)
		end
	end
	return TrainModuleFunctions.NumberOfTables
end

function AutoTrainBest()
	task.spawn(function()
		while getgenv().AutoTrain do
			local BestByRebirth = CalculateBestByRebirth()
			local BestByDamage = CalculateBestByDamage()

			getgenv().CurrentTreadmill = math.max(BestByRebirth, BestByDamage)

			local args = {
				{ tableNumber = getgenv().CurrentTreadmill, stageNumber = getgenv().CurrentStage }
			}
			Events.DamageIncreaseOnClickEvent:FireServer(unpack(args))

			task.wait()
		end
	end)
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Brainrot Training",
	Icon = 0,
	LoadingTitle = "Rayfield Interface Suite",
	Theme = "Default",
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = nil,
		FileName = "Big Hub",
	},
	Discord = {
		Enabled = false,
		Invite = "noinvitelink",
		RememberJoins = true,
	},
	KeySystem = false,
})

local MainTab = Window:CreateTab("Main", "Box")
MainTab:CreateSection("Farming")

MainTab:CreateToggle({
	Name = "Auto Train",
	CurrentValue = false,
	Flag = "AutoTrainToggle",
	Callback = function(enabled)
		getgenv().AutoTrain = enabled
		if enabled then
			AutoTrainBest()
		end
	end,
})

local MiscTab = Window:CreateTab("Misc", "Box")
MiscTab:CreateSection("Miscellaneous")

MiscTab:CreateButton({
	Name = "Disable Click Pop Ups",
	Callback = function()
		local GUI = LocalPlayer.PlayerGui:FindFirstChild("CoinGem")
		if GUI then
			GUI.Enabled = false
		end
	end,
})

MiscTab:CreateButton({
	Name = "Claim All Codes",
	Callback = function()
		task.spawn(function()
			for code in pairs(CodeData) do
				local args = { "Claim", code }
				Events:WaitForChild("CodeEvent"):InvokeServer(unpack(args))
			end
		end)
	end,
})

