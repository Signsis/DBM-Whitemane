local mod	= DBM:NewMod("Razuvious", "DBM-Naxx", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221016184543")
mod:SetCreatureID(16061)

mod:RegisterCombat("combat_yell", L.Yell1, L.Yell2, L.Yell3, L.Yell4)

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 55543 29107 29060 29061 9250696 9250606 9250607 9250609 55550 9250608",    --   Nowy casting shout  > 9250696
	"SPELL_AURA_APPLIED 605 9250609 48074 55550 9250608",
	"UNIT_DIED"
)

local warnShoutNow = mod:NewSpellAnnounce(29107, 3, "Interface\\Icons\\Spell_Shadow_DeathScream")
warnShoutNow.text = "|cffff3333Disrupting Shout|r"
local warnShoutNowNEW = mod:NewSpellAnnounce(9250696, 3, "Interface\\Icons\\Ability_Warrior_RallyingCry")    -- local warnShoutNowNEW = mod:NewAnnounce("warnShoutNowNEW", 3, "Interface\\Icons\\Ability_Warrior_RallyingCry")
warnShoutNowNEW.text = "|cff1a99ffDisciplinary Shout|r"
--local warnShoutSoon		= mod:NewSoonAnnounce(29107, 3)
local warnShieldWall	= mod:NewAnnounce("WarningShieldWallSoon", 3, 29061, nil, nil, nil, 29061)
local specJaggedKnife       = mod:NewSpecialWarningYou(9250609, nil, nil, nil, 1, 2)

local timerShout		= mod:NewNextTimer(15, 29107, "Disrupting Shout", nil, nil, 2, "Interface\\Icons\\Spell_Shadow_DeathScream",nil ,true) -- Whitemane PTR buff notes say it should be 12, but was consistently 15s in the vod
--local timerShoutCasting		= mod:NewNextTimer(15, 9250696, nil, nil, nil, 2, "Interface\\Icons\\Spell_Shadow_DeathScream")
local timerShoutCasting = mod:NewNextTimer(15, 9250696, "Disciplinary Shout", nil, nil, 1, nil ,nil, true)     --local timerShoutCasting = mod:NewTimer(15, "Disciplinary Shout", "Interface\\Icons\\Ability_Warrior_RallyingCry", nil, nil, 1) 
timerShoutCasting.icon = "Interface\\Icons\\Ability_Warrior_RallyingCry"
local timerTaunt		= mod:NewCDTimer(20, 29060, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerShieldWall	= mod:NewCDTimer(20, 29061, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerMindControl	= mod:NewBuffActiveTimer(60, 605, nil, nil, nil, 6)
local timerJaggedKnife		= mod:NewNextTimer(10, 9250609, "Jagged Knife", nil, nil, 3, nil, nil, true)

mod:AddBoolOption("YellJaggedKnifeCountdown", true, "announce", nil, nil, nil, 9250609)

function mod:OnCombatStart()
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

	if self:IsDifficulty("normal10") or self:IsDifficulty("heroic10") then
		timerJaggedKnife:Start(15)
	else
		timerJaggedKnife:Start(35)
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
	elseif args:IsSpellID(9250609, 55550, 9250608) then    -- Jagged Knife
		if self:IsDifficulty("normal10") or self:IsDifficulty("heroic10") then
			timerJaggedKnife:Start(25)
		else
			timerJaggedKnife:Start()
		end
    end
end
	

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 605 and args:IsSrcTypePlayer() then -- Mind Control
		timerMindControl:Start(nil, args.sourceName)
	elseif args:IsSpellID(9250609, 48074, 55550, 9250608) then     -- Jagged Knife
		if args:IsPlayer() then
            specJaggedKnife:Show()
			specJaggedKnife:Play("targetyou")

            -- warning odpali siê tylko jeœli opcja w DBM jest w³¹czona
            if self.Options.YellJaggedKnifeCountdown then

				SendChatMessage("Jagged Knife on " .. args.destName, "SAY")
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
