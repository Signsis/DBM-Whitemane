local mod    = DBM:NewMod("Loatheb", "DBM-Naxx", 3)
local L      = mod:GetLocalizedStrings()

mod:SetRevision("20260918000000")
mod:SetCreatureID(16011)

mod:RegisterCombat("combat")

-- POPRAWKA 1: Czyste zdarzenie SPELL_AURA_APPLIED bez do³¹czania spellId w stringu
mod:RegisterEventsInCombat(
    "SPELL_CAST_SUCCESS 29204 55052 55593",
    "SPELL_AURA_APPLIED 9250692",
	"SPELL_AURA_REMOVED 9250692",
    "SPELL_DAMAGE",
    "SPELL_SUMMON 29234",
    "SWING_DAMAGE",
    "UNIT_DIED"
)

local warnSporeNow    = mod:NewCountAnnounce(32329, 2, "Interface\\AddOns\\DBM-VPVEM\\Icons\\LoathebSporeSignsis")
local warnDoomNow     = mod:NewSpellAnnounce(29204, 3)
local warnHealSoon    = mod:NewAnnounce("WarningHealSoon", 4, 48071, nil, nil, nil, 55593)
local warnHealNow     = mod:NewAnnounce("WarningHealNow", 1, 48071, false, nil, nil, 55593)

local timerSpore    = mod:NewNextTimer(15, 32329, "Itchy Spores", nil, nil, 5, "Interface\\AddOns\\DBM-VPVEM\\Icons\\LoathebSporeSignsis", DBM_COMMON_L.DAMAGE_ICON)
local timerDoom     = mod:NewNextTimer(20, 29204, nil, nil, nil, 2)
local timerAura     = mod:NewBuffActiveTimer(17, 55593, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)
local timerwVolatileSpores     = mod:NewNextTimer(15, 9250692, "Volatile Spores", nil, nil, 3, nil ,nil, true)

-- Tworzymy powiadomienie dla celu
local warnVolatileSpores       = mod:NewTargetNoFilterAnnounce(9250692, 2)

-- Opcje w menu Loatheba
mod:AddBoolOption("SporeDamageAlert", false)
mod:AddBoolOption("CustomSporeCountdown", true, "announce", nil, nil, nil, 32329)
mod:AddBoolOption("CustomSporeSound", true, "announce", nil, nil, nil, 32329)

L.CustomSporeCountdown = "Poka¿ specjalny licznik odliczania (Signsis)"
L.CustomSporeSound     = "Odtwarzaj dŸwiêk odliczania Signsis (5..1)"

mod.vb.doomCounter  = 0
mod.vb.sporeTimer   = 15
mod.vb.sporeCounter = 0

local specWarnVolatileSpores = mod:NewSpecialWarningYou(9250692, nil, nil, nil, 1, 2)
mod:AddBoolOption("YellVolatileSporesCountdown", true, "announce", nil, nil, nil, 9250692)


local function StartSporeTimer(self, time, nextCount)
    local timer = timerSpore:Start(time, nextCount)
    if timer then
        timer:SetText("Itchy Spores (|cff00ffff" .. nextCount .. "|r)")
        timer:SetColor({r = 1, g = 0.8, b = 0}, {r = 1, g = 0.8, b = 0})
    end

    -- Wywo³anie w³asnego odliczania
    if self.Options.CustomSporeCountdown then
        DBM:ShowCustomAlert(
            "Interface\\AddOns\\DBM-VPVEM\\Icons\\LoathebSporeSignsis",
            "Itchy Spores",
            time,
            false,
            self.Options.CustomSporeSound
        )
    end
end

function mod:OnCombatStart(delay)
    self.vb.doomCounter = 0
    self.vb.sporeCounter = 0
	if self:IsDifficulty("heroic10") or self:IsDifficulty("heroic25") then
		timerwVolatileSpores:Start()
	end
    if self:IsDifficulty("normal10") or self:IsDifficulty("normal25") then
        self.vb.sporeTimer = 15
        timerDoom:Start(120 - delay, 1)
    else
        self.vb.sporeTimer = 15
        timerDoom:Start(20 - delay, 1)
    end
    
    StartSporeTimer(self, 18 - delay, 1)
end

function mod:SPELL_SUMMON(args)
    if args.spellId == 29234 then -- Summon Spore
        self.vb.sporeCounter = self.vb.sporeCounter + 1
        warnSporeNow:Show("|cff00ffff" .. self.vb.sporeCounter .. "|r")

        local nextCount = self.vb.sporeCounter + 1
        if self:IsDifficulty("normal10") or self:IsDifficulty("heroic10") then
            StartSporeTimer(self, 36, nextCount)
        else
            StartSporeTimer(self, self.vb.sporeTimer, nextCount)
        end
    end
end

function mod:SPELL_CAST_SUCCESS(args)
    local spellId = args.spellId
    if args:IsSpellID(29204, 55052) then  -- Inevitable Doom
        self.vb.doomCounter = self.vb.doomCounter + 1
        warnDoomNow:Show(self.vb.doomCounter)
        if self:IsDifficulty("normal10") or self:IsDifficulty("heroic10") then
            timerDoom:Start(30, self.vb.doomCounter + 1)
        else
            timerDoom:Start(20, self.vb.doomCounter + 1)
        end
    elseif spellId == 55593 then
        timerAura:Start()
        warnHealSoon:Schedule(14)
        warnHealNow:Schedule(17)
    end
end

function mod:SPELL_DAMAGE(_, sourceName, _, _, destName, _, spellId, _, _, amount)
    if self.Options.SporeDamageAlert and destName == "Spore" and spellId ~= 62124 and self:IsInCombat() then
        SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "RAID_WARNING")
        SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "WHISPER", nil, sourceName)
    end
end

function mod:SWING_DAMAGE(_, sourceName, _, _, destName, _, _, _, _, amount)
    if self.Options.SporeDamageAlert and destName == "Spore" and self:IsInCombat() then
        SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "RAID_WARNING")
        SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "WHISPER", nil, sourceName)
    end
end

function mod:UNIT_DIED(args)
    local cid = self:GetCIDFromGUID(args.destGUID)
    if cid == 16011 then
        warnHealSoon:Cancel()
        warnHealNow:Cancel()
        DBM:HideCustomAlert()
    end
end

function mod:OnCombatEnd()
    DBM:HideCustomAlert()
end

function mod:SPELL_AURA_APPLIED(args)
    if args.spellId == 9250692 then
        warnVolatileSpores:CombinedShow(0.3, args.destName)
        timerwVolatileSpores:Start()
        if args:IsPlayer() then
            specWarnVolatileSpores:Show()
            specWarnVolatileSpores:Play("targetyou")

            -- odliczanie odpali siê tylko jeœli opcja w DBM jest w³¹czona
            if self.Options.YellVolatileSporesCountdown then
                --SendChatMessage("Volatile Spores on me", "SAY")
				SendChatMessage("Volatile Spores on " .. args.destName, "SAY")

				self:Schedule(3, function() SendChatMessage("7", "SAY") end)
				self:Schedule(4, function() SendChatMessage("6", "SAY") end)
                self:Schedule(5, function() SendChatMessage("5", "SAY") end)
                self:Schedule(6, function() SendChatMessage("4", "SAY") end)
                self:Schedule(7, function() SendChatMessage("3", "SAY") end)
                self:Schedule(8, function() SendChatMessage("2", "SAY") end)
                self:Schedule(9, function() SendChatMessage("1", "SAY") end)
                
            end
        end
    end
end

function mod:SPELL_AURA_REMOVED(args)
    if args:IsPlayer() and args.spellId == 9250692 then
		SendChatMessage("Clear", "SAY")
    end
end


if RaidBossEmoteFrame then
    local originalOnEvent = RaidBossEmoteFrame:GetScript("OnEvent")
    RaidBossEmoteFrame:SetScript("OnEvent", function(self, event, msg, ...)
        if mod:IsInCombat() and (msg == "A Purifying Mushroom has appeared!" or msg:find("The aura's power begins to wane!")) then
            return
        end
        
        if originalOnEvent then
            originalOnEvent(self, event, msg, ...)
        end
    end)
end
