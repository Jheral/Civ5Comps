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

g_PlayerEventIndex = nil;
g_PlayerEvents = {};
g_CurrentEventType = nil;
g_CurrentOptions = {};
g_ActiveOption = nil;

-------------------------------------------------
-- Diplo Corner Hook ( Here for testing purposes, nothing more. Should be removed in final version )
-------------------------------------------------
function OnAdditionalInformationDropdownGatherEntries(additionalEntries)
        table.insert(additionalEntries, {
                text="Event Choice Popup",
                call=function() PopulateView(2); OnShow(); end
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
    if popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_EVENT then
        return;
    end
	print(string.format("Popup is Event"));
    -- Only display popup if the ID is the active player.
    if( popupInfo.Data1 ~= Game.GetActivePlayer() ) then
        return;
    end
	print(string.format("Player is the active player"));
	
    if( popupInfo.Data2 ~= nil ) then
		print(string.format("The event has a real id and Data3 is %s", popupInfo.Data3));
		g_PlayerEventIndex = popupInfo.Data3;
		PopulateView(popupInfo.Data2);
		if GameInfo.Events[popupInfo.Data2].bForcedImmediate then
			Controls.CloseButton:SetHide(true);
		else
			Controls.CloseButton:SetHide(false);
		end
	else
		print(string.format("The event doesn't have a real id"));
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
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_EVENT, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

-------------------------------------------------------------------------------
-- On Show
-------------------------------------------------------------------------------
function OnShow()
	UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy );
end

-------------------------------------------------------------------------------
-- On TestClose
-------------------------------------------------------------------------------
function OnTestClose()
	if g_CurrentEventType == nil or g_CurrentEventType.bForcedImmediate == false then
		OnClose();
	end
end
-------------------------------------------------------------------------------
-- On Close
-------------------------------------------------------------------------------
function OnClose()
	if g_ActiveOption ~= nil then
		g_ActiveOption.Button.EventOption:SetCheck(false);
		g_ActiveOption = nil;
	end
	g_PlayerEventIndex = nil;
	g_CurrentEventType = nil;
	g_CurrentOptions = {};
    UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnTestClose );

-------------------------------------------------------------------------------
-- On Accept
-------------------------------------------------------------------------------
function OnAccept()
	if g_ActiveOption == nil then return; end
	local pPlayer = Players[Game:GetActivePlayer()];
	print(string.format("%s - %s: %s", g_ActiveOption.Key, g_ActiveOption.Option.ID, g_ActiveOption.Option.Type));
	pPlayer:ProcessEventOptionByID(g_PlayerEventIndex, g_ActiveOption.Option.ID);
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
        if		(wParam == Keys.VK_ESCAPE)	then OnTestClose();		return true;
		elseif	(wParam == Keys.VK_RETURN)	then OnAccept();	return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------
-- Populate View
-------------------------------------------------------------------------------
function PopulateView(iEventID)
	print(string.format("Inside PopulateView"));
	g_OptionIM:ResetInstances();

	local pPlayer = Players[Game:GetActivePlayer()];
	local eEvent = GameInfo.Events[iEventID];
	
	PopulatePullDown(Controls.MultiPull);

	if eEvent ~= nil then
		g_ActiveOption = nil;
		g_CurrentEventType = eEvent;
		local options = GetEventOptions(eEvent);
		Controls.AcceptButton:SetDisabled(true);
		print(string.format("Before Title"));
		Controls.EventTitle:LocalizeAndSetText(eEvent.Description);

		print(string.format("Before Pedia"));
		if eEvent.Civilopedia ~= nil then
			Controls.EventDescription:LocalizeAndSetText(eEvent.Civilopedia);
		else
			Controls.EventDescription:LocalizeAndSetText("No Event Text");
		end

		print(string.format("Before Image"));
		if eEvent.Image ~= nil then
			print(string.format("Image is not nil - %s", eEvent.Image));
			Controls.EventImage:SetTexture(eEvent.Image);
			if Controls.EventImage:IsHidden() then
				print(string.format("Image is hiding - show!"));
				Controls.EventImage:SetHide(false);
			end
		else
			print(string.format("Image is nil"));
			if (not Controls.EventImage:IsHidden()) then
				print(string.format("Image is showing - hide!"));
				Controls.EventImage:SetHide(true);
			end
		end
		
		print(string.format("Before Option Loop"));
		for key, eOption in pairs(options) do
			if eOption.EventType == eEvent.Type then
				g_CurrentOptions[key] = {Key=key,Option=eOption,Button=g_OptionIM:GetInstance()};
				BuildOptionRadio(g_CurrentOptions[key]);
				print(string.format("%s",key));
				print(string.format("Option added"));
			end
		end
	end
	print(string.format("Event doesn't exist"));
end

-------------------------------------------------------------------------------
-- PopulatePullDown
-------------------------------------------------------------------------------
function PopulatePullDown(pullDown)
	pullDown:ClearEntries();
	local pPlayer = Players[Game:GetActivePlayer()];
	for event in pPlayer:Events() do
		local eEvent = GameInfo.Events[event:GetEventType()];
		local instance = {};
		pullDown:BuildEntry("InstanceOne", instance);
		instance.Button:SetText(Locale.ConvertTextKey(eEvent.Description));
		instance.Button:SetToolTipString(Locale.ConvertTextKey(eEvent.Civilopedia));
		instance.Button:SetVoids(event:GetID(), event:GetEventType());
	end
	pullDown:CalculateInternals();
	local dropDown = Controls.MultiPull;
	local width, height = dropDown:GetGrid():GetSizeVal();
	dropDown:GetGrid():SetSizeVal(width, height+100);
	pullDown:RegisterSelectionCallback(	function(eventIndex, iEventType) 
											g_PlayerEventIndex = eventIndex;
											PopulateView(iEventType); 
										end);
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
	print(string.format("%s", eOption.Key));
	local instance = eOption.Button;
	local option = eOption.Option;
	print(string.format("Inside BuildOptionRadio"));
	instance.EventOption:GetTextButton():LocalizeAndSetText(option.Description);
	if (option.bOverrideTooltip) then
		print(string.format("Tooltip Overridden"));
		if option.Help ~= nil then
			print(string.format("Help String Exists"));
			instance.EventOption:SetToolTipString(Locale.ConvertTextKey(option.Help));
			else
			print(string.format("No Help String"));
		end
	else
		print(string.format("Normal Tooltip"));
		BuildOptionTooltip(eOption);
	end
	print(string.format("Tooltip Set, move on to callback"));
	instance.EventOption:SetVoid1(eOption.Key);
	instance.EventOption:RegisterCallback(Mouse.eLClick, SetActiveOption );
	print(string.format("Callback done"));
end

-------------------------------------------------------------------------------
-- Build Option Tooltip
-------------------------------------------------------------------------------
function BuildOptionTooltip(eOption)
	print(string.format("Inside BuildOptionTooltip"));
	local strToolTipString = "";
	strToolTipString = strToolTipString .. "[NEWLINE]----------------[NEWLINE]";
	if (eOption.Option.Help ~= nil) then
		strToolTipString = strToolTipString .. Locale.ConvertTextKey(eOption.Option.Help);
	end
	local pPlayer = Players[Game:GetActivePlayer()];
	local pEvent = pPlayer:GetEvent(g_PlayerEventIndex);
	strToolTipString = strToolTipString .. pEvent:GetToolTipByOptionID(eOption.Option.ID);
	eOption.Button.EventOption:SetToolTipString(strToolTipString);
end
ContextPtr:SetHide(true);