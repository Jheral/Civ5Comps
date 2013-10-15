-- YieldHelpers
-- Author: Snarko
-- DateCreated: 9/18/2013 3:43:21 PM
--------------------------------------------------------------
-- Helper function to build yield tooltip string
function GetGenericYieldTooltip(iYieldType, iExtra)
	local iPlayerID = Game.GetActivePlayer();
	local pPlayer = Players[iPlayerID];

	strText = "";
	strColoredValue = "";
	strColorPositive = "[COLOR_POSITIVE]+"
	strColorNegative = "[COLOR:255:150:150:255]"

	-- Yield from cities EXCLUDING trade routes.
	-- Once traderoutes are remade include a text key for them here. Until then don't include traderoute yield here, because we want seperate text keys for it.
	local iYieldFromCities = pPlayer:GetYieldFromCitiesTimes100(iYieldType, true) / 100;
	if (iYieldFromCities ~= 0) then
		if (iYieldFromCities > 0) then strColoredValue = strColorPositive .. iYieldFromCities .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromCities .. "[ENDCOLOR]" end
		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_CITIES", strColoredValue);
	end

	local iYieldFromHappiness = pPlayer:GetYieldPerTurnFromExcessHappiness(iYieldType) + pPlayer:GetYieldFromHappinessTimes100(iYieldType) / 100;
	if (iYieldFromHappiness ~= 0) then
		if (iYieldFromHappiness > 0) then strColoredValue = strColorPositive .. iYieldFromHappiness .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromHappiness .. "[ENDCOLOR]" end
		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_HAPPINESS", strColoredValue);
	end

	local iYieldFromTraits = pPlayer:GetYieldFromTraits(iYieldType);
	if (iYieldFromTraits ~= 0) then
		if (iYieldFromTraits > 0) then strColoredValue = strColorPositive .. iYieldFromTraits .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromTraits .. "[ENDCOLOR]" end
		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_TRAITS", strColoredValue);
	end

	local iYieldFromCityConnections = pPlayer:GetCityConnectionYieldTimes100(iYieldType) / 100;
	if (iYieldFromCityConnections ~= 0) then
		if (iYieldFromCityConnections > 0) then strColoredValue = strColorPositive .. iYieldFromCityConnections .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromCityConnections .. "[ENDCOLOR]" end
		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_CITY_CONNECTIONS", strColoredValue);
	end

	-- EventEngine - v0.1, Snarko
	local iYieldFromEvents = pPlayer:GetYieldFromEvents(iYieldType);
	if (iYieldFromEvents ~= 0) then
		if (iYieldFromEvents > 0) then strColoredValue = strColorPositive .. iYieldFromEvents .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromEvents .. "[ENDCOLOR]" end
		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_EVENTS", strColoredValue);
	end
	-- END EventEngine

	local iYieldFromResolutions = pPlayer:GetYieldFromResolutions(iYieldType);
	if (iYieldFromResolutions ~= 0) then
		if (iYieldFromResolutions > 0) then strColoredValue = strColorPositive .. iYieldFromResolutions .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromResolutions .. "[ENDCOLOR]" end
		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_RESOLUTIONS", strColoredValue);
	end

	-- Religion can also give modifier, so we wait with adding the text.
	local iYieldFromReligion = pPlayer:GetYieldFromReligion(iYieldType);
	
	local iBase = iExtra + iYieldFromCities + iYieldFromHappiness + iYieldFromTraits + iYieldFromCityConnections + iYieldFromEvents + iYieldFromResolutions + iYieldFromReligion;

	if (iBase ~= 0) then
		local iYieldFromReligion = iYieldFromReligion + iBase * pPlayer:GetReligionYieldModifier(iYieldType) / 100;
		if (iYieldFromReligion ~= 0) then
			if (iYieldFromReligion > 0) then strColoredValue = strColorPositive .. iYieldFromReligion .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromReligion .. "[ENDCOLOR]" end
			strText = strText .. "[NEWLINE]";
			strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_RELIGION", strColoredValue);
		end

		local iYieldModFromLeague = iBase * pPlayer:GetYieldFromLeagueReward(iYieldType) / 100;
		if (iYieldModFromLeague ~= 0) then
			if (iYieldModFromLeague > 0) then strColoredValue = strColorPositive .. iYieldModFromLeague .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldModFromLeague .. "[ENDCOLOR]" end
			strText = strText .. "[NEWLINE]";
			strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_LEAGUE", strColoredValue);
		end

		local iYieldFromGoldenAge = iBase * GameInfo.Yields[iYieldType].GoldenAgePlayerYieldMod / 100;
		if (iYieldFromGoldenAge ~= 0 and pPlayer:IsGoldenAge() and not pPlayer:IsGoldenAgeCultureBonusDisabled()) then
			if (iYieldFromGoldenAge > 0) then strColoredValue = strColorPositive .. iYieldFromGoldenAge .. "[ENDCOLOR]" else strColoredValue = strColorNegative .. iYieldFromGoldenAge .. "[ENDCOLOR]" end
			strText = strText .. "[NEWLINE]";
			strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_YIELD_FROM_GOLDEN_AGE", strColoredValue);
		end
	end
	
	return strText;
end