local mod	= DBM:NewMod("Heigan", "DBM-Naxx", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20190516165414")
mod:SetCreatureID(15936)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEventsInCombat(
    "SPELL_AURA_APPLIED 9250592 29998 9250593 55011",
	"SPELL_AURA_REFRESH 9250592 29998 9250593 55011"
)

local warnTeleportSoon			= mod:NewAnnounce("WarningTeleportSoon", 2, 46573)
local warnTeleportNow			= mod:NewAnnounce("WarningTeleportNow", 3, 46573)
local warnPlagueCloudEnd		= mod:NewEndAnnounce(30122, 1)

local timerTeleport				= mod:NewTimer(90, "TimerTeleport", 46573, nil, nil, 6)
local timerPlagueCloud			= mod:NewBuffActiveTimer(45, 30122, nil, nil, nil, 6)

local timerTeleportTunnel		= mod:NewNextTimer(10, 9250691, "Teleport Tunnel", nil, nil, 3)
timerTeleportTunnel.icon = "Interface\\Icons\\Spell_Arcane_TeleportUnderCity"   -- spell_arcane_portalundercity

local timerDecrepitFever		= mod:NewNextTimer(20, 9250592, "Decrepit Fever", nil, nil, 5, nil, nil, true)

-- Opcja w³¹czenia/wy³¹czenia alertu na ekranie w menu bossa
mod:AddBoolOption("CustomTeleportAlert", true, "general", nil, nil, nil, 46573)

function mod:DancePhase()
	timerPlagueCloud:Start()
	warnTeleportSoon:Schedule(35, 10)
	warnPlagueCloudEnd:Schedule(45)
	self:ScheduleMethod(45, "BackInRoom", 88)
	self:SetStage(2)
	timerDecrepitFever:Cancel()

	-- Ukrywa alert po przeteleportowaniu bossa na podest
    DBM:HideCustomAlert()
end

function mod:BackInRoom(time)
	timerTeleport:Show(time)
	warnTeleportSoon:Schedule(time - 15, 15)
	warnTeleportNow:Schedule(time)
	self:ScheduleMethod(time, "DancePhase")
	self:SetStage(1)
	timerTeleportTunnel:Start()
	timerDecrepitFever:Start(12)

	-- Wyœwietla odliczanie na ekranie, gdy boss wraca do sali / startuje walka
    if self.Options.CustomTeleportAlert then
        DBM:ShowCustomAlert("Interface\\Icons\\Spell_Arcane_Blink", "Teleport", time)
    end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self:BackInRoom(90 - delay)
	timerTeleportTunnel:Start(20)
	timerDecrepitFever:Start(12)
end

function mod:OnCombatEnd(wipe)
    DBM:HideCustomAlert()
end

function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(9250592, 29998, 9250593, 55011) and self:AntiSpam(5, "DecrepitFever") then
        timerDecrepitFever:Start()
    end
end

mod.SPELL_AURA_REFRESH = mod.SPELL_AURA_APPLIED


if RaidBossEmoteFrame then
    local originalOnEvent = RaidBossEmoteFrame:GetScript("OnEvent")
    RaidBossEmoteFrame:SetScript("OnEvent", function(self, event, msg, ...)
        if mod:IsInCombat() and msg:find("channel a spell") then
            return
        end
        
        if originalOnEvent then
            originalOnEvent(self, event, msg, ...)
        end
    end)
end