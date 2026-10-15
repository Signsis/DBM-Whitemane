-- this file uses the texture Textures/arrow.tga. This image was created by Everaldo Coelho and is licensed under the GNU Lesser General Public License. See Textures/lgpl.txt.
local mod	= DBM:NewMod("Thaddius", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221008164846")
mod:SetCreatureID(15928)

mod:RegisterCombat("combat_yell", L.Yell)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 28089 9250710",
	"SPELL_CAST_SUCCESS 9250651 54531 28167 9250650",
	--"SPELL_AURA_APPLIED 45185",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_AURA player"
)

--local warnShiftSoon			= mod:NewPreWarnAnnounce(28089, 5, 3)
local warnShiftCasting		= mod:NewCastAnnounce(28089, 4)
local warnThrow				= mod:NewSpellAnnounce(28338, 2)
local warnThrowSoon			= mod:NewSoonAnnounce(28338, 1)
local warnTeslaOverloadCasting		= mod:NewCastAnnounce(9250710, 4)

local warnChargeChanged		= mod:NewSpecialWarning("WarningChargeChanged", nil, nil, nil, 3, 2, nil, nil, 28089)
local warnChargeNotChanged	= mod:NewSpecialWarning("WarningChargeNotChanged", false, nil, nil, 1, 12, nil, nil, 28089)
--local timerDebuffStompCD		 = mod:NewCDTimer(15, 45185, nil, nil, nil, 3)
--local warnDebuffStompOn			 = mod:NewTargetAnnounce(45185, 2)
--local specWarnStomp			= mod:NewSpecialWarningTaunt(45185, nil, nil, nil, 1, 2)
local yellShift				= mod:NewShortPosYell(28089, DBM_CORE_L.AUTO_YELL_CUSTOM_POSITION)

local enrageTimer			= mod:NewBerserkTimer(480)
local timerNextShift		= mod:NewNextTimer(20, 28089, "Polarity Shift", nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerShiftCast		= mod:NewCastTimer(3, 28089, nil, nil, nil, 2)
local timerThrow			= mod:NewNextTimer(28, 28338, "Magnetic Pull", nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerChainLightning		= mod:NewNextTimer(15, 9250651, "Chain Lightning", nil, nil, 3, nil, nil, true)
local warnChainLightning    = mod:NewSpellAnnounce(9250651, 3)

if not DBM.Options.GroupOptionsBySpell then
	mod:AddMiscLine(DBM_CORE_L.OPTION_CATEGORY_DROPDOWNS)
end
mod:AddDropdownOption("ArrowsEnabled", {"Never", "TwoCamp", "ArrowsRightLeft", "ArrowsInverse"}, "Never", "misc", nil, 28089) --not grouping to prevent padding issue (aggravated with ElvUI) and ungrouped dropdown line workaround

mod:SetBossHealthInfo(
	15930, L.Boss1,
	15929, L.Boss2
)

local currentCharge = nil

local function TankThrow(self)
	if not self:IsInCombat() or self.vb.phase == 2 then
		DBM.BossHealth:Hide()
		return
	end
	timerThrow:Start()
	warnThrow:Show()
	warnThrowSoon:Schedule(23)
	self:Schedule(28, TankThrow, self)
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	currentCharge = nil
	self:Schedule(25 - delay, TankThrow, self)
	timerThrow:Start(25-delay)
	warnThrowSoon:Schedule(20 - delay)
end

mod.vb.lastShift = 0

function mod:SPELL_CAST_START(args)
	if args.spellId == 28089 then -- Polarity Shift
		self:SetStage(2)
		if self:IsDifficulty("normal10") or self:IsDifficulty("normal25") then
			timerNextShift:Start(30)
			--warnShiftSoon:Schedule(25)
		else
			timerNextShift:Start(30)
			--warnShiftSoon:Schedule(25)
		end
		timerShiftCast:Start()
		warnShiftCasting:Show()
		self.vb.lastShift = GetTime()
	elseif args.spellId == 9250710 then
		warnTeslaOverloadCasting:Show()
	end
end

function mod:UNIT_AURA()
	if self.vb.phase ~= 2 or not self.vb.lastShift or (GetTime() - self.vb.lastShift) < 3 then
		return
	end

	local charge
	local i = 1

	while UnitDebuff("player", i) do
		local _, _, icon, count = UnitDebuff("player", i)
		if icon == "Interface\\Icons\\Spell_ChargeNegative" then
			if count > 1 then return end -- to jest stackujący dmg debuff, ignorujemy
			charge = L.Charge1
		elseif icon == "Interface\\Icons\\Spell_ChargePositive" then
			if count > 1 then return end
			charge = L.Charge2
		end
		i = i + 1
	end

	if not charge then
		return
	end

	self.vb.lastShift = 0

	if charge == currentCharge then
		warnChargeNotChanged:Show()
		warnChargeNotChanged:Play("dontmove")

		if self.Options.ArrowsEnabled == "ArrowsInverse" then
			self:ShowLeftArrow()
		elseif self.Options.ArrowsEnabled == "ArrowsRightLeft" then
			self:ShowRightArrow()
		end

		return
	end

	if charge == L.Charge1 then
		yellShift:Yell(7, "- -")
	else
		yellShift:Yell(6, "+ +")
	end

	warnChargeChanged:Show(charge)
	warnChargeChanged:Play("stilldanger")

	if self.Options.ArrowsEnabled == "ArrowsInverse" then
		self:ShowRightArrow()
	elseif self.Options.ArrowsEnabled == "ArrowsRightLeft" then
		self:ShowLeftArrow()
	elseif self.Options.ArrowsEnabled == "TwoCamp" then
		self:ShowUpArrow()
	end

	currentCharge = charge
end

--function mod:SPELL_AURA_APPLIED(args)
--	if args.spellId == 45185 then
--		timerDebuffStompCD:Start()
--		warnDebuffStompOn:Show(args.destName)
--		if not args:IsPlayer() then
--			specWarnStomp:Show(args.destName)
--			specWarnStomp:Play("tauntboss")
--		end
--	end
--end

function mod:CHAT_MSG_MONSTER_YELL(msg, npc)
	if npc == L.name and self.vb.phase ~= 2 then
		self:SendSync("P2")
	elseif msg and msg:find("Maximum power!") then    -- ta nowa faza
        timerNextShift:Cancel()
	end
end

function mod:OnSync(msg)
	if msg == "P2" then
		self:Unschedule(TankThrow)
		timerThrow:Cancel()
		warnThrowSoon:Cancel()
		DBM.BossHealth:Hide()
		enrageTimer:Start()
		timerNextShift:Start(15)
		timerChainLightning:Start(14)
		--warnShiftSoon:Schedule(10)
		self:SetStage(2)
		--if self:IsDifficulty("heroic10") or self:IsDifficulty("heroic25") then
		--	timerDebuffStompCD:Start()
		--end
	end
end

local function arrowOnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= 3.5 and self.elapsed < 4.5 then
		self:SetAlpha(4.5 - self.elapsed)
	elseif self.elapsed >= 4.5 then
		self:Hide()
	end
end

local function arrowOnShow(self)
	self.elapsed = 0
	self:SetAlpha(1)
end

local arrowLeft = CreateFrame("Frame", nil, UIParent)
arrowLeft:Hide()
local arrowLeftTexture = arrowLeft:CreateTexture(nil, "BACKGROUND")
arrowLeftTexture:SetTexture("Interface\\AddOns\\DBM-Naxx\\ConstructQuarter\\Textures\\arrow")
arrowLeftTexture:SetPoint("CENTER", arrowLeft, "CENTER")
arrowLeft:SetHeight(1)
arrowLeft:SetWidth(1)
arrowLeft:SetPoint("CENTER", UIParent, "CENTER", -150, -30)
arrowLeft:SetScript("OnShow", arrowOnShow)
arrowLeft:SetScript("OnUpdate", arrowOnUpdate)

local arrowRight = CreateFrame("Frame", nil, UIParent)
arrowRight:Hide()
local arrowRightTexture = arrowRight:CreateTexture(nil, "BACKGROUND")
arrowRightTexture:SetTexture("Interface\\AddOns\\DBM-Naxx\\ConstructQuarter\\Textures\\arrow")
arrowRightTexture:SetPoint("CENTER", arrowRight, "CENTER")
arrowRightTexture:SetTexCoord(1, 0, 0, 1)
arrowRight:SetHeight(1)
arrowRight:SetWidth(1)
arrowRight:SetPoint("CENTER", UIParent, "CENTER", 150, -30)
arrowRight:SetScript("OnShow", arrowOnShow)
arrowRight:SetScript("OnUpdate", arrowOnUpdate)

local arrowUp = CreateFrame("Frame", nil, UIParent)
arrowUp:Hide()
local arrowUpTexture = arrowUp:CreateTexture(nil, "BACKGROUND")
arrowUpTexture:SetTexture("Interface\\AddOns\\DBM-Naxx\\ConstructQuarter\\Textures\\arrow")
arrowUpTexture:SetRotation(math.pi * 3 / 2)
arrowUpTexture:SetPoint("CENTER", arrowUp, "CENTER")
arrowUp:SetHeight(1)
arrowUp:SetWidth(1)
arrowUp:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
arrowUp:SetScript("OnShow", arrowOnShow)
arrowUp:SetScript("OnUpdate", arrowOnUpdate)

function mod:ShowRightArrow()
	arrowRight:Show()
end

function mod:ShowLeftArrow()
	arrowLeft:Show()
end

function mod:ShowUpArrow()
	arrowUp:Show()
end

function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(9250651, 54531, 28167, 9250650) then
		timerChainLightning:Start()
		warnChainLightning:Show()
	end
end
