local mod    = DBM:NewMod("Grobbulus", "DBM-Naxx", 2)
local L        = mod:GetLocalizedStrings()



local ml = DBM:GetModLocalization("Grobbulus")
ml:SetOptionLocalization({SpecWarnManySlimes="Show special warning when 3 or more Fallout Slimes are alive"})
ml:SetWarningLocalization({SpecWarnManySlimes="|TInterface\\Icons\\spell_nature_abolishmagic:12:12|t %d Slimes! %s |TInterface\\Icons\\spell_nature_abolishmagic:12:12|t"})

mod:SetRevision("20221016191326")
mod:SetCreatureID(15931)
mod:SetUsedIcons(1, 2, 3, 4)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
    "SPELL_AURA_APPLIED 28169",
    "SPELL_AURA_REMOVED 28169",
    "SPELL_SUMMON 28240",
    "SPELL_DAMAGE 54363 28241 9250640 9250641",
    "SPELL_CAST_SUCCESS 54367 28156 9250702 9250703",
    "CHAT_MSG_RAID_BOSS_EMOTE",
    "UNIT_DIED"
)

local emote_Spray = "Grobbulus sprays slime across the room!"

local warnInjection            = mod:NewTargetNoFilterAnnounce(28169, 2)
local warnVolatileBile            = mod:NewTargetNoFilterAnnounce(9250702, 2, "Interface\\Icons\\Spell_Fire_FelPyroblast")
warnVolatileBile.text = "|cffFFF700" .. (GetSpellInfo(9250702) or "Volatile Bile") .. " on|r %s"    --   "|cffd2ff1c" limonkowy kolor


local warnCloud                = mod:NewSpellAnnounce(28240, 2)
warnCloud.text = "|cff00ff00" .. (GetSpellInfo(28240) or "Poison Cloud") .. "|r"
local warnSlimeSprayNow        = mod:NewSpellAnnounce(54364, 4)

local specWarnInjection        = mod:NewSpecialWarningYou(28169, nil, nil, nil, 1, 2)
local specWarnCloud            = mod:NewSpecialWarningKeepMove(28240, "Tank", nil, nil, 1, 2)
local specWarnCloudGTFO        = mod:NewSpecialWarningGTFO(28240, "-Tank", nil, nil, 1, 2) 
specWarnCloudGTFO.text = "|cff00ff00Cloud damage - move away|r"
local specWarnManySlimes    = mod:NewSpecialWarning("SpecWarnManySlimes", nil, nil, nil, 1, 2)

local timerInjection        = mod:NewTargetTimer(10, 28169, nil, nil, nil, 3)
local timerCloud            = mod:NewNextTimer(15, 28240, "Poison Cloud", nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
timerCloud.keep = true
local VolatileBiletimer            = mod:NewNextTimer(15, 9250702, "Volatile Bile", nil, nil, 5, nil, nil, true)
VolatileBiletimer.icon = "Interface\\Icons\\Spell_Fire_FelPyroblast"
local timerSlimeSprayCD        = mod:NewCDTimer(20, 54364, "Slime Spray", nil, nil, 2, nil, nil, true)
local enrageTimer            = mod:NewBerserkTimer(480)

mod:AddSetIconOption("SetIconOnInjectionTarget", 28169, false, false, {1, 2, 3, 4})

local mutateIcons = {}
local slimesAlive = 0

mod:AddBoolOption("YellMutatingInjectionCountdown", true, "announce", nil, nil, nil, 28169)

-- Bezpieczna funkcja pobieraj¹ca nick w kolorze klasy gracza
local function GetClassColoredName(name)
    if not name or name == "" then return "" end
    
    -- 1. Próba pobrania koloru bezpoœrednio z DBM
    if DBM and type(DBM.GetColoredName) == "function" then
        local colored = DBM:GetColoredName(name)
        if colored and colored ~= name and colored:find("|c") then
            return colored
        end
    end
    
    -- 2. Pobranie klasy z jednostki lub listy rajdu
    local _, class = UnitClass(name)
    if not class and GetNumRaidMembers then
        for i = 1, GetNumRaidMembers() do
            local n, _, _, _, _, c = GetRaidRosterInfo(i)
            if n == name then class = c; break end
        end
    elseif not class and GetNumGroupMembers then
        for i = 1, GetNumGroupMembers() do
            local n, _, _, _, _, c = GetRaidRosterInfo(i)
            if n == name then class = c; break end
        end
    end
    
    -- 3. Na³o¿enie koloru z RAID_CLASS_COLORS
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return string.format("|cff%02x%02x%02x%s|r", (c.r or 1) * 255, (c.g or 1) * 255, (c.b or 1) * 255, name)
    end
    
    return name
end

-- Pasek timera - zawsze czysty tekst "Volatile Bile"
local function VolatileBiletimerbar(time)
    VolatileBiletimer:Stop()
    local timer = VolatileBiletimer:Start(time)
    if timer then
        timer:SetText("Volatile Bile")
        timer:SetColor({r = 1, g = 0.97, b = 0})    -- ({r = 0.82, g = 1, b = 0.11})
    end
end

local function addIcon(self)
    for i,j in ipairs(mutateIcons) do
        local icon = 0 + i
        self:SetIcon(j, icon)
    end
end

local function removeIcon(self, target)
    for i,j in ipairs(mutateIcons) do
        if j == target then
            table.remove(mutateIcons, i)
            self:SetIcon(target, 0)
        end
    end
    addIcon(self)
end

function mod:ManySlimes()
    if self:IsHealer() then
        specWarnManySlimes:Show(slimesAlive, "Heal hard!")
        specWarnManySlimes:Play("healall")
    else
        specWarnManySlimes:Show(slimesAlive, "Focus Slimes!")
        specWarnManySlimes:Play("killmob")
    end
end

function mod:OnCombatStart(delay)
    slimesAlive = 0
    table.wipe(mutateIcons)
    enrageTimer:Start(-delay)
    timerSlimeSprayCD:Start(10)
    timerCloud:Start(15)
    if self:IsDifficulty("heroic10") or self:IsDifficulty("heroic25") then
        VolatileBiletimerbar(10)
    end
end

function mod:OnCombatEnd()
    for _, j in ipairs(mutateIcons) do
        self:SetIcon(j, 0)
    end
end

function mod:YellMutating(text)
    SendChatMessage(text, "SAY")
end

function mod:SPELL_AURA_APPLIED(args)
    if args.spellId == 28169 then
        warnInjection:Show(args.destName)
        timerInjection:Start(args.destName)
        if args:IsPlayer() then
            specWarnInjection:Show()
            specWarnInjection:Play("runout")

            -- odliczanie odpali siê tylko jeœli opcja w DBM jest w³¹czona
            if self.Options.YellMutatingInjectionCountdown then
                self:UnscheduleMethod("YellMutating")

				SendChatMessage("Mutating Injection on " .. args.destName, "SAY")

				self:ScheduleMethod(3, "YellMutating", "7")
                self:ScheduleMethod(4, "YellMutating", "6")
                self:ScheduleMethod(5, "YellMutating", "5")
                self:ScheduleMethod(6, "YellMutating", "4")
                self:ScheduleMethod(7, "YellMutating", "3")
                self:ScheduleMethod(8, "YellMutating", "2")
                self:ScheduleMethod(9, "YellMutating", "1")
                self:ScheduleMethod(10, "YellMutating", "Clear")
            end
        end
        if self.Options.SetIconOnInjectionTarget then
            table.insert(mutateIcons, args.destName)
            addIcon(self)
        end
    end
end

function mod:SPELL_AURA_REMOVED(args)
    if args.spellId == 28169 then
        timerInjection:Cancel(args.destName)
        if self.Options.SetIconOnInjectionTarget then
            removeIcon(self, args.destName)
        end
        
        if args:IsPlayer() and self.Options.YellMutatingInjectionCountdown then
            self:UnscheduleMethod("YellMutating")
            SendChatMessage("Clear", "SAY")
        end
    end
end

function mod:SPELL_SUMMON(args)
    if args.spellId == 28240 and args:GetSrcCreatureID() == 15931 then
        warnCloud:Show()
        timerCloud:Start()
        if self.Options.SpecWarn28240keepmove and self:IsTanking("player", "boss1", nil, true) then
            specWarnCloud:Show()
            specWarnCloud:Play("moveboss")
        end
    end
end

function mod:SPELL_DAMAGE(_,_,_, destGUID, _,_,spellId)
    if (spellId == 54363 or spellId == 28241 or spellId == 9250640 or spellId == 9250641) and self.Options.SpecWarn28240gtfo and destGUID == UnitGUID("player") and self:AntiSpam(1, "Cloud") then
        specWarnCloudGTFO:Show("Cloud")
        specWarnCloudGTFO:Play("watchfeet")
    end
end

function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(54367, 28156) then
        slimesAlive = slimesAlive + 1
        if slimesAlive >= 3 and self.Options.SpecWarnManySlimes and self:AntiSpam(1, "Slime")then
            self:ScheduleMethod(0.2, "ManySlimes")
        end
    elseif args:IsSpellID(9250702, 9250703) then
        if self:IsDifficulty("heroic10") or self:IsDifficulty("heroic25") then
            -- Przekazujemy nick pokolorowany kolorem klasy
            warnVolatileBile:Show(GetClassColoredName(args.destName))
            VolatileBiletimerbar(15)
        end
    end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
    if msg == emote_Spray or msg:find(emote_Spray) then
        self:SendSync("Spray")
    end
end

function mod:UNIT_DIED(args)
    if self:GetCIDFromGUID(args.destGUID) == 16290 then
        slimesAlive = slimesAlive > 1 and slimesAlive - 1 or 0
        if slimesAlive < 3 then
            self:UnscheduleMethod("ManySlimes")
        end
    end
end

function mod:OnSync(msg)
    if msg == "Spray" then
        warnSlimeSprayNow:Show()
        if self:IsDifficulty("normal10") or self:IsDifficulty("normal25") then
            timerSlimeSprayCD:Start()
        else
            timerSlimeSprayCD:Start()
        end
    end
end


if RaidBossEmoteFrame then
    local originalOnEvent = RaidBossEmoteFrame:GetScript("OnEvent")
    RaidBossEmoteFrame:SetScript("OnEvent", function(self, event, msg, ...)
        if mod:IsInCombat() and (msg == "Grobbulus sprays slime across the room!" or msg:find("with a Volatile Bile!")) then
            return
        end
        
        if originalOnEvent then
            originalOnEvent(self, event, msg, ...)
        end
    end)
end
