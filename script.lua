local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- CẤU HÌNH TỐC ĐỘ & ANIMATION
local NORMAL_SPEED = 16
local SPRINT_SPEED = 50
local SPRINT_KEY = Enum.KeyCode.LeftShift
local CUSTOM_ANIM_ID = "rbxassetid://656118852" -- Thay ID của bạn vào đây

local isSprinting = false
local sprintTrack = nil
local sprintBtn = nil

-- NHẬN DIỆN THIẾT BỊ (Mobile/Delta vs PC)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local guiParent = (gethui and gethui()) or CoreGui or player:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("DeltaSprintGui") then
	guiParent.DeltaSprintGui:Destroy()
end

-- CHỈ TẠO UI KHI CHẠY TRÊN ĐIỆN THOẠI (DELTA)
if isMobile then
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DeltaSprintGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = guiParent

	sprintBtn = Instance.new("TextButton")
	sprintBtn.Name = "SprintButton"
	sprintBtn.Size = UDim2.new(0, 75, 0, 75)
	sprintBtn.Position = UDim2.new(0.82, 0, 0.55, 0)
	sprintBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	sprintBtn.BackgroundTransparency = 0.25
	sprintBtn.Text = "SPRINT\nOFF"
	sprintBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sprintBtn.Font = Enum.Font.GothamBold
	sprintBtn.TextSize = 14
	sprintBtn.Draggable = true
	sprintBtn.Active = true
	sprintBtn.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = sprintBtn

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(255, 255, 255)
	uiStroke.Thickness = 2
	uiStroke.Parent = sprintBtn
end

-- HÀM CẬP NHẬT TRẠNG THÁI CHẠY
local function updateSprintState(state)
	isSprinting = state
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if isSprinting then
		if sprintBtn then
			sprintBtn.Text = "SPRINT\nON"
			sprintBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		end
		if humanoid then
			humanoid.WalkSpeed = SPRINT_SPEED
		end
	else
		if sprintBtn then
			sprintBtn.Text = "SPRINT\nOFF"
			sprintBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		end
		if humanoid then
			humanoid.WalkSpeed = NORMAL_SPEED
		end
		if sprintTrack and sprintTrack.IsPlaying then
			sprintTrack:Stop(0.2)
		end
	end
end

-- SỰ KIỆN BẤM NÚT (CHỈ KÍCH HOẠT NẾU CÓ UI TRÊN MOBILE)
if sprintBtn then
	sprintBtn.MouseButton1Click:Connect(function()
		updateSprintState(not isSprinting)
	end)
end

-- THIẾT LẬP ANIMATION KHI HỒI SINH
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	local anim = Instance.new("Animation")
	anim.AnimationId = CUSTOM_ANIM_ID

	sprintTrack = animator:LoadAnimation(anim)
	sprintTrack.Priority = Enum.AnimationPriority.Action4
	sprintTrack.Looped = true
end

if player.Character then
	setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

-- SỰ KIỆN BÀN PHÍM (DÀNH CHO PC)
UserInputService.InputBegan:Connect(function(input)
	if UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == SPRINT_KEY then
		updateSprintState(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == SPRINT_KEY then
		updateSprintState(false)
	end
end)

-- DUY TRÌ TỐC ĐỘ & PHÁT ANIMATION KHI DI CHUYỂN
RunService.RenderStepped:Connect(function()
	if not isSprinting then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	humanoid.WalkSpeed = SPRINT_SPEED

	if humanoid.MoveDirection.Magnitude > 0 then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if track ~= sprintTrack and (track.Name:lower():find("run") or track.Name:lower():find("walk")) then
					track:Stop()
				end
			end
		end

		if sprintTrack and not sprintTrack.IsPlaying then
			sprintTrack:Play(0.1)
		end
	else
		if sprintTrack and sprintTrack.IsPlaying then
			sprintTrack:Stop(0.1)
		end
	end
end)
