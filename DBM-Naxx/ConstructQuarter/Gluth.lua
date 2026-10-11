local mod    = DBM:NewMod("Gluth", "DBM-Naxx", 2)
local L      = mod:GetLocalizedStrings()

mod:SetRevision("20260917000000")
mod:SetCreatureID(15932)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
    "SPELL_AURA_APPLIED 28371 54427",
    "SPELL_AURA_REMOVED 28371 54427",
    "SPELL_CAST_SUCCESS 28375 9250704 28374 54426", -- poprawne ID Decimate (28374, 54426)
    "UNIT_DIED"
)

local warnEnrageSoon    = mod:NewPreWarnAnnounce(54427, 5, 3)
local warnEnrage        = mod:NewTargetNoFilterAnnounce(54427, 3, nil , "Healer|Tank|RemoveEnrage", 2)
local warnDecimateSoon  = mod:NewSoonAnnounce(28374, 2)
warnDecimateSoon.text   = "|cffffd200Decimate soon (|cff0080ff%s|cffffd200)|r"

--local warnDecimateNow   = mod:NewAnnounce("warnDecimateNow", 3, 28374)
--warnDecimateNow.text    = "|cffffd200Decimate (|cff0080ff%s|cffffd200)|r"

local warnDecimateNow = mod:NewSpellAnnounce(28374, 3)
warnDecimateNow.text   = "|cffffd200Decimate (|cff0080ff%s|cffffd200)|r"

local warnRoar          = mod:NewAnnounce("warnRoar", 2, 9250704)
warnRoar.text           = "|cff0080ffTerrifying Roar|r"

local specWarnEnrage    = mod:NewSpecialWarningDispel(54427, "RemoveEnrage", nil, nil, 1, 6)

local timerEnrage       = mod:NewBuffActiveTimer(8, 54427, nil, nil, nil, 5, nil, DBM_COMMON_L.ENRAGE_ICON)
local timerEnrageCD     = mod:NewCDTimer(30, 54427, "Enrage", nil, nil, 5, nil, nil, true)
local timerDecimate     = mod:NewCDTimer(105, 28374, nil, nil, nil, 2, nil, nil, true)
local enrageTimer       = mod:NewBerserkTimer(360)
local timerRoarCD       = mod:NewCDTimer(20, 9250704, "Terrifying Roar", nil, nil, 6, nil, nil, true)

-- Opcje w menu Glutha (zak³adka Decimate)
mod:AddBoolOption("CustomDecimateCountdown", true, "announce", nil, nil, nil, 28374)
mod:AddBoolOption("CustomDecimateSound", true, "announce", nil, nil, nil, 28374)

L.CustomDecimateCountdown = "Poka¿ specjalny licznik odliczania (Signsis)"
L.CustomDecimateSound     = "Odtwarzaj dŸwiêk odliczania Signsis (5..1)"

local decimateCount = 0

local function StartRoarTimer(time)
    local timer = timerRoarCD:Start(time)
    if timer then
        timer:SetColor({r = 0, g = 0.5, b = 1})
    end
end

local function StartDecimateTimer(time, count)
    local timer = timerDecimate:Start(time)
    if timer then
        timer:SetText("Decimate (|cff0080ff" .. count .. "|r)")
    end
end

function mod:OnCombatStart(delay)
    decimateCount = 1
    enrageTimer:Start(360 - delay)
    timerEnrageCD:Start(30 - delay)
    warnEnrageSoon:Schedule(25 - delay)
    
    StartDecimateTimer(105 - delay, decimateCount)
    warnDecimateSoon:Schedule(95 - delay, decimateCount)

    -- Wywo³anie w³asnego odliczania na start walki
    if self.Options.CustomDecimateCountdown then
        DBM:ShowCustomAlert(
            "Interface\\Icons\\Spell_Nature_Purge",
            "Decimate",
            105 - delay,
            false,
            self.Options.CustomDecimateSound
        )
    end

    --if not (self:IsDifficulty("normal10") or self:IsDifficulty("normal25")) then
     --   StartRoarTimer(20 - delay)
    --end
end

function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(28371, 54427) then
        if self.Options.SpecWarn54427dispel then
            local class = self:UnitClass()
            if class == "HUNTER" or class == "ROGUE" then
                specWarnEnrage:Play("dispelboss")
            else
                specWarnEnrage:Play("enrage")
            end
            specWarnEnrage:Show(args.destName)
        else
            warnEnrage:Show(args.destName)
        end
        timerEnrage:Start()
        timerEnrageCD:Start()
        warnEnrageSoon:Schedule(25)
    end
end

function mod:SPELL_AURA_REMOVED(args)
    if args:IsSpellID(28371, 54427) then
        timerEnrage:Stop()
    end
end

function mod:SPELL_CAST_SUCCESS(args)
    if (args.spellId == 28374 or args.spellId == 54426 or args.spellId == 28375) and self:AntiSpam(20) then
        warnDecimateNow:Show(decimateCount)
        decimateCount = decimateCount + 1
        warnDecimateSoon:Schedule(95, decimateCount)
        StartDecimateTimer(105, decimateCount)

        -- Odliczanie po rzuceniu Decimate
        if self.Options.CustomDecimateCountdown then
            DBM:ShowCustomAlert(
                "Interface\\Icons\\Spell_Nature_Purge",
                "Decimate",
                105,
                false,
                self.Options.CustomDecimateSound
            )
        end
    elseif args.spellId == 9250704 then
        if self:IsDifficulty("heroic10") or self:IsDifficulty("heroic25") then
            warnRoar:Show()
            StartRoarTimer(20)
        end
    end
end

function mod:UNIT_DIED(args)
    local cid = self:GetCIDFromGUID(args.destGUID)
    if cid == 15932 then
        DBM:HideCustomAlert()
    end
end

function mod:OnCombatEnd()
    DBM:HideCustomAlert()
end

if RaidBossEmoteFrame then
    local originalOnEvent = RaidBossEmoteFrame:GetScript("OnEvent")
    RaidBossEmoteFrame:SetScript("OnEvent", function(self, event, msg, ...)
        if mod:IsInCombat() and msg == "Gluth decimates all nearby flesh!" then
            return
        end
        
        if originalOnEvent then
            originalOnEvent(self, event, msg, ...)
        end
    end)
end
