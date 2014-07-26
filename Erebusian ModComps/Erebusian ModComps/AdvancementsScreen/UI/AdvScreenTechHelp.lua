
local validUnitBuilds = nil;
local validBuildingBuilds = nil;
local validImprovementBuilds = nil;

-------------------------------------------------
-- Help text (popup) for techs in the advancements screen
-------------------------------------------------
function AdvScreenTechHelp( iTechID )
	local pTechInfo = GameInfo.Technologies[iTechID];
	
	local pActiveTeam = Teams[Game.GetActiveTeam()];
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local pTeamTechs = pActiveTeam:GetTeamTechs();
	local iTechCost = pActivePlayer:GetResearchCost(iTechID);
	
	local strHelpText = "";
	-- Name
	strHelpText = strHelpText .. Locale.ToUpper(Locale.ConvertTextKey( pTechInfo.Description ));

	-- Do we have this tech?
	if (pTeamTechs:HasTech(iTechID)) then
		strHelpText = strHelpText .. " [COLOR_POSITIVE_TEXT](" .. Locale.ConvertTextKey("TXT_KEY_RESEARCHED") .. ")[ENDCOLOR]";
	else
		strHelpText = strHelpText .. "[NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TT_REQUIRED");
		local prereqs = {};

		for row in GameInfo.Technology_PrereqTechs() do
			if row.TechType == pTechInfo.Type then
				table.insert(prereqs, GameInfo.Technologies[GameInfoTypes[row.PrereqTech]]);
			end
		end

		for _,prereq in pairs(prereqs) do
			local prereqTree = GameInfo.TechTreeTypes[GameInfoTypes[prereq.TechTreeType]];
			local colorText = "[COLOR_NEGATIVE_TEXT]";
			if pTeamTechs:HasTech(prereq.ID) then colorText = "[COLOR_POSITIVE_TEXT]"; end
			strHelpText = strHelpText .. colorText .. "[NEWLINE]"
						.. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TT_REQUIRED_TECH", 
												Locale.ConvertTextKey(prereq.Description), 
												Locale.ConvertTextKey(prereqTree.Description))
						.. "[ENDCOLOR]";
		end
	end

	-- Cost/Progress
	strHelpText = strHelpText .. "[NEWLINE]-------------------------[NEWLINE]";
	
	local iProgress = pActivePlayer:GetResearchProgress(iTechID);
	local bShowProgress = true;
	
	-- Don't show progres if we have 0 or we're done with the tech
	if (iProgress == 0 or pTeamTechs:HasTech(iTechID)) then
		bShowProgress = false;
	end
	
	if (bShowProgress) then
		strHelpText = strHelpText .. Locale.ConvertTextKey("TXT_KEY_TECH_HELP_COST_WITH_PROGRESS", iProgress, iTechCost);
	else
		strHelpText = strHelpText .. Locale.ConvertTextKey("TXT_KEY_TECH_HELP_COST", iTechCost);
	end
	
	-- Leads to...
	local strLeadsTo = "";
	local bFirstLeadsTo = true;
	for row in GameInfo.Technology_PrereqTechs() do
		local pPrereqTech = GameInfo.Technologies[row.PrereqTech];
		local pLeadsToTech = GameInfo.Technologies[row.TechType];
		
		if (pPrereqTech and pLeadsToTech) then
			if (pTechInfo.ID == pPrereqTech.ID) then
				
				-- If this isn't the first leads-to tech, then add a comma to separate
				if (bFirstLeadsTo) then
					bFirstLeadsTo = false;
				else
					strLeadsTo = strLeadsTo .. ", ";
				end
				
				strLeadsTo = strLeadsTo .. "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey( pLeadsToTech.Description ) .. "[ENDCOLOR]";
			end
		end
	end
	
	if (strLeadsTo ~= "") then
		strHelpText = strHelpText .. "[NEWLINE]";
		strHelpText = strHelpText .. Locale.ConvertTextKey("TXT_KEY_TECH_HELP_LEADS_TO", strLeadsTo);
	end
	-- Specific tech effects
	strHelpText = strHelpText .. "[NEWLINE]-------------------------[NEWLINE]";

	local bNotFirst = false;

	local units = GetTechUnits(pTechInfo);
	local unitCount = 0;
	for i,v in pairs(units) do unitCount = unitCount + 1; end
	if unitCount > 0 then
		strHelpText = strHelpText .. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TT_UNLOCK_UNIT_LABEL")		.. "[ICON_BULLET]" .. table.concat(units, "[NEWLINE][ICON_BULLET]");
		bNotFirst = true;
	end
	
	local buildings = GetTechBuildings(pTechInfo);
	local buildingCount = 0;
	for i,v in pairs(buildings) do buildingCount = buildingCount + 1; end
	if buildingCount > 0 then
		if bNotFirst then strHelpText = strHelpText .. "[NEWLINE]"; end
		strHelpText = strHelpText .. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TT_UNLOCK_BUILDING_LABEL")	.. "[ICON_BULLET]" .. table.concat(buildings, "[NEWLINE][ICON_BULLET]");
		bNotFirst = true;
	end
	
	local builds = GetTechBuilds(pTechInfo);
	local buildCount = 0;
	for i,v in pairs(builds) do buildCount = buildCount + 1; end
	if buildCount > 0 then
		if bNotFirst then strHelpText = strHelpText .. "[NEWLINE]"; end
		strHelpText = strHelpText .. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TT_UNLOCK_BUILD_LABEL")	.. "[ICON_BULLET]" .. table.concat(builds, "[NEWLINE][ICON_BULLET]");
		bNotFirst = true;
	end
	
	local effects = GetMiscTechEffects(pTechInfo);
	local effectCount = 0;
	for i,v in pairs(effects) do effectCount = effectCount + 1; end
	if effectCount > 0 then
		if bNotFirst then strHelpText = strHelpText .. "[NEWLINE]"; end
		strHelpText = strHelpText .. table.concat(effects, "[NEWLINE]");
		bNotFirst = true;
	end

	-- Pre-written help text
	if bNotFirst then strHelpText = strHelpText .. "[NEWLINE]-------------------------[NEWLINE]"; end
	strHelpText = strHelpText .. Locale.ConvertTextKey( pTechInfo.Help );
	
	return strHelpText;
end

-------------------------------------------------
-- Parse tech's unit unlocks to a string array
-------------------------------------------------
function GetTechUnits(eTech)
	local strRetTable = {};
 	for eUnit in GameInfo.Units(string.format("PreReqTech = '%s'", eTech.Type)) do
		if validUnitBuilds[eUnit.Class] == eUnit.Type then
			table.insert(strRetTable, Locale.ConvertTextKey(eUnit.Description));
		end
	end
	return strRetTable;
end

-------------------------------------------------
-- Parse tech's building, project and process unlocks to a string array
-------------------------------------------------
function GetTechBuildings(eTech)
	local strRetTable = {};
 	for eBuilding in GameInfo.Buildings(string.format("PreReqTech = '%s'", eTech.Type)) do
		if validBuildingBuilds[eBuilding.BuildingClass] == eBuilding.Type then
			table.insert(strRetTable, Locale.ConvertTextKey(eBuilding.Description));
		end
	end
 	for eProject in GameInfo.Projects(string.format("TechPrereq = '%s'", eTech.Type)) do
		table.insert(strRetTable, Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TT_PROJECT",eProject.Description));
	end
	return strRetTable;
end

-------------------------------------------------
-- Parse tech's build unlocks to a string array
-------------------------------------------------
function GetTechBuilds(eTech)
	local strRetTable = {};
	for eBuild in GameInfo.Builds{PrereqTech = eTech.Type, ShowInTechTree  = 1} do
		if validImprovementBuilds[eBuild.ImprovementType] == eBuild.ImprovementType then
			table.insert(strRetTable, Locale.ConvertTextKey( eBuild.Description ));
		end
	end
	return strRetTable;
end

-------------------------------------------------
-- Parse tech's other effects to a string array
-------------------------------------------------
function GetMiscTechEffects(eTech)
	local strEffectsTable = {};
	
	local condition = "TechType = '" .. eTech.Type .. "'";
	
 	for eResource in GameInfo.Resources(string.format("TechReveal = '%s'", eTech.Type)) do
		table.insert(strEffectsTable, Locale.ConvertTextKey("TXT_KEY_REVEALS_RESOURCE_ON_MAP",eResource.Description));
	end

	for row in GameInfo.Processes("TechPrereq = '" .. eTech.Type .. "'") do
		table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ENABLE_PRODUCITON_CONVERSION", Locale.ConvertTextKey( row.Description )));
	end	

	for row in GameInfo.Improvement_TechNoFreshWaterYieldChanges(condition) do
		table.insert(strEffectsTable, Locale.ConvertTextKey("TXT_KEY_NO_FRESH_WATER",GameInfo.Improvements[row.ImprovementType].Description,GameInfo.Yields[row.YieldType].Description,row.Yield));
	end	

	for row in GameInfo.Improvement_TechFreshWaterYieldChanges(condition) do
		table.insert(strEffectsTable, Locale.ConvertTextKey("TXT_KEY_FRESH_WATER",GameInfo.Improvements[row.ImprovementType].Description,GameInfo.Yields[row.YieldType].Description,row.Yield));
	end
	
	local yieldChanges = {};
	for row in GameInfo.Improvement_TechYieldChanges(condition) do
		local improvementType = row.ImprovementType;
		if(yieldChanges[improvementType] == nil) then
			yieldChanges[improvementType] = {};
		end
		local improvement = GameInfo.Improvements[row.ImprovementType];
		local yield = GameInfo.Yields[row.YieldType];
		table.insert(yieldChanges[improvementType], Locale.Lookup( "TXT_KEY_YIELD_IMPROVED", improvement.Description , yield.Description, row.Yield));
	end
	local sortedYieldChanges = {};
	for k,v in pairs(yieldChanges) do
		table.insert(sortedYieldChanges, {k,v});
	end
	table.sort(sortedYieldChanges, function(a,b) return Locale.Compare(a[1], b[1]) == -1 end); 
	for i,v in pairs(sortedYieldChanges) do
		table.sort(v[2], function(a,b) return Locale.Compare(a,b) == -1 end);
		table.insert(strEffectsTable, table.concat(v[2], "[NEWLINE]"));
	end	

	if eTech.AllowsEmbarking					then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_EMBARKING" )); end
	if eTech.EmbarkedAllWaterPassage			then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_CROSSING_OCEANS" )); end
	if eTech.AllowsDefensiveEmbarking			then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ABLTY_DEFENSIVE_EMBARK_STRING" )); end
	if eTech.EmbarkedMoveChange				> 0	then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_FASTER_EMBARKED_MOVEMENT" )); end

	if eTech.UnitFortificationModifier		> 0	then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_UNIT_FORTIFICATION_MOD", eTech.UnitFortificationModifier )); end
	if eTech.UnitBaseHealModifier			> 0	then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_UNIT_BASE_HEAL_MOD", eTech.UnitBaseHealModifier )); end

	if eTech.AllowEmbassyTradingAllowed			then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_EMBASSY" )); end
	if eTech.OpenBordersTradingAllowed			then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_OPEN_BORDERS" )); end
	if eTech.DefensivePactTradingAllowed		then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_DEFENSIVE_PACTS" )); end
	if eTech.ResearchAgreementTradingAllowed	then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_RESEARCH_AGREEMENTS" )); end
	if eTech.TradeAgreementTradingAllowed		then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_TRADE_AGREEMENTS" )); end

	if eTech.BridgeBuilding						then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_BRIDGES" )); end

	if eTech.MapVisible							then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_REVEALS_ENTIRE_MAP" )); end

	if eTech.AllowsWorldCongress				then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ALLOWS_WORLD_CONGRESS" )); end
	if eTech.ExtraVotesPerDiplomat			> 0	then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_EXTRA_VOTES_FROM_DIPLOMATS", eTech.ExtraVotesPerDiplomat )); end
	if eTech.InfluenceSpreadModifier		> 0	then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_DOUBLE_TOURISM" )); end

	if eTech.InternationalTradeRoutesChange	> 0	then table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_ADDITIONAL_INTERNATIONAL_TRADE_ROUTE" )); end
	for row in GameInfo.Technology_TradeRouteDomainExtraRange(condition) do
		if (row.TechType == eTech.Type and row.Range > 0) then
			if (GameInfo.Domains[row.DomainType].ID == DomainTypes.DOMAIN_LAND) then
				table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_EXTENDS_LAND_TRADE_ROUTE_RANGE" ));
			elseif (GameInfo.Domains[row.DomainType].ID == DomainTypes.DOMAIN_SEA) then
				table.insert(strEffectsTable, Locale.ConvertTextKey( "TXT_KEY_EXTENDS_SEA_TRADE_ROUTE_RANGE"));
			end
		end
	end
	
	for row in GameInfo.Route_TechMovementChanges(condition) do
		table.insert(strEffectsTable, Locale.ConvertTextKey("TXT_KEY_FASTER_MOVEMENT", GameInfo.Routes[row.RouteType].Description));
	end	

	for row in GameInfo.Technology_FreePromotions(condition) do
		local ePromotion = GameInfo.UnitPromotions[row.PromotionType];
		if ePromotion ~= nil then table.insert(strEffectsTable, Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TT_FREE_PROMOTION", ePromotion.Description)); end
	end
	
	return strEffectsTable;
end

-------------------------------------------------
-- Make sure the civ uniques override the defaults
-------------------------------------------------
function GatherInfoAboutUniqueStuff( civType )
	print(civType);

	validUnitBuilds = {};
	validBuildingBuilds = {};
	validImprovementBuilds = {};

	-- put in the default units for any civ
	for thisUnitClass in GameInfo.UnitClasses() do
		validUnitBuilds[thisUnitClass.Type]	= thisUnitClass.DefaultUnit;	
	end

	-- put in my overrides
	for thisOverride in GameInfo.Civilization_UnitClassOverrides() do
 		if thisOverride.CivilizationType == civType then
			validUnitBuilds[thisOverride.UnitClassType]	= thisOverride.UnitType;
			print(thisOverride.UnitType);
 		end
	end

	-- put in the default buildings for any civ
	for thisBuildingClass in GameInfo.BuildingClasses() do
		validBuildingBuilds[thisBuildingClass.Type]	= thisBuildingClass.DefaultBuilding;
	end

	-- put in my overrides
	for thisOverride in GameInfo.Civilization_BuildingClassOverrides() do
 		if thisOverride.CivilizationType == civType then
			validBuildingBuilds[thisOverride.BuildingClassType]	= thisOverride.BuildingType;
			print(thisOverride.BuildingType);	
 		end
	end
	
	-- add in support for unique improvements
	for thisImprovement in GameInfo.Improvements() do
		if thisImprovement.CivilizationType == civType or thisImprovement.CivilizationType == nil then
			validImprovementBuilds[thisImprovement.Type] = thisImprovement.Type;	
		else
			validImprovementBuilds[thisImprovement.Type] = nil;	
		end
	end
	
end