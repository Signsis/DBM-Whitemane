local mod        = DBM:NewMod("Heigan", "DBM-Naxx", 3)
local L        = mod:GetLocalizedStrings()

mod:SetRevision("20190516165414")
mod:SetCreatureID(15936)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEventsInCombat(
    "SPELL_AURA_APPLIED 9250592 29998 9250593 55011",
    "SPELL_AURA_REFRESH 9250592 29998 9250593 55011"
)

local warnTeleportSoon            = mod:NewAnnounce("WarningTeleportSoon", 2, 46573)
local warnTeleportNow            = mod:NewAnnounce("WarningTeleportNow", 3, 46573)
local warnPlagueCloudEnd        = mod:NewEndAnnounce(30122, 1)

-- Customowe ostrze¿enie z kolorem klasy dla graczy zateleportowanych do tunelu
local warnTeleportClassColor    = mod:NewAnnounce("warnTeleportClassColor", 3, 9250691)
warnTeleportClassColor.text     = "|cffffe000Teleported to tunnel:|r %s"
warnTeleportClassColor.icon = "Interface\\Icons\\Spell_Arcane_TeleportUnderCity"

local timerTeleport                = mod:NewTimer(90, "TimerTeleport", 46573, nil, nil, 6)
local timerPlagueCloud            = mod:NewBuffActiveTimer(45, 30122, nil, nil, nil, 6)

local timerTeleportTunnel        = mod:NewNextTimer(10, 9250691, "Teleport Tunnel", nil, nil, 3)
timerTeleportTunnel.icon = "Interface\\Icons\\Spell_Arcane_TeleportUnderCity"

local timerDecrepitFever        = mod:NewNextTimer(20, 9250592, "Decrepit Fever", nil, nil, 5, nil, nil, true)

-- Opcja w³¹czenia/wy³¹czenia alertu na ekranie w menu bossa
--mod:AddBoolOption("CustomTeleportAlert", true, "general", nil, nil, nil, 46573)

-- Tabela pamiêci pozycji dla skanera oraz tabela bufora celów
local lastPositions = {}
local teleportTargets = {}
local isCollectingTeleports = false

local function getColoredTargetText(target)
    if not target or target == "" then return "ffffffff", "Unknown" end

    for uId in DBM:GetGroupMembers() do
        if UnitName(uId) == target then
            local _, classFileName = UnitClass(uId)
            if classFileName and RAID_CLASS_COLORS[classFileName] then
                return RAID_CLASS_COLORS[classFileName].colorStr, target
            end
            break
        end
    end
    return "ffffffff", target
end

-- Funkcja wywo³ywana JEDNORAZOWO po zamkniêciu okna zbierania (1.5s)
function mod:ShowTeleportTargets()
    if #teleportTargets > 0 then
        local formattedTargets = table.concat(teleportTargets, ", ")
        warnTeleportClassColor:Show(formattedTargets)
        table.wipe(teleportTargets)
    end
    isCollectingTeleports = false
end

function mod:CheckPlayerPositions()
    if not self:IsInCombat() then return end

    SetMapToCurrentZone()

    for uId in DBM:GetGroupMembers() do
        if not UnitIsDeadOrGhost(uId) then
            local x, y = GetPlayerMapPosition(uId)

            if x and y and x > 0 and y > 0 then
                local last = lastPositions[uId]

                if last then
                    local dx = x - last.x
                    local dy = y - last.y
                    local dist = (dx * dx + dy * dy) ^ 0.5

                    -- Skok pozycji o ponad 15% mapy w ci¹gu 1s oznacza teleportacjê
                    if dist > 0.15 then
                        local pName = UnitName(uId)

                        if pName and self:AntiSpam(5, "TeleportTarget_" .. pName) then
                            local classHex, cleanName = getColoredTargetText(pName)
                            local formattedName = "|c" .. classHex .. cleanName .. "|r"

                            -- Dodajemy sformatowany nick do zbiorczej listy
                            table.insert(teleportTargets, formattedName)

                            -- Jeœli to pierwsza osoba z fali, otwieramy 1.5-sekundowe okno zbierania reszty osób
                            if not isCollectingTeleports then
                                isCollectingTeleports = true
                                self:ScheduleMethod(1.5, "ShowTeleportTargets")
                            end
                        end
                    end
                end

                lastPositions[uId] = { x = x, y = y }
            end
        end
    end

    -- Skanowanie uruchamia siê co 1 sekundê
    self:Schedule(1, self.CheckPlayerPositions, self)
end

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
    --if self.Options.CustomTeleportAlert then
    --    DBM:ShowCustomAlert("Interface\\Icons\\Spell_Arcane_Blink", "Teleport", time)
    --end
end

function mod:OnCombatStart(delay)
    table.wipe(lastPositions)
    table.wipe(teleportTargets)
    isCollectingTeleports = false
    self:SetStage(1)
    self:BackInRoom(90 - delay)
    timerTeleportTunnel:Start(20)
    timerDecrepitFever:Start(12)

    -- Uruchomienie skanera pozycji 2 sekundy po starcie walki
    self:Schedule(2, self.CheckPlayerPositions, self)
end

function mod:OnCombatEnd(wipe)
    DBM:HideCustomAlert()
    isCollectingTeleports = false
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