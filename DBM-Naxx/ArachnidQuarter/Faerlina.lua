local mod    = DBM:NewMod("Faerlina", "DBM-Naxx", 1)
local L        = mod:GetLocalizedStrings()

mod:SetRevision("20221016190115")
mod:SetCreatureID(15953)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEventsInCombat(
    "SPELL_AURA_APPLIED 28798 54100 28732 54097 28794 54099 9250587 9250586",
    "SPELL_CAST_SUCCESS 28796 54098 9250584 9250585",
    "UNIT_DIED"
)

local warnEmbraceActive        = mod:NewSpellAnnounce(28732, 1)
local warnEmbraceExpire        = mod:NewAnnounce("WarningEmbraceExpire", 2, 28732, nil, nil, nil, 28732)
warnEmbraceExpire.text = "|cff33b5ffWidow's Embrace ends in 5|r"
local warnEmbraceExpired    = mod:NewFadesAnnounce(28732, 3)
warnEmbraceExpired.text = "|cff33b5ffWidow's Embrace faded|r"
local warnEnrageSoon        = mod:NewSoonAnnounce(28131, 3)
warnEnrageSoon.text = "|cffffe000Frenzy soon|r"
local warnEnrageNow            = mod:NewSpellAnnounce(28131, 4)

local specWarnEnrage        = mod:NewSpecialWarningDefensive(28131, nil, nil, nil, 3, 2)
local specWarnGTFO            = mod:NewSpecialWarningGTFO(28794, nil, nil, nil, 1, 8)

local timerEmbrace            = mod:NewBuffActiveTimer(30, 28732, nil, nil, nil, 5)
local timerEnrage            = mod:NewCDTimer(60, 28131, nil, nil, nil, 6, nil, nil, true)
local timerPoisonVolleyCD    = mod:NewCDTimer(14, 54098, nil, nil, nil, 5)

-- OPCJE W MENU DBM BOSSA
mod:AddBoolOption("CustomFrenzyAlert", true, "announce", nil, nil, nil, 28131)
mod:AddBoolOption("CustomFrenzySound", true, "announce", nil, nil, nil, 28131)

mod.vb.enraged = false
local iconFrenzy = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy"

local function StartEmbraceTimer(time)
    local timer = timerEmbrace:Start(time)
    if timer then
        timer:SetColor({r = 0, g = 0.5, b = 1})
    end
end

local function StartEnrageTimer(duration)
    local timer = timerEnrage:Start(duration)
    if timer then
        timer:SetColor({r = 1, g = 0.88, b = 0}, {r = 1, g = 0.88, b = 0})
    end
end

function mod:OnCombatStart(delay)
    StartEnrageTimer()
    warnEnrageSoon:Schedule(55 - delay)
    timerPoisonVolleyCD:Start(13.6 - delay)
    self.vb.enraged = false

    if self.Options.CustomFrenzyAlert then
        DBM:ShowCustomAlert(iconFrenzy, "Frenzy", 60 - delay, true, self.Options.CustomFrenzySound)
    end
end

function mod:OnCombatEnd()
    DBM:HideCustomAlert()
end

function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(28798, 54100) then -- Frenzy
        self.vb.enraged = true
        DBM:HideCustomAlert()
        
        if self:IsTanking("player", "boss1", nil, true) then
            specWarnEnrage:Show()
            specWarnEnrage:Play("defensive")
        else
            warnEnrageNow:Show()
        end
    elseif args:IsSpellID(28732, 54097) and args:GetDestCreatureID() == 15953 and self:AntiSpam(5, 2) then -- Widow's Embrace
        warnEmbraceExpire:Cancel()
        warnEmbraceExpired:Cancel()
        warnEnrageSoon:Cancel()
        timerPoisonVolleyCD:Cancel()
        timerPoisonVolleyCD:Schedule(30, 10)
        timerEnrage:Stop()
        
        -- Okreœlenie czasu na podstawie tego czy boss mia³ Frenzy
        local frenzyDuration = 35
        if self.vb.enraged then
            StartEnrageTimer()
            warnEnrageSoon:Schedule(55)
            frenzyDuration = 60
        else
            StartEnrageTimer(35)
            warnEnrageSoon:Schedule(30)
            frenzyDuration = 35
        end
        
        StartEmbraceTimer()
        warnEmbraceActive:Show()
        warnEmbraceExpire:Schedule(25)
        warnEmbraceExpired:Schedule(30)
        self.vb.enraged = false
        
        if self.Options.CustomFrenzyAlert then
            DBM:ShowCustomAlert(iconFrenzy, "Frenzy", frenzyDuration, true, self.Options.CustomFrenzySound)
        end
    elseif args:IsSpellID(28794, 54099, 9250587, 9250586) and args:IsPlayer() then
        specWarnGTFO:Show(args.spellName)
        specWarnGTFO:Play("watchfeet")
    end
end

function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(28796, 54098, 9250584, 9250585) then
        timerPoisonVolleyCD:Start()
    end
end

function mod:UNIT_DIED(args)
    local cid = self:GetCIDFromGUID(args.destGUID)
    if cid == 15953 then
        warnEnrageSoon:Cancel()
        warnEmbraceExpire:Cancel()
        warnEmbraceExpired:Cancel()
        timerPoisonVolleyCD:Cancel()
        DBM:HideCustomAlert()
    end
end