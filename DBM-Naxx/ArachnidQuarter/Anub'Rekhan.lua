local mod    = DBM:NewMod("Anub'Rekhan", "DBM-Naxx", 1)
local L      = mod:GetLocalizedStrings()

mod:SetRevision("20260918000000")
mod:SetCreatureID(15956)

mod:RegisterCombat("combat_yell", L.Pull1, L.Pull2)

mod:RegisterEventsInCombat(
    "SPELL_CAST_START 28783 56090 28785 54021 9250578 9250582 9250583 9250579",
    "SPELL_CAST_SUCCESS 56090 9250579",
    "SPELL_AURA_REMOVED 28785 54021 9250582 9250583",
    "SPELL_AURA_APPLIED 9250685 9250684"
)

local warningLocustSoon    = mod:NewSoonAnnounce(28785, 2)
local warningLocustFaded   = mod:NewFadesAnnounce(28785, 1)

-- Customowy Warning dla Impale, obs³u¿y formatowanie kolorami
local warnImpaleClassColor = mod:NewAnnounce("warnImpaleClassColor", 3, 28783)
warnImpaleClassColor.text  = "|cffffe000Impale on|r %s"

local specialWarningLocust = mod:NewSpecialWarningSpell(28785, nil, nil, nil, 2, 2)
local yellImpale           = mod:NewYell(28783, nil, false)

local timerLocustIn        = mod:NewCDTimer(60, 28785, "Locust Swarm", nil, nil, 2)
local timerLocustFade      = mod:NewBuffActiveTimer(16, 28785, nil, nil, nil, 2)
local timerImpale          = mod:NewCDTimer(20, 56090, "Impale", nil, nil, 3, nil, nil, true)
local specWarnGTFO         = mod:NewSpecialWarningGTFO(9250685, nil, nil, nil, 1, 8)

-- OPCJE W GUI BOSSA:
mod:AddBoolOption("CustomLocustAlert", true, "general", nil, nil, nil, 28785)
mod:AddBoolOption("LocustSound", true, "sound", nil, nil, nil, 28785)
mod:AddBoolOption("ArachnophobiaTimer", true, "timer", nil, nil, nil, "at1859")

-- Zmienna pomocnicza do zapobiegania spamowi dla Impale
local impaleTargets = {}

function mod:OnCombatStart(delay)
    table.wipe(impaleTargets)
    local initialCD = 60 - delay
    timerLocustIn:Start(60 - delay)
    local bar = timerLocustIn:Start(60)
    if bar then
        bar:SetColor({r = 0, g = 1, b = 0}) -- Zielony (RGB)
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
    if args:IsSpellID(28783, 56090, 9250578, 9250579) then  -- Impale
        timerImpale:Start()
        
        -- Algorytm pobierania celu i przypisania koloru klasy z WA
        local target = args.destName
        if not target or target == "" then
            target = UnitName("boss1target") or UnitName("targettarget") or "Unknown"
        end
        
        if self:AntiSpam(3, target) then -- unikanie spamu jeœli zdarzenie zdubluje target
            local classColorHex = "ffffffff" -- Domyœlnie bia³y
            
            if target and target ~= "Unknown" then
                local numRaid = GetNumRaidMembers()
                if numRaid > 0 then
                    for i = 1, numRaid do
                        local unit = "raid" .. i
                        if UnitName(unit) == target then
                            local _, classFileName = UnitClass(unit)
                            if classFileName and RAID_CLASS_COLORS[classFileName] then
                                classColorHex = RAID_CLASS_COLORS[classFileName].colorStr
                            end
                            break
                        end
                    end
                else
                    if target == UnitName("player") then
                        local _, classFileName = UnitClass("player")
                        if classFileName and RAID_CLASS_COLORS[classFileName] then
                            classColorHex = RAID_CLASS_COLORS[classFileName].colorStr
                        end
                    end
                end
            end
            
            -- Wyœwietlenie ostrze¿enia na ekranie DBM
            local formattedTarget = "|c" .. classColorHex .. target .. "|r"
            warnImpaleClassColor:Show(formattedTarget)

            -- Yell jeœli my jesteœmy celem
            if target == UnitName("player") then
                yellImpale:Yell()
            end
        end

    elseif args:IsSpellID(28785, 54021, 9250582, 9250583) then  -- Locust Swarm
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
    end
end

mod.SPELL_CAST_SUCCESS = mod.SPELL_CAST_START

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