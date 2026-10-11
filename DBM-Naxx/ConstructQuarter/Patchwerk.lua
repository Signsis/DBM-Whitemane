local mod	= DBM:NewMod("Patchwerk", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20190417005949")
mod:SetCreatureID(16028)

mod:RegisterCombat("combat_yell", L.yell1, L.yell2)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 28131",
	"SPELL_DAMAGE 28308 59192",
	"SPELL_MISSED 28308 59192"
)

local enrageTimer	= mod:NewBerserkTimer(300)
local warnFrenzy = mod:NewSpellAnnounce(28131, 3)
local timerAchieve	= mod:NewAchievementTimer(180, 1857)

mod:AddBoolOption("WarningHateful", false, "announce", nil, nil, nil, 28308)

local function announceStrike(target, damage)
	SendChatMessage(L.HatefulStrike:format(target, damage), "RAID")
end

function mod:OnCombatStart(delay)
	if self:IsDifficulty("normal25") then
		enrageTimer:Start(360-delay)
	else
		enrageTimer:Start(300-delay)
	end
	timerAchieve:Start(-delay)
end

function mod:SPELL_DAMAGE(_, _, _, _, destName, _, spellId, _, _, amount)
	if (spellId == 28308 or spellId == 59192) and self.Options.WarningHateful and DBM:GetRaidRank() >= 1 then
		announceStrike(destName, amount or 0)
	end
end

function mod:SPELL_MISSED(_, _, _, _, destName, _, spellId, _, _, missType)
	if (spellId == 28308 or spellId == 59192) and self.Options.WarningHateful and DBM:GetRaidRank() >= 1 then
		announceStrike(destName, getglobal("ACTION_SPELL_MISSED_"..(missType)) or "")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28131) then -- To jest na Frenzy
		warnFrenzy:Show()
		-- specWarnEnrage:Play("defensive")
	end
end

