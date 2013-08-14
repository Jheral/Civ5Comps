-- EventHistoryPopup
-- Author: Eric "Jheral" Lindroth
--------------------------------------------------------------

include( "IconSupport" );
include( "InstanceManager" );
include( "CommonBehaviors" );

local g_OptionIM = InstanceManager:new("EventOptionInstance", "EventOption", Controls.OptionStack);

local screenSizeX, screenSizeY = UIManager:GetScreenSizeVal();
local spWidth, spHeight = Controls.EventScrollPanel:GetSizeVal();
local mpWidth, mpHeight = Controls.MainPanel:GetSizeVal();

-- Original UI designed at 1050px
local heightOffset = screenSizeY - 1020;

spHeight = spHeight + heightOffset;
mpHeight = mpHeight + heightOffset;
Controls.EventScrollPanel:SetSizeVal(spWidth, spHeight); 
Controls.EventScrollPanel:CalculateInternalSize();
Controls.EventScrollPanel:ReprocessAnchoring();
Controls.MainPanel:SetSizeVal(mpWidth, mpHeight);
Controls.MainPanel:ReprocessAnchoring();

g_PlayerEventReference = nil;
g_CurrentEventType = nil;
g_CurrentOptions = {};
g_ActiveOption = nil;

-------------------------------------------------
-- Diplo Corner Hook ( Here for testing purposes, nothing more. Should be removed in final version )
-------------------------------------------------
function OnAdditionalInformationDropdownGatherEntries(additionalEntries)
        table.insert(additionalEntries, {
                text="Event Choice Popup",
                call=function() OnShow(); end
        });
end
LuaEvents.AdditionalInformationDropdownGatherEntries.Add(OnAdditionalInformationDropdownGatherEntries);
LuaEvents.RequestRefreshAdditionalInformationDropdownEntries();

-------------------------------------------------------------------------------
-- GetEventOptions(eEvent)
-------------------------------------------------------------------------------
function GetEventOptions(eEvent)
	local options = {};
	for eOption in GameInfo.Event_Options() do
		if eOption.EventType == eEvent.Type then
			table.insert(options, eOption);
		end
	end
	return options;
end

-------------------------------------------------------------------------------
-- On Show
-------------------------------------------------------------------------------
function OnPopupMessage(popupInfo)
    --If popup type isn't events, exit
    if popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_MODDER_0 then
        return;
    end
	--print(string.format("Popup is Event"));
    -- Only display popup if the ID is the active player.
    if( popupInfo.Data1 ~= Game.GetActivePlayer() ) then
        return;
    end
	--print(string.format("Player is the active player"));
	
	PopulateView(2);
    if( popupInfo.Data2 ~= nil ) then
		--print(string.format("The event has a real id"));
		--PopulateView(popupInfo.Data2);
	else
		--print(string.format("The event doesn't have a real id"));
    end
	
	OnShow();
end
Events.SerialEventGameMessagePopup.Add( OnPopupMessage );

-------------------------------------------------------------------------------
-- ShowHideHandler
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
	-- Set player icon at top of screen
	CivIconHookup( Game.GetActivePlayer(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );

    if( not bInitState ) then
        if( not bIsHide ) then
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_MODDER_0, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

-------------------------------------------------------------------------------
-- On Show
-------------------------------------------------------------------------------
function OnShow()
	PopulateView(2);
	UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy );
end

-------------------------------------------------------------------------------
-- On Close
-------------------------------------------------------------------------------
function OnClose()
	if g_ActiveOption ~= nil then
		g_ActiveOption.Button.EventOption:SetCheck(false);
		g_ActiveOption = nil;
	end
	g_PlayerEventReference = nil;
	g_CurrentEventType = nil;
	g_CurrentOptions = {};
    UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );

-------------------------------------------------------------------------------
-- On Accept
-------------------------------------------------------------------------------
function OnAccept()
	if g_ActiveOption == nil then return; end
	local pPlayer = Players[Game:GetActivePlayer()];
	--print(string.format("%s - %s: %s", g_ActiveOption.Key, g_ActiveOption.Option.ID, g_ActiveOption.Option.Type));
	OnClose();
	return;
end
Controls.AcceptButton:RegisterCallback( Mouse.eLClick, OnAccept );

-------------------------------------------------------------------------------
-- Input Handler
-------------------------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    ----------------------------------------------------------------        
    -- Key Down Processing
    ----------------------------------------------------------------        
    if uiMsg == KeyEvents.KeyDown then
        if		(wParam == Keys.VK_ESCAPE)	then OnClose();		return true;
		elseif	(wParam == Keys.VK_RETURN)	then OnAccept();	return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------
-- Populate View
-------------------------------------------------------------------------------
function PopulateView(iEventID)
	--print(string.format("Inside PopulateView"));
	g_OptionIM:ResetInstances();

	local pPlayer = Players[Game:GetActivePlayer()];
	local eEvent = GameInfo.Events[iEventID];

	if eEvent ~= nil then
		g_ActiveOption = nil;
		g_CurrentEventType = eEvent;
		local options = GetEventOptions(eEvent);
		Controls.AcceptButton:SetDisabled(true);
		--print(string.format("Before Title"));
		Controls.EventTitle:LocalizeAndSetText(eEvent.Description);

		--print(string.format("Before Pedia"));
		if eEvent.Civilopedia ~= nil then
			Controls.EventDescription:LocalizeAndSetText(eEvent.Civilopedia);
		else
			Controls.EventDescription:LocalizeAndSetText("No Event Text");
		end

		--print(string.format("Before Image"));
		if eEvent.Image ~= nil then
			--print(string.format("Image is not nil - %s", eEvent.Image));
			Controls.EventImage:SetTexture(eEvent.Image);
			if Controls.EventImage:IsHidden() then
				--print(string.format("Image is hiding - show!"));
				Controls.EventImage:SetHide(false);
			end
		else
			--print(string.format("Image is nil"));
			if (not Controls.EventImage:IsHidden()) then
				--print(string.format("Image is showing - hide!"));
				Controls.EventImage:SetHide(true);
			end
		end
		
		--print(string.format("Before Option Loop"));
		for key, eOption in pairs(options) do
			if eOption.EventType == eEvent.Type then
				g_CurrentOptions[key] = {Key=key,Option=eOption,Button=g_OptionIM:GetInstance()};
				BuildOptionRadio(g_CurrentOptions[key]);
				--print(string.format("%s",key));
				--print(string.format("Option added"));
			end
		end
	end
	--print(string.format("Event doesn't exist"));
end

-------------------------------------------------------------------------------
-- Set Active Option
-------------------------------------------------------------------------------
function SetActiveOption(key)
	if (key ~= nil and g_CurrentOptions[key] ~= nil) then
		if g_CurrentOptions[key].Button.EventOption:IsChecked() ~= true then
			g_CurrentOptions[key].Button.EventOption:SetCheck(true);
		end
		g_ActiveOption = g_CurrentOptions[key];
		Controls.AcceptButton:SetDisabled(false);
	end
end

-------------------------------------------------------------------------------
-- Build Option Radio
-------------------------------------------------------------------------------
function BuildOptionRadio(eOption)
	--print(string.format("%s", eOption.Key));
	local instance = eOption.Button;
	local option = eOption.Option;
	--print(string.format("Inside BuildOptionRadio"));
	instance.EventOption:GetTextButton():LocalizeAndSetText(option.Description);
	if option.bOverrideTooltip ~= 0 then
		--print(string.format("Tooltip Overridden"));
		if option.Help ~= nil then
			--print(string.format("Help String Exists"));
			instance.EventOption:SetToolTipString(Locale.ConvertTextKey(option.Help));
			else
			--print(string.format("No Help String"));
		end
	else
		--print(string.format("Normal Tooltip"));
		BuildOptionTooltip(eOption);
	end
	--print(string.format("Tooltip Set, move on to callback"));
	instance.EventOption:SetVoid1(eOption.Key);
	instance.EventOption:RegisterCallback(Mouse.eLClick, SetActiveOption );
	--print(string.format("Callback done"));
end

-------------------------------------------------------------------------------
-- Build Option Tooltip
-------------------------------------------------------------------------------
function BuildOptionTooltip(eOption)
	--print(string.format("Inside BuildOptionTooltip"));
	local strToolTipString = "Effects go here, in due time";
	strToolTipString = strToolTipString .. "[NEWLINE]----------------[NEWLINE]";
	strToolTipString = strToolTipString .. Locale.ConvertTextKey(eOption.Option.Help);
	eOption.Button.EventOption:SetToolTipString(strToolTipString);
end
ContextPtr:SetHide(true);