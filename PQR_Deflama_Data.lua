-------------------------------------------------------------------------------
-- Functions & Variables
-------------------------------------------------------------------------------
if not PQR_LoadedDataFile then
	PQR_LoadedDateFile = 1
	print("|cffFFBE69Deflama Data File v1.2 - Nov 2, 2013|cffffffff")
end

---------------------------
-- Dead's Data Functions --
---------------------------

function SIN_convert(spell)
	local spell = GetSpellInfo(spell)
	return spell
end

function SIN_Cast(spell, unit)
	local spell = SIN_convert(spell)
	if IsUsableSpell(spell)
			and GetSpellCooldown(spell) == 0
			and not UnitCastingInfo("player")
			and not UnitChannelInfo("player") then
		SIN_CastTarget = unit 
		CastSpellByName(spell, unit)
	end
end

function SIN_CanCast(spell, unit)
	local spell = SIN_convert(spell)
	local unit = unit or "target"
	if UnitCanAttack("player", unit)
			and not SIN_CastImmune(unit)
			and (not UnitIsDeadOrGhost(unit)
			or UnitIsFeignDeath(unit))
			and (IsSpellInRange(spell) == 1
			or not IsSpellInRange(spell)) then
		return true
	end
end

function SIN_CastImmune(unit)
	local Immune={
		"Hand of Protection",
		"Divine Shield",
		"Ice Block",
		"Dispersion",
		"Deterrence",
		"Dematerialize",
		"Touch of Karma",
		}
	for i=1,#Immune do
		if UnitBuff(unit,Immune[i]) or
				UnitDebuff(unit, "Cyclone") then
			return 1
		end
	end
end

function SIN_UnitDebuffCount(unit, spell, filter)
	local spell = SIN_convert(spell)
	local debuff = { UnitDebuff(unit, spell, nil, filter) }
	if debuff[1] then
		return debuff[4]
	else
		return 0
	end
end

function SIN_UnitDebuffTime(unit, spell, filter)
	local spell = SIN_convert(spell)
	local debuff = { UnitDebuff(unit, spell, nil, filter) }
	if debuff[1] then
		return debuff[7] - GetTime()
	else
		return 0
	end
end

function SIN_CooldownRemains(spellId)
	local base = GetSpellBaseCooldown(spellId) / 1000
	local cd = GetTime() - GetSpellCooldown(spellId)
	local remains = base - cd
	if remains <= base
			and remains >= 0 then
		return remains
	else
		return base
	end
end

--------------------------------------------------------------------------------------------------
--									Nova Functions												--
--------------------------------------------------------------------------------------------------
Nova_UnitInfo = nil
function Nova_UnitInfo(t)
	-- Takes an input of UnitID (player, target, pet, mouseover, etc) and gives you their most useful info
		local CurShield = UnitHealth(t)
		if Nova_54EventsCheck then
			if UnitDebuffID("player",142861) then --Ancient Miasma
				CurShield = select(15,UnitDebuffID(t, 142863)) or select(15,UnitDebuffID(t, 142864)) or select(15,UnitDebuffID(t, 142865)) or (UnitHealthMax(t) / 2) or 400000
			end
		end
		
		local TManaActual = UnitPower(t)
		local TMaxMana = UnitPowerMax(t)
		if TMaxMana == 0 then TMaxMana = 1 end			
		local TMana = 100 * UnitPower(t) / TMaxMana
		local THealthActual = CurShield
		local THealth = 100 * CurShield / UnitHealthMax(t) 		
		local myClassPower = 0 
		local PQ_Class = select(2, UnitClass(t)) 
		local PQ_UnitLevel = UnitLevel(t)
		local PQ_CombatCheck = UnitAffectingCombat(t) 
		if PQ_Class == "PALADIN" then
			myClassPower = UnitPower("player", 9)
			if UnitBuffID("player", 90174) then
				myClassPower = myClassPower + 3
			end
		elseif PQ_Class == "PRIEST" then
			myClassPower = UnitPower("player", 13)
		elseif PQ_Class == "DRUID" and PQ_Class == 2 then
			myClassPower = UnitPower("player", 8)
		elseif PQ_Class == "MONK"  then
			myClassPower = UnitPower("player", 12)
		end
		--       1            2          3         4           5             6          7               8
		return THealth, THealthActual, TMana, TManaActual, myClassPower, PQ_Class, PQ_UnitLevel, PQ_CombatCheck
end

-- Self Explainatory
GlyphCheck = nil
function GlyphCheck(glyphid)
	for i=1, 6 do
		if select(4, GetGlyphSocketInfo(i)) == glyphid then
			return true
		end
	end
	return false
end

--Tabled Cast Time Checking for When you Last Cast Something.
CheckCastTime = {}
Nova_CheckLastCast = nil
function Nova_CheckLastCast(spellid, ytime) -- SpellID of Spell To Check, How long of a gap are you looking for?
	if ytime > 0 then
		if #CheckCastTime > 0 then
			for i=1, #CheckCastTime do
				if CheckCastTime[i].SpellID == spellid then
					if GetTime() - CheckCastTime[i].CastTime > ytime then
						CheckCastTime[i].CastTime = GetTime()
						return true
					else
						return false
					end
				end
			end
		end
		table.insert(CheckCastTime, { SpellID = spellid, CastTime = GetTime() } )
		return true
	elseif ytime <= 0 then
		return true
	end
	return false
end

--------------------------------------------------------------------------------------------------
--									Copied Functions											--
--------------------------------------------------------------------------------------------------
Nova_CustomT = { }

----------------------------------------------
-- Sheuron Healing Functions
----------------------------------------------
function CalculateHP(t)
	local incomingheals = UnitGetIncomingHeals(t) and UnitGetIncomingHeals(t) or 0
	local PercentWithIncoming = 100 * ( UnitHealth(t) + incomingheals ) / UnitHealthMax(t)
	local ActualWithIncoming = ( UnitHealthMax(t) - ( UnitHealth(t) + incomingheals ) )
	if PercentWithIncoming and ActualWithIncoming then
		return PercentWithIncoming, ActualWithIncoming
	else
		return 100,UnitHealthMax("player")
	end
end

function CalculateShieldHP(t)
	local incomingheals = 0
	local CurShield = select(15,UnitDebuffID(t, 142863)) or select(15,UnitDebuffID(t, 142864)) or select(15,UnitDebuffID(t, 142865)) or (UnitHealthMax(t) / 2) or 400000
	local PercentWithIncoming = 100 * ( CurShield + incomingheals ) / UnitHealthMax(t)
	local ActualWithIncoming = ( UnitHealthMax(t) - ( CurShield + incomingheals ) )
	if PercentWithIncoming and ActualWithIncoming then
		return PercentWithIncoming, ActualWithIncoming
	else
		return 100,UnitHealthMax("player")
	end
end

function CanHeal(t)
	if not UnitIsCharmed(t) 
		and (UnitInRange(t) or not UnitIsPlayer(t))
		and UnitIsConnected(t)
		and (UnitCanCooperate("player",t) or not UnitIsPlayer(t))			
		and not LineOfSight(t)
		and not UnitIsDeadOrGhost(t) 
		and not PQR_IsOutOfSight(t) 		
		and CanHealEvents(t)				
		and UnitDebuffID(t,76577) == nil -- Smoke Bomb - Rogue
		then 
			return true
		else 
			return false 
		end 
end

function CanHealEvents(t)
	local che = true
	if Nova_4xEventsCheck then
		if UnitDebuffID(t,104451) == nil -- Ice Tomb - Hagara the Stormbinder
		and UnitDebuffID(t,23402) == nil -- Corrupted Healing - DS 
		then
			che = true
		else
			che = false
		end
	end

	if Nova_53EventsCheck then
		if UnitDebuffID(t,121949) == nil -- Parasistic Growth - Amber-Shaper Un'sok
		and UnitDebuffID(t,122784) == nil -- Reshape Life - Amber-Shaper Un'sok
		and UnitDebuffID(t,122370) == nil -- Reshape Life 2 - Amber-Shaper Un'sok
		and UnitDebuffID(t,123184) == nil -- Dissonance Field
		and UnitDebuffID(t,123255) == nil -- Dissonance Field 2
		and UnitDebuffID(t,123596) == nil -- Dissonance Field 3 
		and UnitDebuffID(t,128353) == nil -- Dissonance Field 4
		and UnitDebuffID(t,128353) == nil -- Dissonance Field 4
		then
			che = true
		else
			che = false
		end
	end

	if Nova_53EventsCheck then
		if UnitDebuffID(t,137341) == nil -- Beast of Nightmares	
		and UnitDebuffID(t,137360) == nil -- Corrupted Healing - ToT	
		and UnitDebuffID(t,140701) == nil -- Crystal Shell: Full Capacity! - Tortos HC - break SpiritShell				
		then
			che = true
		else
			che = false
		end
	end
	return che
end

function SheuronEngine(MO, LOWHP, ACTUALHP, TARGETHEAL, SPECIALNPCS, HEALPET)
	Nova_Tanks = { }
	Queue_Sys = { }
	local MouseoverCheck = MO or false
	local ActualHP = ACTUALHP or false
	local LowHPTarget = LOWHP or 80
	local TargetHealCheck = TARGETHEAL or false
	local SPECIALNPCS = SPECIALNPCS or false
	local HEALPET = HEALPET or true
	local ASP = UnitGetTotalAbsorbs("player") or 0	
	lowhpmembers = 0
	
	members = { { Unit = "player", HP = CalculateHP("player"), GUID = UnitGUID("player"), AHP = select(2, CalculateHP("player")), IsNPC = false, ASP = ASP } } 

	if SPECIALNPCS then	
		if UnitDebuffID("player",145206) then --Aqua Bomb - Proving Grounds							
			table.insert(Queue_Sys, { Unit = "player", HP = CalculateHP("player"), AHP = select(2, CalculateHP("player")), Type = 1, DebuffID = 145206, Stacks = 1, IsNPC = false, SpellType = 1 } )
		end	
	end	
				
	-- Check if the Player is apart of the Custom Table
	if #Nova_CustomT > 0 then
		for i=1, #Nova_CustomT do 
			if UnitGUID("player") == Nova_CustomT[i].GUID then 
				Nova_CustomT[i].Unit = "player" 
				Nova_CustomT[i].HP = CalculateHP("player")
				Nova_CustomT[i].AHP = select(2, CalculateHP("player")) 
				Nova_CustomT[i].IsNPC = false
				Nova_CustomT[i].ASP = ASP
			end 
		end
	end

	if IsInRaid() then
			group = "raid"
	elseif IsInGroup() then
			group = "party"
	end
	
	for i = 1, GetNumGroupMembers() do 
		local member, memberhp, memberahp, uidmember = group..i, CalculateHP(group..i), select(2, CalculateHP(group..i)), UnitGUID(group..i)	
		local memberasp = UnitGetTotalAbsorbs(group..i) or 0
		-- Checking all Party/Raid Members for Range/Health
		if ((UnitExists(member) and CanHeal(member)) or UnitIsUnit("player",member))
		and member ~= nil and memberhp ~= nil and memberahp ~= nil and uidmember ~= nil then 
			-- Checking if Member has threat
			if UnitThreatSituation(member) == 3 then memberhp = memberhp - 1 end			
			-- Checking if Member is a tank
			if UnitGroupRolesAssigned(member) == "TANK" then
				memberhp = memberhp - 1 
				table.insert(Nova_Tanks, { Unit = member, HP = memberhp, AHP = memberahp, IsNPC = false, ASP = memberasp } )
			end				
			
			--Special NPCs	
			if SPECIALNPCS then	
				local npcid = tonumber(UnitGUID(member):sub(6,10), 16)				
				if UnitDebuffID(member,145263) then --Chomp debuff - Proving Grounds
					memberhp = memberhp - 20
				end				
				if UnitDebuffID(member,145206) or UnitDebuffID(member,139375) or UnitDebuffID(member,139966) then --Aqua Bomb - Proving Grounds, Shadow Burst & Debilitate - Legendary quest					
					memberhp = memberhp - 5
					if npcid == 0 then
						local IsNPC = false
					else
						local IsNPC = true
					end
					table.insert(Queue_Sys, { Unit = member, HP = memberhp, AHP = memberahp, Type = 1, DebuffID = 145206, Stacks = 1, IsNPC = IsNPC, SpellType = 1 } )
					--PQR_WriteToChat("\124cFFFF55FFUnitName: "..UnitName(member))
				end					
				if npcid == 72218 or npcid == 69837 then --Oto the Protector - Proving Grounds
					memberhp = memberhp - 1 
					table.insert(Nova_Tanks, { Unit = member, HP = memberhp, AHP = memberahp, IsNPC = true, ASP = memberasp } )
					--PQR_WriteToChat("\124cFFFF55FF1111111111")
				end				
			end
			
			-- If they are in the Custom Table add their info in
			if #Nova_CustomT > 0 then
				for i=1, #Nova_CustomT do 
					if uidmember == Nova_CustomT[i].GUID then 
						Nova_CustomT[i].Unit = member 
						Nova_CustomT[i].HP = memberhp 
						Nova_CustomT[i].AHP = memberahp
						Nova_CustomT[i].IsNPC = false
						Nova_CustomT[i].ASP = memberasp					
					end 
				end 
			end

			table.insert( members,{ Unit = member, HP = memberhp, GUID = uidmember, AHP = memberahp, IsNPC = false, ASP = memberasp } ) 
			
			-- Setting Low HP Members variable for AoE Healing
			if not ActualHP and memberhp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			elseif ActualHP and memberahp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			end			
		end 
		
		-- Checking Pets in the group
		if HEALPET and UnitExists(group..i.."pet") and CanHeal(group..i.."pet") then
			local memberpet, memberpethp, memberpetahp, uidmemberpet, memberpetASP = nil, nil, nil, nil, nil
			if UnitAffectingCombat("player") then
				 memberpet = group..i.."pet" 
				 memberpethp = CalculateHP(memberpet) * 2				 
				 memberpetahp = select(2, CalculateHP(memberpet))
				 uidmemberpet = UnitGUID(memberpet)
				 memberpetASP = UnitGetTotalAbsorbs(memberpet) or 0
			else
				 memberpet = group..i.."pet" 
				 memberpethp = CalculateHP(memberpet)				 
				 memberpetahp = select(2, CalculateHP(memberpet))
				 uidmemberpet = UnitGUID(memberpet)
				 memberpetASP = UnitGetTotalAbsorbs(memberpet) or 0
			end
			
			-- Checking if Pet is apart of the CustomTable
			if #Nova_CustomT > 0 then
				for i=1, #Nova_CustomT do 
					if uidmemberpet == Nova_CustomT[i].GUID then 
						Nova_CustomT[i].Unit = memberpet 
						Nova_CustomT[i].HP = memberpethp
						Nova_CustomT[i].AHP = memberpetahp
						Nova_CustomT[i].IsNPC = false
						Nova_CustomT[i].ASP = memberpetASP						
					end
				end
			end
			if memberpet ~= nil and memberpethp ~= nil and uidmemberpet ~= nil and memberpetahp ~= nil then
				table.insert(members, { Unit = memberpet, HP = memberpethp, GUID = uidmemberpet, AHP = memberpetahp, IsNPC = false, ASP = memberpetASP } )
			end
			-- Setting Low HP Members variable for AoE Healing
			if not ActualHP and memberpethp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			elseif ActualHP and memberpetahp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			end				
		end

	end 

	--Bad Debuffs
	if #Queue_Sys > 0 then
		table.sort(Queue_Sys, function(x,y) return x.Stacks > y.Stacks end)
	end
			
	-- So if we pass that ActualHP is true, then we will sort by most health missing. If not, we sort by lowest % of health.
	if not ActualHP then
		table.sort(members, function(x,y) return x.HP < y.HP end)
		if #Nova_Tanks > 0 then
			table.sort(Nova_Tanks, function(x,y) return x.HP < y.HP end)
		end
	elseif ActualHP then
		table.sort(members, function(x,y) return x.AHP > y.AHP end)
		if #Nova_Tanks > 0 then
			table.sort(Nova_Tanks, function(x,y) return x.AHP > y.AHP end)
		end
	end
	
	-- Checking Priority Targeting
	if TargetHealCheck and CanHeal("target") then
		table.sort(members, function(x) return UnitIsUnit("target",x.Unit) end)
	elseif MouseoverCheck and CanHeal("mouseover") and GetMouseFocus() ~= WorldFrame then
		table.sort(members, function(x) return UnitIsUnit("mouseover",x.Unit) end)
	end
end

function ShieldSheuronEngine(MO, LOWHP, ACTUALHP, TARGETHEAL, HEALPET)
	Nova_Tanks = { }
	local MouseoverCheck = MO or false
	local ActualHP = ACTUALHP or false
	local LowHPTarget = LOWHP or 80
	local TargetHealCheck = TARGETHEAL or false
	local HEALPET = HEALPET or true
	local ASP = UnitGetTotalAbsorbs("player") or 0	
	lowhpmembers = 0
	
	members = { { Unit = "player", HP = CalculateShieldHP("player"), GUID = UnitGUID("player"), AHP = select(2, CalculateShieldHP("player")), IsNPC = false, ASP = ASP } } 
		
	-- Check if the Player is apart of the Custom Table
	if #Nova_CustomT > 0 then
		for i=1, #Nova_CustomT do 
			if UnitGUID("player") == Nova_CustomT[i].GUID then 
				Nova_CustomT[i].Unit = "player" 
				Nova_CustomT[i].HP = CalculateShieldHP("player")
				Nova_CustomT[i].AHP = select(2, CalculateShieldHP("player")) 
				Nova_CustomT[i].IsNPC = false
				Nova_CustomT[i].ASP = ASP
			end 
		end
	end

	if IsInRaid() then
			group = "raid"
	elseif IsInGroup() then
			group = "party"
	end
	
	for i = 1, GetNumGroupMembers() do 
		local member, memberhp, memberahp, uidmember = group..i, CalculateShieldHP(group..i), select(2, CalculateShieldHP(group..i)), UnitGUID(group..i)	
		local memberasp = UnitGetTotalAbsorbs(group..i) or 0	
		
		-- Checking all Party/Raid Members for Range/Health
		if (UnitExists(member) and CanHeal(member)) or UnitIsUnit("player",member) then 
			-- Checking if Member has threat
			if UnitThreatSituation(member) == 3 then memberhp = memberhp - 1 end			
			-- Checking if Member is a tank
			if UnitGroupRolesAssigned(member) == "TANK" then
				memberhp = memberhp - 1 
				if member ~= nil and memberhp ~= nil and memberahp ~= nil then
					table.insert(Nova_Tanks, { Unit = member, HP = memberhp, AHP = memberahp, IsNPC = false, ASP = memberasp } )
				end
			end				
		
			-- If they are in the Custom Table add their info in
			if #Nova_CustomT > 0 then
				for i=1, #Nova_CustomT do 
					if uidmember == Nova_CustomT[i].GUID then 
						Nova_CustomT[i].Unit = member 
						Nova_CustomT[i].HP = memberhp 
						Nova_CustomT[i].AHP = memberahp
						Nova_CustomT[i].IsNPC = false
						Nova_CustomT[i].ASP = memberasp
					end 
				end 
			end
			if member ~= nil and memberhp ~= nil and uidmember ~= nil and memberahp ~= nil then
				table.insert( members,{ Unit = member, HP = memberhp, GUID = uidmember, AHP = memberahp, IsNPC = false, ASP = memberasp } ) 
			end
			-- Setting Low HP Members variable for AoE Healing
			if not ActualHP and memberhp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			elseif ActualHP and memberahp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			end			
		end 
		
		-- Checking Pets in the group
		if HEALPET and UnitExists(group..i.."pet") and CanHeal(group..i.."pet") then
			local memberpet, memberpethp, memberpetahp, uidmemberpet, memberpetASP = nil, nil, nil, nil, nil
			if UnitAffectingCombat("player") then
				 memberpet = group..i.."pet" 
				 memberpethp = CalculateShieldHP(memberpet) * 2				 
				 memberpetahp = select(2, CalculateShieldHP(memberpet))
				 uidmemberpet = UnitGUID(memberpet)
				 memberpetASP = UnitGetTotalAbsorbs(memberpet) or 0
			else
				 memberpet = group..i.."pet" 
				 memberpethp = CalculateShieldHP(memberpet)				 
				 memberpetahp = select(2, CalculateShieldHP(memberpet))
				 uidmemberpet = UnitGUID(memberpet)
				 memberpetASP = UnitGetTotalAbsorbs(memberpet) or 0
			end
			
			-- Checking if Pet is apart of the CustomTable
			if #Nova_CustomT > 0 then
				for i=1, #Nova_CustomT do 
					if uidmemberpet == Nova_CustomT[i].GUID then 
						Nova_CustomT[i].Unit = memberpet 
						Nova_CustomT[i].HP = memberpethp
						Nova_CustomT[i].AHP = memberpetahp
						Nova_CustomT[i].IsNPC = false
						Nova_CustomT[i].ASP = memberpetASP
					end
				end
			end
			if memberpet ~= nil and memberpethp ~= nil and uidmemberpet ~= nil and memberpetahp ~= nil then
				table.insert(members, { Unit = memberpet, HP = memberpethp, GUID = uidmemberpet, AHP = memberpetahp, IsNPC = false, ASP = memberpetASP } )
			end
			-- Setting Low HP Members variable for AoE Healing
			if not ActualHP and memberpethp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			elseif ActualHP and memberpetahp < LowHPTarget then
				lowhpmembers = lowhpmembers + 1
			end				
		end
	end 

	--Bad Debuffs
	if #Queue_Sys > 0 then
		table.sort(Queue_Sys, function(x,y) return x.Stacks > y.Stacks end)
	end
	
	-- So if we pass that ActualHP is true, then we will sort by most health missing. If not, we sort by lowest % of health.
	if not ActualHP then
		table.sort(members, function(x,y) return x.HP < y.HP end)
		if #Nova_Tanks > 0 then
			table.sort(Nova_Tanks, function(x,y) return x.HP < y.HP end)
		end
	elseif ActualHP then
		table.sort(members, function(x,y) return x.AHP > y.AHP end)
		if #Nova_Tanks > 0 then
			table.sort(Nova_Tanks, function(x,y) return x.AHP > y.AHP end)
		end
	end
	
	-- Checking Priority Targeting
	if TargetHealCheck and CanHeal("target") then
		table.sort(members, function(x) return UnitIsUnit("target",x.Unit) end)
	elseif MouseoverCheck and CanHeal("mouseover") and GetMouseFocus() ~= WorldFrame then
		table.sort(members, function(x) return UnitIsUnit("mouseover",x.Unit) end)
	end
end

function BossSheuronEngine(MO, LOWHP, ACTUALHP, TARGETHEAL, BOSSTOTAL, ONLYBOSSANDHEALER, SPELLID)
	Nova_Tanks = { }
	local MouseoverCheck = MO or false
	local ActualHP = ACTUALHP or false
	local LowHPTarget = LOWHP or 80
	local TargetHealCheck = TARGETHEAL or false
	local BOSSTOTAL = BOSSTOTAL or 1
	local ONLYBOSSANDHEALER = ONLYBOSSANDHEALER or false
	local SPELLID = SPELLID or 83968 --mass rez
	local ASP = UnitGetTotalAbsorbs("player") or 0	
	lowhpmembers = 0
	
	members = { { Unit = "player", HP = CalculateHP("player"), GUID = UnitGUID("player"), AHP = select(2, CalculateHP("player")), IsNPC = false, ASP = ASP } } 
	
	-- Check if the Player is apart of the Custom Table
	for i=1, #Nova_CustomT do 
		if UnitGUID("player") == Nova_CustomT[i].GUID then 
			Nova_CustomT[i].Unit = "player" 
			Nova_CustomT[i].HP = CalculateHP("player")
			Nova_CustomT[i].AHP = select(2, CalculateHP("player")) 
			Nova_CustomT[i].IsNPC = false
			Nova_CustomT[i].ASP = ASP
		end 
	end

	if IsInRaid() then
			group = "raid"
	elseif IsInGroup() then
			group = "party"
	end

	for i = 1, BOSSTOTAL do 
	    local boss,bosshp, bossasp = "boss"..i, CalculateHP("boss"..i), UnitGetTotalAbsorbs("boss") or 0 
	    if IsSpellInRange(GetSpellInfo(SPELLID),boss) 
	    then 
	    	if boss ~= nil and bosshp ~= nil and UnitGUID(boss) ~= nil and select(2, CalculateHP(boss)) ~= nil then
				table.insert( members,{ Unit = boss, HP = bosshp, GUID = UnitGUID(boss), AHP = select(2, CalculateHP(boss)), IsNPC = true, ASP = bossasp } ) 
			end
	    end
	end
	
	if not ONLYBOSSANDHEALER then
		for i = 1, GetNumGroupMembers() do 
			local member, memberhp, memberasp = group..i, CalculateHP(group..i), UnitGetTotalAbsorbs(group..i) or 0 
			
			-- Checking all Party/Raid Members for Range/Health
			if CanHeal(member) then 
				-- Checking if Member has threat
				if UnitThreatSituation(member) == 3 then memberhp = memberhp - 1 end
				-- Checking if Member is a tank
				if UnitGroupRolesAssigned(member) == "TANK" then 
					memberhp = memberhp - 1 
					if member ~= nil and memberhp ~= nil and select(2, CalculateHP(member)) ~= nil then
						table.insert(Nova_Tanks, { Unit = member, HP = memberhp, AHP = select(2, CalculateHP(member)), IsNPC = false, ASP = memberasp } )
					end
				end			
				-- If they are in the Custom Table add their info in
				for i=1, #Nova_CustomT do 
					if UnitGUID(member) == Nova_CustomT[i].GUID then 
						Nova_CustomT[i].Unit = member 
						Nova_CustomT[i].HP = memberhp 
						Nova_CustomT[i].AHP = select(2, CalculateHP(member))
						Nova_CustomT[i].IsNPC = false
						Nova_CustomT[i].ASP = memberasp
					end 
				end 
				if group..i ~= nil and memberhp ~= nil and UnitGUID(group..i) ~= nil and select(2, CalculateHP(group..i)) ~= nil then
					table.insert( members,{ Unit = group..i, HP = memberhp, GUID = UnitGUID(group..i), AHP = select(2, CalculateHP(group..i)), IsNPC = false, ASP = memberasp } ) 
				end
			end 
			
			-- Checking Pets in the group
			if HEALPET and UnitExists(group..i.."pet") and CanHeal(group..i.."pet") then
				local memberpet, memberpethp, memberpetahp, uidmemberpet, memberpetASP = nil, nil, nil, nil, nil
				if UnitAffectingCombat("player") then
					 memberpet = group..i.."pet" 
					 memberpethp = CalculateHP(memberpet) * 2				 
					 memberpetahp = select(2, CalculateHP(memberpet))
					 uidmemberpet = UnitGUID(memberpet)
					 memberpetASP = UnitGetTotalAbsorbs(memberpet) or 0
				else
					 memberpet = group..i.."pet" 
					 memberpethp = CalculateHP(memberpet)				 
					 memberpetahp = select(2, CalculateHP(memberpet))
					 uidmemberpet = UnitGUID(memberpet)
					 memberpetASP = UnitGetTotalAbsorbs(memberpet) or 0
				end
				
				-- Checking if Pet is apart of the CustomTable
				if #Nova_CustomT > 0 then
					for i=1, #Nova_CustomT do 
						if uidmemberpet == Nova_CustomT[i].GUID then 
							Nova_CustomT[i].Unit = memberpet 
							Nova_CustomT[i].HP = memberpethp
							Nova_CustomT[i].AHP = memberpetahp
							Nova_CustomT[i].IsNPC = false
							Nova_CustomT[i].ASP = memberpetASP						
						end
					end
				end
				if memberpet ~= nil and memberpethp ~= nil and uidmemberpet ~= nil and memberpetahp ~= nil then
					table.insert(members, { Unit = memberpet, HP = memberpethp, GUID = uidmemberpet, AHP = memberpetahp, IsNPC = false, ASP = memberpetASP } )
				end
			end
		end 
	end
	
	-- So if we pass that ActualHP is true, then we will sort by most health missing. If not, we sort by lowest % of health.
	if not ActualHP then
		table.sort(members, function(x,y) return x.HP < y.HP end)
		if #Nova_Tanks > 0 then
			table.sort(Nova_Tanks, function(x,y) return x.HP < y.HP end)
		end
	elseif ActualHP then
		table.sort(members, function(x,y) return x.AHP > y.AHP end)
		if #Nova_Tanks > 0 then
			table.sort(Nova_Tanks, function(x,y) return x.AHP > y.AHP end)
		end
	end
	
	-- Setting Low HP Members variable for AoE Healing
	for i=1,#members do
		if members[i].HP < LowHPTarget then
			lowhpmembers = lowhpmembers + 1
		end
	end
	
	-- Checking Priority Targeting
	if (CanHeal("target") or (IsSpellInRange(GetSpellInfo(SPELLID),"target") and not UnitIsPlayer("target"))) and TargetHealCheck then
		table.sort(members, function(x) return UnitIsUnit("target",x.Unit) end)
	elseif (CanHeal("mouseover") or (IsSpellInRange(GetSpellInfo(SPELLID),"mouseover") and not UnitIsPlayer("mouseover"))) and GetMouseFocus() ~= WorldFrame and MouseoverCheck then
		table.sort(members, function(x) return UnitIsUnit("mouseover",x.Unit) end)
	end
end

function PQR_UnitDistance(var1, var2)
	local distance = 50
	local a,b,c,d,e,f,g,h,i,j = GetAreaMapInfo(GetCurrentMapAreaID())
	if a ~= nil and b ~= nil and c ~= nil and d ~= nil and e ~= nil and f ~= nil and g ~= nil and h ~= nil and i ~= nil and j ~= nil then
		local x1 , y1 = PQR_UnitInfo(var1)
		local x2 , y2 = PQR_UnitInfo(var2)
		if x1 ~= nil and x2 ~= nil and y1 ~= nil and y2 ~= nil then
			local w = (d - e)
			local h = (f - g)	
			local distance = sqrt(min(x1 - x2, w - (x1 - x2))^2 + min(y1 - y2, h - (y1-y2))^2)
			--PQR_WriteToChat("\124cFFFF55FFDistance: "..distance) 
			return distance		
		end
	end
	return distance
end

function WildMushroomUnitLocTable(t)
	local x2 , y2 = PQR_UnitInfo(t)
	WildMushroomTable = { }	
	if x2 ~= nil and y2 ~= nil then 		
		table.insert(WildMushroomTable, { x = x2, y = y2, WMTime = GetTime()  } )
		--PQR_WriteToChat("\124cFFFF55FFDebug WildMushroomUnitLocTable - x2: "..x2.." - y2: "..y2)					
	end
end

function WildMushroom_UnitDistance(var1, x2, y2)
	local distance = false
	local a,b,c,d,e,f,g,h,i,j = GetAreaMapInfo(GetCurrentMapAreaID())	
	if a ~= nil and b ~= nil and c ~= nil and d ~= nil and e ~= nil and f ~= nil and g ~= nil and h ~= nil and i ~= nil and j ~= nil then
		local x1 , y1 = PQR_UnitInfo(var1)
		if x1 ~= nil and x2 ~= nil and y1 ~= nil and y2 ~= nil then
			local w = (d - e)
			local h = (f - g)	
			local distance = sqrt(min(x1 - x2, w - (x1 - x2))^2 + min(y1 - y2, h - (y1-y2))^2)
			--PQR_WriteToChat("\124cFFFF55FFDebug WildMushroomDistance: "..distance) 
			return distance		
		end
	end
	return distance
end
	
if not tLOS then tLOS={} end
if not fLOS then fLOS=CreateFrame("Frame") end

function LineOfSight(target)
	local updateRate=3
	fLOS:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	function fLOSOnEvent(self,event,...)
		if event=="COMBAT_LOG_EVENT_UNFILTERED" then
			local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, _, _, _, spellFailed  = ...				
			if subEvent ~= nil then
				if subEvent=="SPELL_CAST_FAILED" then
					local player=UnitGUID("player") or ""
					if sourceGUID ~= nil then
						if sourceGUID==player then 
							if spellFailed ~= nil then
								if spellFailed==SPELL_FAILED_LINE_OF_SIGHT 
								or spellFailed==SPELL_FAILED_NOT_INFRONT 
								or spellFailed==SPELL_FAILED_OUT_OF_RANGE 
								or spellFailed==SPELL_FAILED_UNIT_NOT_INFRONT 
								or spellFailed==SPELL_FAILED_UNIT_NOT_BEHIND 
								or spellFailed==SPELL_FAILED_NOT_BEHIND 
								or spellFailed==SPELL_FAILED_MOVING 
								or spellFailed==SPELL_FAILED_IMMUNE 
								or spellFailed==SPELL_FAILED_FLEEING 
								or spellFailed==SPELL_FAILED_BAD_TARGETS 
								or spellFailed==SPELL_FAILED_STUNNED 
								or spellFailed==SPELL_FAILED_SILENCED 
								or spellFailed==SPELL_FAILED_NOT_IN_CONTROL 
								or spellFailed==SPELL_FAILED_VISION_OBSCURED
								or spellFailed==SPELL_FAILED_DAMAGE_IMMUNE
								or spellFailed==SPELL_FAILED_CHARMED								
								then						
									tLOS={}
									tinsert(tLOS,{unit=target,time=GetTime()})			
								end
							end
						end
					end
				end
			end
			
			if #tLOS > 0 then				
				table.sort(tLOS,function(x,y) return x.time>y.time end)
				if (GetTime()>(tLOS[1].time+updateRate)) then
					tLOS={}
				end
			end
		end
	end
	fLOS:SetScript("OnEvent",fLOSOnEvent)
	if #tLOS > 0 then
		if tLOS[1].unit==target 
		then
			--PQR_WriteToChat("\124cFFFF55FFLoS Name: "..UnitName(target)) 
			return true
		end
	end
end
	
if not fSS then fSS=CreateFrame("Frame") end
function SpellSUCCEEDED(spellID,spellTARGET)
	local spellID = spellID or 0
	local spellTARGET = spellTARGET or "player"	
	fSS:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	function fSSOnEvent(self,event,...)
		if event=="COMBAT_LOG_EVENT_UNFILTERED" then
			local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, lspellID, _  = ...				
			if subEvent ~= nil then
				if subEvent=="SPELL_CAST_SUCCESS" then					
					local player=UnitGUID("player") or ""					
					if sourceGUID ~= nil then
						if sourceGUID==player then 							
							local tuid=UnitGUID(spellTARGET) or ""
							if destGUID ~= nil then
								if destGUID==tuid then									
									--PQR_WriteToChat("\124cFFFF55FFfSS1: "..subEvent.." - "..sourceGUID.." - "..lspellID.." - "..a1.." - "..a3.." - "..a4.." - "..a5.." - "..a6.." - "..a7.." - "..a8.." - lspellID: "..lspellID.." - "..a10) 
									if lspellID ~= nil then
										--PQR_WriteToChat("\124cFFFF55FFfSS2: SpellID: "..lspellID.." - Spellcached: "..spellID)
										if tonumber(lspellID) == tonumber(spellID) or (tonumber(lspellID) == 77130 and tonumber(spellID) == 51886) then																						
											if #Queue_Spell > 0 then
												PQR_WriteToChat("\124cFFFF55FFQueue System: succeeded cast "..GetSpellInfo(spellID).." on "..UnitName(spellTARGET).." - Unit: "..spellTARGET)										
												table.remove(Queue_Spell,1)
												return true										
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	fSS:SetScript("OnEvent",fSSOnEvent)
end

function VUnitFacing(t)
	local t = t or "target"
	local px,py = GetPlayerMapPosition("player")
	local tx,ty = GetPlayerMapPosition(t)
	local angle = floor ( ( math.pi - math.atan2(px-tx,ty-py) - GetPlayerFacing() ) / (math.pi*2) * 32 + 0.5 ) % 32		
	local dwt = PQR_UnitDistance(t,"player")
	return px, tx, angle, dwt, py, ty
end
--------------------------------------------------------------------------------------------------
--									Vachiusa Functions											--
--------------------------------------------------------------------------------------------------

-- Checks if our Cleanse will have a valid Debuff to Cleanse
function ValidDispel(t)
	return true
end
  
-- Custom CalStop function
function CalStop(n)	
	local myIncomingHeal = UnitGetIncomingHeals(n, "player") or 0
	local allIncomingHeal = UnitGetIncomingHeals(n) or 0
	local overheal = 0
	if myIncomingHeal >= allIncomingHeal then
		overheal = 0
	else
		overheal = allIncomingHeal - myIncomingHeal
	end
	local CurShield = UnitHealth(n)
	if Nova_54EventsCheck then
		if UnitDebuffID("player",142861) then --Ancient Miasma
			CurShield = select(15,UnitDebuffID(n, 142863)) or select(15,UnitDebuffID(n, 142864)) or select(15,UnitDebuffID(n, 142865)) or (UnitHealthMax(n) / 2) or 400000
			overheal = 0
		end
	end	
	local overhealth = 100 * (CurShield+ overheal ) / UnitHealthMax(n)
	if overhealth and overheal then
		return overhealth, overheal
	else
		return 0, 0
	end
end	

--Custom check boss npc id
function checkbossid(t)
	for i=1,4 do 
	    local bossCheck = "boss"..i 
	    if UnitExists(bossCheck) then 
	        local npcID = tonumber(UnitGUID(bossCheck):sub(6,10), 16) 	        	         
	        if npcID == t then
	        	return bossCheck	        	
	        end
	    end
	end
    return false
end
    
--Custom check boss npc id
function bossid(t)
	local bossCheck = "boss1"
	local npcID = 0
	for i=1,4 do 
	    local bossCheck = "boss"..i 
	    if UnitExists(bossCheck) then 
	        local npcID = tonumber(UnitGUID(bossCheck):sub(6,10), 16) 	        	         
	        if npcID ~= 0 then
	        	return bossCheck,npcID	        			        	        
	        end
		end
	end	    
end   

-- Average Health of Players
function AverageHealth(n) -- N = Size of the range of people we are checking
	local NumberOfPeople = n
	local Nova_Average = 0
	if #members < NumberOfPeople then
		for i=NumberOfPeople, 0, -1 do
			if #members >= i then
				NumberOfPeople = i
				break
			end
		end
	end
		
	for i=1, NumberOfPeople do
		Nova_Average = Nova_Average + members[i].HP 
	end
		
	Nova_Average = Nova_Average / NumberOfPeople
		
	return Nova_Average, NumberOfPeople
end

-- Checking if there's a dangerous Debuff we should Cleanse on boss asap
	function BossDispel(d,s,t)	
		if Nova_AutoEventDispel then	
			if UnitExists(t) then	        		
				if UnitDebuffID(t, d) then
					if IsSpellInRange(GetSpellInfo(s),t) == 1 
					and not PQR_IsOutOfSight(t)
					and PQR_SpellAvailable(s)
					and select(2,GetSpellCooldown(s)) < 2					
					and IsUsableSpell(s) then
						CastSpellByName(tostring(GetSpellInfo(s)),t)	 
	        			--return true --Silent cast
					end				
	        		
	        	end
			end
		end
	end

	function SBossDispel(d,s)	
		if Nova_AutoEventDispel then			
			for i=1,4 do 
			    local bossCheck = "boss"..i 
			    if UnitExists(bossCheck) then 
					if UnitBuffID(bossCheck, d) then				
						if IsSpellInRange(GetSpellInfo(s),bossCheck) == 1 
						and not PQR_IsOutOfSight(bossCheck)
						and PQR_SpellAvailable(s)
						and select(2,GetSpellCooldown(s)) < 2		
						and IsUsableSpell(s) then
							if d == 117283 then --prevent spam dispel Cleasing Water
								if Nova_UnitInfo(bossCheck) <= 95 then
									CastSpellByName(tostring(GetSpellInfo(s)),bossCheck)	 
				       				--return true --Silent cast
				       			end
				       		else
				       			CastSpellByName(tostring(GetSpellInfo(s)),bossCheck)	 
				       			--return true --Silent cast			       		
			       			end
						end						        		
			       	end
				end
			end	 				        		
		end
	end

-- Checking if there's a dangerous Debuff we should Cleanse asap
	function RaidDispel(t,buff) --t: dispel spell id
		if Nova_AutoEventDispel then
			Queue_Sys = { }		
			for i=1, #members do
				for j=1, #buff do
					local RDDname, RDDrank, RDDicon, RDDcount, RDDdebuffType, RDDduration, RDDexpirationTime, RDDunitCaster, RDDisStealable, RDDshouldConsolidate, RDDspellId = UnitDebuffID(members[i].Unit,buff[j])
					--if UnitDebuffID(members[i].Unit, buff[j]) then
					if RDDname then
						if IsSpellInRange(GetSpellInfo(t),members[i].Unit) == 1 						
						and not PQR_IsOutOfSight(members[i].Unit)
						and PQR_SpellAvailable(t)
						and ValidDispel(members[i].Unit)
						and select(2,GetSpellCooldown(t)) < 2
						and IsUsableSpell(t) then						
							table.insert(Queue_Sys, { Unit = members[i].Unit, HP = 0, AHP = 0, Type = RDDdebuffType, DebuffID = buff[j], Stacks = RDDcount, IsNPC = false, SpellType = 1 } )			
							--return true --Silent cast
						end
					end							
				end
			end	
			--Bad Debuffs
			if #Queue_Sys > 0 then
				table.sort(Queue_Sys, function(x,y) return x.Stacks > y.Stacks end)
			end	
		end
	end

	function RaidDispelDelay(t,buff,d) --t: dispel spell id, d: delay seconds
		if Nova_AutoEventDispel then		
			for i=1, #members do
				for j=1, #buff do
					local RDDname, RDDrank, RDDicon, RDDcount, RDDdebuffType, RDDduration, RDDexpirationTime, RDDunitCaster, RDDisStealable, RDDshouldConsolidate, RDDspellId = UnitDebuffID(members[i].Unit, buff[j])
					if RDDname then
						if IsSpellInRange(GetSpellInfo(t),members[i].Unit) == 1 						
						and not PQR_IsOutOfSight(members[i].Unit)
						and PQR_SpellAvailable(t)
						and ValidDispel(members[i].Unit)
						and select(2,GetSpellCooldown(t)) < 2
						and ((RDDduration - (RDDexpirationTime - GetTime())) >= d) --debuff time left
						and IsUsableSpell(t) then
							CastSpellByName(tostring(GetSpellInfo(t)),members[i].Unit)				
							--return true --Silent cast
						end
					end							
				end
			end		
		end
	end

	function RaidRangeDispel(t,buff,d) --t: dispel spell id, d: range check	
		if Nova_AutoEventDispel then
			for i=1, #members do
				for j=1, #buff do
					if UnitDebuffID(members[i].Unit, buff[j]) then
						if IsSpellInRange(GetSpellInfo(t),members[i].Unit) == 1 						
						and not PQR_IsOutOfSight(members[i].Unit)
						and PQR_SpellAvailable(t)
						and ValidDispel(members[i].Unit)
						and select(2,GetSpellCooldown(t)) < 2
						and IsUsableSpell(t) then
							local dsafe = true						
							for j=1,#members do		
								if PQR_UnitDistance(members[i].Unit,members[j].Unit) then
									if PQR_UnitDistance(members[i].Unit,members[j].Unit) < d 
									and not UnitIsUnit(members[i].Unit,members[j].Unit) 
									then
										dsafe = false
										break									
									end
								end
							end
							
							if dsafe then
								CastSpellByName(tostring(GetSpellInfo(t)),members[i].Unit)				
								--return true --Silent cast
							end
						end
					end							
				end
			end		
		end
	end
					
	function RaidJBDispel(t,buff,fluiditydebuff,d)	
		if Nova_AutoEventDispel then
			for i=1, #members do
				for j=1, #buff do
					if UnitDebuffID(members[i].Unit, buff[j]) then
						if IsSpellInRange(GetSpellInfo(t),members[i].Unit) == 1 						
						and not PQR_IsOutOfSight(members[i].Unit)
						and PQR_SpellAvailable(t)
						and ValidDispel(members[i].Unit)
						and select(2,GetSpellCooldown(t)) < 2
						and not UnitDebuffID(members[i].Unit, fluiditydebuff)
						and IsUsableSpell(t) then
							local dsafe = true						
							for j=1,#members do		
								if PQR_UnitDistance(members[i].Unit,members[j].Unit) then
									if PQR_UnitDistance(members[i].Unit,members[j].Unit) < d 
									and not UnitIsUnit(members[i].Unit,members[j].Unit) 
									then
										dsafe = false
										break									
									end
								end
							end
							
							if dsafe then
								CastSpellByName(tostring(GetSpellInfo(t)),members[i].Unit)				
								--return true --Silent cast
							end
						end
					end							
				end
			end		
		end
	end				
	
	function RaidLLDispel(buff) 
		local LLdebuff = false	
		local LLdebuffunit = false	
		if #Nova_Tanks == 2 then
			for i=1, #Nova_Tanks do		 
				for j=1, #buff do
					if UnitDebuffID(Nova_Tanks[i].Unit, buff[j]) then
						LLdebuff = true
						LLdebuffunit = Nova_Tanks[i].Unit
						return LLdebuff,LLdebuffunit
					end							
				end
			end
		else		
			for i=1, #members do
				for j=1, #buff do
					if UnitDebuffID(members[i].Unit, buff[j]) then
						LLdebuff = true
						LLdebuffunit = members[i].Unit
						return LLdebuff,LLdebuffunit
					end							
				end
			end		
		end
		return LLdebuff,LLdebuffunit
	end	
					
--Custom GetDistance raid/party member
function PRGetDistance(t,thp,mhp,d,b) --t: "player", "partyN" or "raidN" and not pets, thp: target HP, mhp: hp member for collect, d: distance in yard, b: number of distance requirement
	local real_b = 0
	if #members > 1 then
		for i=1,#members do		
			if PQR_UnitDistance(t,members[i].Unit) and members[i].HP then 
				if members[i].HP > mhp	then
					break
				end					
				if PQR_UnitDistance(t,members[i].Unit) <= d and not UnitIsUnit(t,members[i].Unit) and members[i].HP <= mhp then
					real_b = real_b + 1					
					--if real_b >= b then
						--break
					--end									
				end
			end
		end
		if real_b > 0 and UnitInRange(t) then --UnitInRange = 40y
			table.insert(prdistance, { Unit = t, HP = thp, PD = real_b } )
			table.sort(prdistance, function(x,y) return x.PD > y.PD end)					
		end
	end		
end  
	
function PRGetDistanceTable(mhp,d,b)		
	if not d then local d = 10 end
	if not b then local b = 25 end				
	if not mhp then local mhp = 95 end	
	prdistance = { { Unit = "player", HP = CalculateHP("player"), PD = 0 } }
	if #members > 1 then
		for i=1,#members do	
			if members[i].HP then
				if members[i].HP > mhp	then
					break
				end								
				if members[i].HP <= mhp and UnitInRange(members[i].Unit) then
					PRGetDistance(members[i].Unit, members[i].HP, mhp, d, b)
					--if prdistance[1].PD >= b then
						--break
					--end
					--EX: PRGetDistanceTable(95, 20, 7) --ChiWave
				end
			end
		end
	end
end	

--Custom sort by HP
function PRGetDistanceTablebyHP(h,b)
	prdistancebyhp = { { Unit = "player", HP = CalculateHP("player"), PD = 0 } }
	if #prdistance > 1 then
		for i=1,#prdistance do			
			if prdistance[i].PD and prdistance[i].HP then
				if prdistance[i].PD < b then
					break
				end				
				if prdistance[i].PD >= b and prdistance[i].HP <= h then
					table.insert(prdistancebyhp, { Unit = prdistance[i].Unit, HP = prdistance[i].HP, PD = prdistance[i].PD } )
					table.sort(prdistancebyhp, function(x,y) return x.HP < y.HP end)						
				end
			end
		end	
	end
end

--Custom GetDistance raid/party member with buff
function PRGetDistancebuff(t,thp,mhp,d,b,buff) --t: "player", "partyN" or "raidN" and not pets, thp: target HP, mhp: hp member for collect, d: distance in yard, b: number of distance requirement
	local real_b = 0
	if #members > 1 then
		for i=1,#members do	
			if members[i].HP and PQR_UnitDistance(t,members[i].Unit) then	
				if members[i].HP > mhp then
					break
				end					
				if PQR_UnitDistance(t,members[i].Unit) <= d and not UnitIsUnit(t,members[i].Unit) and members[i].HP <= mhp and not UnitBuffID(members[i].Unit,buff,"player") then
					real_b = real_b + 1					
					--if real_b >= b then
						--break
					--end									
				end
			end
		end
		if real_b > 0 and UnitInRange(t) then --UnitInRange = 40y
			table.insert(prdistancebuff, { Unit = t, HP = thp, PD = real_b } )
			table.sort(prdistancebuff, function(x,y) return x.PD > y.PD end)					
		end
	end		
end  

function PRGetDistanceTablebuff(mhp,d,b,buff)		
	if not d then local d = 10 end
	if not b then local b = 25 end				
	if not mhp then local mhp = 95 end	
	if not buff then local buff = 115151 end --RM
	prdistancebuff = { { Unit = "player", HP = CalculateHP("player"), PD = 0 } }
	if #members > 1 then
		for i=1,#members do	
			if members[i].HP then
				if members[i].HP > mhp then
					break
				end				
				if members[i].HP <= mhp and UnitInRange(members[i].Unit) and not UnitBuffID(members[i].Unit,buff,"player") then
					PRGetDistancebuff(members[i].Unit, members[i].HP, mhp, d, b, buff)
					--if prdistance[1].PD >= b then
						--break
					--end
					--EX: PRGetDistanceTable(95, 20, 7) --ChiWave
				end
			end
		end
	end
end	

--Custom sort by HP with buff
function PRGetDistanceTablebyHPbuff(h,b)
	prdistancebyhpbuff = { { Unit = "player", HP = CalculateHP("player"), PD = 0 } }
	if #prdistancebuff > 1 then
		for i=1,#prdistancebuff do			
			if prdistancebuff[i].PD and prdistancebuff[i].HP then
				if prdistancebuff[i].PD < b then
					break
				end				
				if prdistancebuff[i].PD >= b and prdistancebuff[i].HP <= h then
					table.insert(prdistancebyhpbuff, { Unit = prdistancebuff[i].Unit, HP = prdistancebuff[i].HP, PD = prdistancebuff[i].PD } )
					table.sort(prdistancebyhpbuff, function(x,y) return x.HP < y.HP end)						
				end
			end
		end	
	end
end	
		
--Druid 
--Custom GetDistance raid/party member
function PRGetDistance2(t,thp,mhp,d,b) --t: "player", "partyN" or "raidN" and not pets, thp: target HP, mhp: hp member for collect, d: distance in yard, b: number of distance requirement
	local real_b = 0
	if #members > 1 then
		for i=1,#members do		
			if PQR_UnitDistance(t,members[i].Unit) and members[i].HP then
				if members[i].HP > mhp then
					break
				end			
				if PQR_UnitDistance(t,members[i].Unit) <= d and not UnitIsUnit(t,members[i].Unit) and members[i].HP <= mhp then
					real_b = real_b + 1																
				end
			end
		end
		if real_b > 0 and UnitInRange(t) then --UnitInRange = 40y
			table.insert(prdistance2, { Unit = t, HP = thp, PD = real_b } )
			table.sort(prdistance2, function(x,y) return x.PD > y.PD end)					
		end
	end		
end  
			
function PRGetDistanceTablebuff2(mhp,d,b,buff1,buff2)		
	if not d then local d = 8 end
	if not b then local b = 25 end				
	if not mhp then local mhp = 95 end	
	if not buff1 then local buff1 = 8936 end
	if not buff2 then local buff2 = 774 end 
	prdistance2 = { { Unit = "player", HP = CalculateHP("player"), PD = 0 } }
	if #members > 1 then
		for i=1,#members do	
			if members[i].HP then
				if members[i].HP > mhp then
					break
				end			
				if members[i].HP <= mhp and UnitInRange(members[i].Unit) and (UnitBuffID(members[i].Unit,buff1) or UnitBuffID(members[i].Unit,buff2)) then
					PRGetDistance2(members[i].Unit, members[i].HP, mhp, d, b)
				end
			end
		end
	end
end		
	
--Custom sort by HP with buff
function PRGetDistanceTablebyHPbuff2(h,b)
	prdistancebyhp2 = { { Unit = "player", HP = CalculateHP("player"), PD = 0 } }
	if #prdistance2 > 1 then
		for i=1,#prdistance2 do			
			if prdistance2[i].PD and prdistance2[i].HP then
				if prdistance2[i].PD < b then
					break
				end				
				if prdistance2[i].PD >= b and prdistance2[i].HP <= h then
					table.insert(prdistancebyhp2, { Unit = prdistance2[i].Unit, HP = prdistance2[i].HP, PD = prdistance2[i].PD } )
					table.sort(prdistancebyhp2, function(x,y) return x.HP < y.HP end)						
				end
			end
		end	
	end
end		

function IsBoss(t)
	if UnitExists(t) then
		if UnitIsUnit(t, "boss1") or UnitIsUnit(t, "boss2") or UnitIsUnit(t, "boss3") or UnitIsUnit(t, "boss4") then
			return true
		else
			return false
		end
	end
end

 --------------------------------------------------------------------------------------------------
--									Libraries													--
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Target & Environmental Globals and Tables
-------------------------------------------------------------------------------
PQ_Shrapnel			= {106794,106791}
PQ_FadingLight		= {105925,105926,109075,109200}
PQ_HourOfTwilight	= {106371,103327,106389,106174,106370}