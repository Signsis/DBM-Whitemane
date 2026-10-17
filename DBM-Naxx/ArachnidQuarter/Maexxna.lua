local mod    = DBM:NewMod("Maexxna", "DBM-Naxx", 1)
local L        = mod:GetLocalizedStrings()

mod:SetRevision("20220627034419")
mod:SetCreatureID(15952)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
    "SPELL_AURA_APPLIED 28622 29484 54125 9250574 9250573 9250572 9250571 54124 54123",
    "SPELL_CAST_SUCCESS 29484 54125 9250574 9250573",
    "CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnWebWrap        = mod:NewTargetNoFilterAnnounce(28622, 2)
local warnWebSpraySoon    = mod:NewSoonAnnounce(29484, 1)
local warnWebSprayNow    = mod:NewSpellAnnounce(29484, 3)
local warnSpidersSoon    = mod:NewAnnounce("WarningSpidersSoon", 2, 17332)
local warnSpidersNow    = mod:NewAnnounce("WarningSpidersNow", 4, 17332)
local warnFrenzy = mod:NewSpellAnnounce(54124, 3)

local specWarnWebWrap    = mod:NewSpecialWarningSwitch(28622, "RangedDps", nil, nil, 1, 2)
local yellWebWrap        = mod:NewYellMe(28622)

local timerWebSpray        = mod:NewNextTimer(40.2, 29484, nil, nil, nil, 2)
--local timerWebWrap        = mod:NewNextTimer(30, 28622, nil, "RangedDps|Healer", nil, 3)
local timerWebWrap		  = mod:NewNextTimer(30, 28622)
local timerSpider        = mod:NewTimer(40.2, "TimerSpider", 17332, nil, nil, 1)

mod:AddBoolOption("CustomWebSprayAlert", true, "general", nil, nil, nil, 29484)
mod:AddBoolOption("CustomWebSpraySound", true, "general", nil, nil, nil, 29484)
mod:AddBoolOption("CustomSpidersAlert", false, "announce")

function mod:OnCombatStart(delay)
    local sprayCD = 40.2 - delay
    local spiderCD = 30.1 - delay

    warnWebSpraySoon:Schedule(30.5 - delay)
    timerWebSpray:Start(sprayCD)
    timerWebWrap:Start(20 - delay)
    warnSpidersSoon:Schedule(25.1 - delay)
    timerSpider:Start(spiderCD)

    -- Na starcie walki Paj¹ki s¹ szybciej (30.1s) ni¿ Web Spray (40.2s)
    if self.Options.CustomSpidersAlert then
        DBM:ShowCustomAlert("Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01", "Spiderlings", spiderCD)
    elseif self.Options.CustomWebSprayAlert then
        DBM:ShowCustomAlert("Interface\\Icons\\Spell_Nature_Web", "Web Spray", sprayCD, nil, self.Options.CustomWebSpraySound)
    end
end

function mod:OnCombatEnd(wipe)
    if not wipe then
        if DBT:GetBar(L.ArachnophobiaTimer) then
            DBT:CancelBar(L.ArachnophobiaTimer)
        end
    end
    DBM:HideCustomAlert()
end

function mod:SPELL_AURA_APPLIED(args)
    if args.spellId == 28622 or args.spellId == 9250572 or args.spellId == 9250571 then
        warnWebWrap:CombinedShow(0.5, args.destName)
        if self:AntiSpam(5, 1) then
            specWarnWebWrap:Show()
            timerWebWrap:Start(40)
        end
        if args.destName == UnitName("player") then
            --yellWebWrap:Yell()
			SendChatMessage("Web Wrap on " .. args.destName, "SAY")
        elseif not DBM:UnitDebuff("player", args.spellName) and self:AntiSpam(5, 2) then
            specWarnWebWrap:Play("targetchange")
        end

    elseif args:IsSpellID(29484, 54125, 9250574, 9250573) and self:AntiSpam(8, 3) then
        warnWebSprayNow:Show()
        warnWebSpraySoon:Schedule(30.5)
        timerWebSpray:Start(40.2)

        -- Po rzuceniu Web Spray nastêpne w kolejnoœci s¹ Paj¹ki (za 30.1s)
        if self.Options.CustomSpidersAlert then
            DBM:ShowCustomAlert("Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01", "Spiderlings", 30.1)
        elseif self.Options.CustomWebSprayAlert then
            DBM:ShowCustomAlert("Interface\\Icons\\Spell_Nature_Web", "Web Spray", 40.2, nil, self.Options.CustomWebSpraySound)
        end

	elseif args:IsSpellID(54124, 54123) then -- To jest na Frenzy
		warnFrenzy:Show()
		-- specWarnEnrage:Play("defensive")
	end
end

mod.SPELL_CAST_SUCCESS = mod.SPELL_AURA_APPLIED

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
    if msg and (msg:find("Spiderlings") or msg:find("spiderlings")) then
        self:SendSync("Spiderlings")
    end
end

function mod:OnSync(event)
    if event == "Spiderlings" then
        warnSpidersNow:Show()
        warnSpidersSoon:Schedule(35)
        timerSpider:Start(40.2)

        -- Po wejœciu Paj¹ków nastêpny Web Spray jest ju¿ za 10.1s
        if self.Options.CustomWebSprayAlert then
            DBM:ShowCustomAlert("Interface\\Icons\\Spell_Nature_Web", "Web Spray", 10.1, nil, self.Options.CustomWebSpraySound)
        elseif self.Options.CustomSpidersAlert then
            DBM:ShowCustomAlert("Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01", "Spiderlings", 40.2)
        end
    end
end

if RaidBossEmoteFrame then
    local originalOnEvent = RaidBossEmoteFrame:GetScript("OnEvent")
    RaidBossEmoteFrame:SetScript("OnEvent", function(self, event, msg, ...)
        if mod:IsInCombat() and (msg == "Spiderlings appear on the web!" or msg:find("into a cocoon!") or msg:find("of web everywhere!")) then
            return
        end
        
        if originalOnEvent then
            originalOnEvent(self, event, msg, ...)
        end
    end)
end
