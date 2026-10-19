local mod    = DBM:NewMod("Anub'Rekhan", "DBM-Naxx", 1)
local L      = mod:GetLocalizedStrings()

mod:SetRevision("20260918000000")
mod:SetCreatureID(15956)

mod:RegisterCombat("combat_yell", L.Pull1, L.Pull2)

mod:RegisterEventsInCombat(
    "SPELL_CAST_START 28785 54021 9250582 9250583 9250578 28783",
	"SPELL_CAST_SUCCESS 28783 56090 9250578 9250579",
    "SPELL_AURA_REMOVED 28785 54021 9250582 9250583",
    "SPELL_AURA_APPLIED 9250685 9250684",
	"COMBAT_LOG_EVENT_UNFILTERED"
)

local warningLocustSoon    = mod:NewSoonAnnounce(28785, 2)
local warningLocustFaded   = mod:NewFadesAnnounce(28785, 1)

-- Customowy Warning dla Impale
--local warnImpaleClassColor = mod:NewAnnounce("warnImpaleClassColor", 3, 28783)
--warnImpaleClassColor.text  = "|cffffe000Impale on|r %s"
local warnImpale    = mod:NewSpellAnnounce(9250578, 3)

local specialWarningLocust = mod:NewSpecialWarningSpell(28785, nil, nil, nil, 2, 2)
--local yellImpale           = mod:NewYell(28783, nil, false)

local timerLocustIn        = mod:NewCDTimer(60, 28785, "Locust Swarm", nil, nil, 2)
local timerLocustFade      = mod:NewBuffActiveTimer(16, 28785, nil, nil, nil, 2)
local timerImpale          = mod:NewCDTimer(20, 56090, "Impale", nil, nil, 3, nil, nil, true)
local specWarnGTFO         = mod:NewSpecialWarningGTFO(9250685, nil, nil, nil, 1, 8)

-- OPCJE W GUI BOSSA:
mod:AddBoolOption("CustomLocustAlert", true, "general", nil, nil, nil, 28785)
mod:AddBoolOption("LocustSound", true, "sound", nil, nil, nil, 28785)
mod:AddBoolOption("ArachnophobiaTimer", true, "timer", nil, nil, nil, "at1859")


function mod:OnCombatStart(delay)
    local initialCD = 60 - delay
    timerLocustIn:Start(60 - delay)
    local bar = timerLocustIn:Start(60)
    if bar then
        bar:SetColor({r = 0, g = 1, b = 0})
    end
    warningLocustSoon:Schedule(50 - delay)
    timerImpale:Start(11 - delay)

    if self.Options.CustomLocustAlert then
        DBM:ShowCustomAlert("Interface\\Icons\\Spell_Nature_InsectSwarm", "Locust Swarm", initialCD, nil, self.Options.LocustSound)
    end
end

function mod:OnCombatEnd(wipe)
    if not wipe and self.Options.ArachnophobiaTimer then
        DBT:CreateBar(1200, L.ArachnophobiaTimer, "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01")
    end
    DBM:HideCustomAlert()
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(28785, 54021, 9250582, 9250583) then  -- Locust Swarm
        specialWarningLocust:Show()
        specialWarningLocust:Play("aesoon")
        timerLocustIn:Stop()

        DBM:HideCustomAlert()
        
        if self:IsDifficulty("normal10") or self:IsDifficulty("heroic10") then
            timerLocustFade:Start(19)
            local bar = timerLocustFade:Start(18.99)
            if bar then
                bar:SetColor({r = 0, g = 1, b = 0})
            end
        else
            timerLocustFade:Start(23)
            local bar = timerLocustFade:Start(22.99)
            if bar then
                bar:SetColor({r = 0, g = 1, b = 0})
            end
        end
	elseif args:IsSpellID(9250578, 28783) then
		timerImpale:Start()
		warnImpale:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28783, 56090, 9250578, 9250579) then
		timerImpale:Start()
		warnImpale:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(9250685, 9250684) and args:IsPlayer() then
        specWarnGTFO:Show(args.spellName)
        specWarnGTFO:Play("watchfeet")
    end
end

function mod:SPELL_AURA_REMOVED(args)
    if args:IsSpellID(28785, 54021, 9250582, 9250583) and args.auraType == "BUFF" then
        warningLocustFaded:Show()

        local nextCD = 71
        if self:IsDifficulty("normal25") or self:IsDifficulty("heroic25") then
            warningLocustSoon:Schedule(57)
            
            timerLocustIn:Start(67)
            local bar = timerLocustIn:Start(66.99)
            if bar then
                bar:SetColor({r = 0, g = 1, b = 0})
            end
            nextCD = 67
        else
            warningLocustSoon:Schedule(61)
            
            timerLocustIn:Start(71)
            local bar = timerLocustIn:Start(70.99)
            if bar then
                bar:SetColor({r = 0, g = 1, b = 0})
            end
            nextCD = 71
        end

        if self.Options.CustomLocustAlert then
            DBM:ShowCustomAlert("Interface\\Icons\\Spell_Nature_InsectSwarm", "Locust Swarm", nextCD, nil, self.Options.LocustSound)
        end
    end
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
    if (event == "SPELL_PERIODIC_DAMAGE" or event == "SPELL_PERIODIC_MISSED" or event == "SPELL_DAMAGE") and (spellId == 9250685 or spellId == 9250684) then
        if destGUID == UnitGUID("player") then
				specWarnGTFO:Show(spellName)
				specWarnGTFO:Play("watchfeet")
        end
    end
end