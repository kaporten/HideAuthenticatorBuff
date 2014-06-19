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
	-- Initial one-time 10sec timer after loading. 
	self.timer = ApolloTimer.Create(10.000, false, "HideBuff", self)

	--[[
		This requires explanation :-/
		
		I can find the individual buff-window on the GUI, but the only detail on 
		which buff each window represents is the GetBuffTooltip(). So, I compare 
		for known tooltips across different locales, in order to identify the
		buff-window to hide.
		
		And, for some reason, the good folks at Carbine decided to stick a char(194) 
		which LOOKS like a space (except space is 32) in between the 2 and % signs. 
		
		I've had no luck actually reproducing this char(194) myself, so I ended
		up just cutting the tooltip-string at the index on which it occurs.		
	]]
	
	-- Default: en	
	self.buffTooltip = "XP, Renown, and Prestige gain is increased by 2%."
	self.endIdx = string.len(self.buffTooltip)

	-- Check locale for de and fr. 
	local strCancel = Apollo.GetString(1)	
	if strCancel == "Abbrechen" then 
		--                                                      | idx 37 contains char(194)
		self.buffTooltip = "Gewinn an EP, Ruhm und Prestige um 2 % erhöht."
		self.endIdx = 36
	end
	if strCancel == "Annuler" then
		--                                                                              | idx 61 contains char(194)		
		self.buffTooltip = "Les gains d'EXP, de renommée et de prestige augmentent de 2 %."
		self.endIdx = 60
	end
end

function HideAuthenticatorBuff:HideBuff()
	-- Repeatable 60 sec timer to re-check for buff if it gets shown again (or missed the 1st time around)
	self.timer = ApolloTimer.Create(60.000, true, "HideBuff", self)
	
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
	self.buffs = {}
	for _,buff in ipairs(buffs) do
		self.buffs[_] = buff
		local tooltip = buff:GetBuffTooltip()
		
		if string.sub(tooltip, 1, self.endIdx) == string.sub(self.buffTooltip, 1, self.endIdx) then
			-- If tooltip is a partial match (and still visible), print that it is being hidden			
			if buff:IsShown() then
				ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "Hiding Authenticator buff")
				buff:Show(false, true)
			end
			break
		end
	end
end

local HideAuthenticatorBuffInst = HideAuthenticatorBuff:new()
HideAuthenticatorBuffInst:Init()