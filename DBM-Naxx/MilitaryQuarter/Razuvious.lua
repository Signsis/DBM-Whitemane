local mod	= DBM:NewMod("Razuvious", "DBM-Naxx", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221016184543")
mod:SetCreatureID(16061)

mod:RegisterCombat("combat_yell", L.Yell1, L.Yell2, L.Yell3, L.Yell4)

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 55543 29107 29060 29061 9250696 9250606 9250607",    --   Nowy casting shout  > 9250696
	"SPELL_AURA_APPLIED 605 9250608",
	"SPELL_AURA_REMOVED 9250608",
	"UNIT_DIED"
)

local warnShoutNow = mod:NewSpellAnnounce(29107, 3, "Interface\\Icons\\Spell_Shadow_DeathScream")
warnShoutNow.text = "|cffff3333Disrupting Shout|r"
local warnShoutNowNEW = mod:NewSpellAnnounce(9250696, 3, "Interface\\Icons\\Ability_Warrior_RallyingCry")    -- local warnShoutNowNEW = mod:NewAnnounce("warnShoutNowNEW", 3, "Interface\\Icons\\Ability_Warrior_RallyingCry")
warnShoutNowNEW.text = "|cff1a99ffDisciplinary Shout|r"
--local warnShoutSoon		= mod:NewSoonAnnounce(29107, 3)
local warnShieldWall	= mod:NewAnnounce("WarningShieldWallSoon", 3, 29061, nil, nil, nil, 29061)

local warnJaggedKnife = mod:NewTargetNoFilterAnnounce(9250608, 4) -- "Interface\\Icons\\INV_Weapon_ShortBlade_12"
mod:AddBoolOption("InfoFrame", true, "option") -- Adds toggle in DBM options menu
-- Table to keep track of players with active debuffs
local activeJaggedKnifeTargets = {}
local timerJaggedKnife   = mod:NewTargetTimer(4, 9250608)

local timerShout		= mod:NewNextTimer(15, 29107, "Disrupting Shout", nil, nil, 2, "Interface\\Icons\\Spell_Shadow_DeathScream",nil ,true) -- Whitemane PTR buff notes say it should be 12, but was consistently 15s in the vod
--local timerShoutCasting		= mod:NewNextTimer(15, 9250696, nil, nil, nil, 2, "Interface\\Icons\\Spell_Shadow_DeathScream")
local timerShoutCasting = mod:NewNextTimer(15, 9250696, "Disciplinary Shout", nil, nil, 1, nil ,nil, true)     --local timerShoutCasting = mod:NewTimer(15, "Disciplinary Shout", "Interface\\Icons\\Ability_Warrior_RallyingCry", nil, nil, 1)
timerShoutCasting.icon = "Interface\\Icons\\Ability_Warrior_RallyingCry"
local timerTaunt		= mod:NewCDTimer(20, 29060, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerShieldWall	= mod:NewCDTimer(20, 29061, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerMindControl	= mod:NewBuffActiveTimer(60, 605, nil, nil, nil, 6)

function mod:OnCombatStart()
    table.wipe(activeJaggedKnifeTargets)
        self:RegisterEvents(
            "SPELL_AURA_APPLIED",
            "SPELL_AURA_REMOVED"
        )
	if self:IsDifficulty("normal25") then
		timerShout:Start(15)       -- 15 musi byc na normal
		--warnShoutSoon:Schedule(10)
	elseif self:IsDifficulty("heroic25") then
		timerShout:Start(15)
		timerShoutCasting:Start(15)
	elseif self:IsDifficulty("normal10") then
		timerShout:Start(25)
	else
		timerShout:Start(25)
		timerShoutCasting:Start(15)
		--warnShoutSoon:Schedule(20)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
    local spellId = args.spellId

    -- 1. Standardowy Disrupting Shout
    if args:IsSpellID(55543, 29107, 9250606, 9250607) then
        if self:IsDifficulty("normal25") then
            timerShout:Start(15)     -- 15 musi byc na normal
			warnShoutNow:Show()
        elseif self:IsDifficulty("heroic10") then
			timerShout:Start(25)
			warnShoutNow:Show()
		elseif	self:IsDifficulty("normal10") then
			timerShout:Start(25)
			warnShoutNow:Show()
		else
            timerShout:Start(15)
			warnShoutNow:Show()
        end

    -- 2. Customowy Disciplinary Shout (niebieski bar)
    elseif spellId == 9250696 and self:AntiSpam(5, "DisciplinaryShout")then
        timerShoutCasting:Start(15)
		warnShoutNowNEW:Show()

    -- 3. Pozosta³e czary
    elseif spellId == 29060 then -- Taunt
        timerTaunt:Start(20, args.sourceGUID)
    elseif spellId == 29061 and self:AntiSpam(2, 1) then -- ShieldWall
        timerShieldWall:Start(20, args.sourceGUID)
        warnShieldWall:Schedule(15)
    end
end

local function updateInfoFrame()
    -- Set the title header of the movable table frame
    DBM.InfoFrame:SetHeader("Bleeding targets")

    -- Show entries inside the frame
    -- Format: ShowTable(table, sorted_by_value)
    DBM.InfoFrame:Show(5, "table", activeJaggedKnifeTargets)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 605 and args:IsSrcTypePlayer() then -- Mind Control
		timerMindControl:Start(nil, args.sourceName)
	end
    if args.spellId == 9250608 then
            -- Add player to the list (Value '1' or time remaining can be displayed)
            activeJaggedKnifeTargets[args.destName] = "Bleeding"

            -- DBM target warning
            --warnJaggedKnife:CombinedShow(0.3, args.destName)

            -- Open/update the movable InfoFrame
            if self.Options.InfoFrame then
                updateInfoFrame()
            end
            -- Optional: Chat message if YOU get the debuff
            if args:IsPlayer() then
                SendChatMessage("I have the Jagged Knife!", "SAY")
            end
    end
end

function mod:SPELL_AURA_REMOVED(args)
    if args.spellId == 9250608 then
        activeJaggedKnifeTargets[args.destName] = nil

        if self.Options.InfoFrame then
            if next(activeJaggedKnifeTargets) ~= nil then
                -- Updates table if players still have the debuff
                updateInfoFrame()
            else
                -- Hides the frame completely when 0 players have the debuff
                DBM.InfoFrame:Hide()
            end
        end
    end
end



function mod:UNIT_DIED(args)
	local guid = args.destGUID
	local cid = self:GetCIDFromGUID(guid)
	if cid == 16803 then--Deathknight Understudy
		timerTaunt:Stop(args.destGUID)
		timerShieldWall:Stop(args.destGUID)
	end
end
