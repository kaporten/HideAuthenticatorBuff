require "Window"
 
local HideAuthenticatorBuff = {} 
function HideAuthenticatorBuff:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 
	return o
end

function HideAuthenticatorBuff:Init()
	Apollo.RegisterAddon(self, false, "", "TargetFrame")
end

function HideAuthenticatorBuff:OnLoad()
	-- Initial timer scanning every second. Will be aborted when buff is hidden, or when permanent-timer kicks in
	self.initialTimer = ApolloTimer.Create(1.000, true, "HideBuff", self)
	
	-- Permanent timer scanning buffs every minute. Just in case it re-appears for some reason.
	self.permanentTimer = ApolloTimer.Create(60.000, true, "OnPermanentTimer", self)

	-- When changing instance (housing, dungeon, etc), restart the initial timer
	Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self) 
	
	-- Default: en	
	self.buffTooltip = "XP, Renown, and Prestige gain is increased by 2%."

	-- Check locale for de and fr. 
	local strCancel = Apollo.GetString(1)
	if strCancel == "Abbrechen" then 
		self.buffTooltip = "Gewinn an EP, Ruhm und Prestige um 2\194\160% erhöht."
	end
	if strCancel == "Annuler" then
		self.buffTooltip = "Les gains d'EXP, de renommée et de prestige augmentent de 2\194\160%."
	end
end

-- When changing instance, restart the initial-timer
function HideAuthenticatorBuff:OnChangeWorld()
	self:StopInitialTimer()
	self.initialTimer = ApolloTimer.Create(1.000, true, "HideBuff", self)
end

-- When the permanent timer kicks in, stop any still-running initial timer (and scan buffs)
function HideAuthenticatorBuff:OnPermanentTimer()
	self:StopInitialTimer()
	self:HideBuff()
end

-- Used to consistently stop/nil the initial timer
function HideAuthenticatorBuff:StopInitialTimer()
	if self.initialTimer ~= nil then		
		self.initialTimer:Stop()
		self.initialTimer = nil
	end
end

function HideAuthenticatorBuff:HideBuff()
	-- Safely dig into the GUI elements
	local addonTargetFrame = Apollo.GetAddon("TargetFrame")
	if addonTargetFrame == nil then return end
	
	local luaUnitFrame = addonTargetFrame.luaUnitFrame
	if luaUnitFrame == nil then return end
	
	local wndMainClusterFrame = luaUnitFrame.wndMainClusterFrame
	if wndMainClusterFrame == nil then return end
	
	local wndBeneBuffBar = wndMainClusterFrame:FindChild("BeneBuffBar")
	if wndBeneBuffBar == nil then return end
	
	local buffs = wndBeneBuffBar:GetChildren()
	if buffs == nil then return end
	
	-- Buffs found, loop over them all
	for _,buff in ipairs(buffs) do
		local tooltip = buff:GetBuffTooltip()
		if tooltip == self.buffTooltip then
			-- If tooltip is a partial match (and still visible), print that it is being hidden			
			if buff:IsShown() then
				-- ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "Hiding Authenticator buff")
				buff:Show(false, true)
				self:StopInitialTimer()
			end
			break
		end
	end
end

local HideAuthenticatorBuffInst = HideAuthenticatorBuff:new()
HideAuthenticatorBuffInst:Init()
