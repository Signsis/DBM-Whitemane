local mod        = DBM:NewMod("Noth", "DBM-Naxx", 3)
local L        = mod:GetLocalizedStrings()

local GetSpellInfo = GetSpellInfo

mod:SetRevision("20221027184343")
mod:SetCreatureID(15954)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEventsInCombat(
    "SPELL_CAST_SUCCESS 29213 54835 9250590 9250591",
    "SPELL_AURA_APPLIED 29208 29209 29210 29211 29213 54835 9250590 9250591 9250690 9250689",
    "SPELL_CAST_START 54890 54891",
    "COMBAT_LOG_EVENT_UNFILTERED",
    "CHAT_MSG_RAID_BOSS_EMOTE"
)

local emote_Teleport = "%s teleports to the balcony above!"
local emote_Return = "%s teleports back into the battle!"

local warnTeleportNow        = mod:NewAnnounce("WarningTeleportNow", 3, 46573)
local warnTeleportSoon    = mod:NewAnnounce("WarningTeleportSoon", 1, 46573)
local warnCurse       = mod:NewTargetNoFilterAnnounce(29213, 2)

local warnBlinkSoon        = mod:NewSoonAnnounce(29208, 1)
local warnBlink            = mod:NewSpellAnnounce(29208, 3)

local specWarnAdds        = mod:NewSpecialWarningAdds(29212, "-Healer", nil, nil, 1, 2)
local specWarnExplosion    = mod:NewSpecialWarningInterrupt(54891)
local specWarnDecurse    = mod:NewSpecialWarningDispel(29213, "RemoveCurse", nil, nil, 1, 2)

local timerTeleport        = mod:NewTimer(80, "TimerTeleport", 46573, nil, nil, 6)
local timerTeleportBack    = mod:NewTimer(70, "TimerTeleportBack", 46573, nil, nil, 6)
local timerCurseCD        = mod:NewCDTimer(25, 29213, "Curse of the Plaguebringer", nil, nil, 5, nil, DBM_COMMON_L.CURSE_ICON, true)
local timerAddsCD        = mod:NewAddsTimer(25, 29212, nil, "-Healer", nil, nil, nil ,nil, true)
local timerBlink        = mod:NewNextTimer(30, 29208)

local specWarnGTFO = mod:NewSpecialWarningGTFO(9250690, nil, nil, nil, 1, 8)
specWarnGTFO.text = "|cff00ff00Plague Residue - move away|r"


function mod:OnCombatStart(delay)
    timerAddsCD:Start(-delay)
    timerCurseCD:Start(15)
    if self:IsDifficulty("normal25") or self:IsDifficulty("heroic25") then
        timerBlink:Start(26-delay)
        warnBlinkSoon:Schedule(23-delay)
    end
    timerTeleport:Start(-delay)
    warnTeleportSoon:Schedule(70-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(29213, 54835, 9250590, 9250591) then -- Curse of the Plaguebringer
        timerCurseCD:Start()
        if self.Options.SpecWarn29213dispel and UnitPowerType("player") ==0 then
            specWarnDecurse:Show("raid")
            specWarnDecurse:Play("helpdispel")
        end
    end
end

function mod:SPELL_AURA_APPLIED(args)
    if (self:IsDifficulty("normal25") or self:IsDifficulty("heroic25")) and args:IsSpellID(29208, 29209, 29210, 29211) then -- Blink
        warnBlink:Show()
        timerBlink:Start()
        warnBlinkSoon:Schedule(27)
    elseif args:IsSpellID(29213, 54835, 9250590, 9250591) then
        warnCurse:CombinedShow(0.3, args.destName)
	elseif args:IsSpellID(9250690, 9250689) and args:IsPlayer() then
        specWarnGTFO:Show(args.spellName)
        specWarnGTFO:Play("watchfeet")
    end
end

function mod:SPELL_CAST_START(args)
    if args:IsSpellID(54890, 54891) and self:AntiSpam(1, "ArcaneExplosion") then -- Arcane Explosion
        specWarnExplosion:Show(args.sourceName)
    end
end

-- bezpoœrednie przechwytywanie zdarzeñ combat logu (omija wewnêtrzne filtry DBM)
function mod:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
    if (event == "SPELL_PERIODIC_DAMAGE" or event == "SPELL_PERIODIC_MISSED" or event == "SPELL_DAMAGE") and (spellId == 9250690 or spellId == 9250689) then
        if destGUID == UnitGUID("player") then
				specWarnGTFO:Show(spellName)
				specWarnGTFO:Play("watchfeet")
        end
    end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
    if msg == emote_Teleport or msg:find(emote_Teleport) then
        self:SendSync("Teleport")
    elseif msg == emote_Return or msg:find(emote_Return) then
        self:SendSync("Return")
    elseif msg == L.Adds or msg:find(L.Adds) then
        self:SendSync("Adds")
    elseif msg == L.AddsTwo or msg:find(L.AddsTwo) then
        self:SendSync("AddsTwo")
    end
end

function mod:OnSync(msg)
    if not self:IsInCombat() then return end
    if msg == "Teleport" then
        timerCurseCD:Stop()
        timerAddsCD:Start(4)
        timerBlink:Stop()
        warnBlinkSoon:Cancel()
        timerTeleportBack:Start()
        warnTeleportSoon:Schedule(70 - 10)
        warnTeleportNow:Show()
    elseif msg == "Return" then
        warnTeleportNow:Show()
        timerAddsCD:Start()
        timerCurseCD:Start(15)
        if self:IsDifficulty("normal25") then
            timerBlink:Start(26)
            warnBlinkSoon:Schedule(23)
        end
        timerTeleport:Start()
        warnTeleportSoon:Schedule(70)
    elseif msg == "Adds" then
        specWarnAdds:Show()
        specWarnAdds:Play("killmob")        
        timerAddsCD:Start()
    elseif msg == "AddsTwo" then
        specWarnAdds:Show()
        specWarnAdds:Play("killmob")
        timerAddsCD:Start()
    end
end

if RaidBossEmoteFrame then
    local originalOnEvent = RaidBossEmoteFrame:GetScript("OnEvent")
    RaidBossEmoteFrame:SetScript("OnEvent", function(self, event, msg, ...)
        if mod:IsInCombat() and msg and (msg:find("blinks away!") or msg:find("teleports to the balcony") or msg:find("back into the battle")) then
            return
        end
        
        if originalOnEvent then
            originalOnEvent(self, event, msg, ...)
        end
    end)
end