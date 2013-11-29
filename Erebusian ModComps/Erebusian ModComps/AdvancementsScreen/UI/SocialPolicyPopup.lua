
include( "IconSupport" );
include( "InstanceManager" );
include( "CommonBehaviors" );
include( "FLuaVector" );
include( "TechButtonInclude" );

include( "AdvScreenTechHelp" );

local m_PopupInfo = nil;

local g_PolicyPipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.PolicyPanel );
local g_PolicyInstanceManager = InstanceManager:new( "PolicyButton", "PolicyIcon", Controls.PolicyPanel );

local g_BranchInstanceManager = InstanceManager:new( "BranchButtonInstance", "BranchButton", Controls.BranchStack );

local g_TabInstanceManager = InstanceManager:new( "TabButtonInstance", "TabButton", Controls.TabPanel );

local g_TechPipeManager = InstanceManager:new( "ConnectorPipe", "ConnectorImage", Controls.TreePanel );

local fullColor		= {x = 1, y = 1, z = 1, w = 1	};
local fadeColor		= {x = 1, y = 1, z = 1, w = 0	};
local fadeColorRV	= {x = 1, y = 1, z = 1, w = 0.2	};
local pinkColor		= {x = 2, y = 0, z = 2, w = 1	};

local lockTexture	= "48Lock.dds";
local checkTexture	= "48Checked.dds";

local hTexture = "Connect_H.dds";
local vTexture = "Connect_V.dds";

local topRightTexture		= "Connect_JonCurve_TopRight.dds";
local topLeftTexture		= "Connect_JonCurve_TopLeft.dds";
local bottomRightTexture	= "Connect_JonCurve_BottomRight.dds";
local bottomLeftTexture		= "Connect_JonCurve_BottomLeft.dds";

local g_PolicyXOffset = 28;
local g_PolicyYOffset = 68;

local g_PolicyPipeXOffset = 28;
local g_PolicyPipeYOffset = 68;

local g_TechXOffset = 80;
local g_TechYOffset = 70;

local g_TechPipeXOffset = 70;
local g_TechPipeYOffset = 80;

local m_gPolicyID;
local m_gAdoptingPolicy;

local bShowAllTenets = false;

local currentView = {
	["Class"] = nil,
	["Style"] = nil,
	["Branch"] = nil,
	["Type"] = nil,
};

tableTabs = {};
tableBranches = {};
tableTabButtons = {};
tableBranchButtons = {};
tablePolicies = {};

g_IdeologyBackgrounds = {
	-- Should this be dynamically generated?
	[0] = "PolicyBranch_Ideology.dds",
	POLICY_BRANCH_AUTOCRACY = "SocialPoliciesAutocracy.dds",
	POLICY_BRANCH_FREEDOM = "SocialPoliciesFreedom.dds",
	POLICY_BRANCH_ORDER = "SocialPoliciesOrder.dds",
};
----------------------------------------------------------------        
-- Key Down Processing
----------------------------------------------------------------    
function InputHandler( uiMsg, wParam, lParam )      
    if uiMsg == KeyEvents.KeyDown then
        if (wParam == Keys.VK_RETURN or wParam == Keys.VK_ESCAPE) then
			if Controls.PolicyConfirm:IsHidden() == false then
				Controls.PolicyConfirm:SetHide(true);
				Controls.BGBlock:SetHide(false);
			else
				OnClose();
			end
			return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------
-- On Close
-- Closes the Popup or the whole window
-------------------------------------------------
function OnClose()
    UIManager:DequeuePopup( ContextPtr );
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );

---------------------------------------------------
---- Diplo Corner Hook
---------------------------------------------------
--function OnAdditionalInformationDropdownGatherEntries(additionalEntries)
--        table.insert(additionalEntries, {
--                text=Locale.ConvertTextKey('TXT_KEY_ADVANCEMENTS_SCREEN'),
--                call=function() 
--					currentView = {["Class"]=nil,["Style"]=nil,["Branch"]=nil}; 
--					UpdateDisplay(); 
--					UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy ); 
--				end
--        });
--end
--LuaEvents.AdditionalInformationDropdownGatherEntries.Add(OnAdditionalInformationDropdownGatherEntries);
--LuaEvents.RequestRefreshAdditionalInformationDropdownEntries();

-------------------------------------------------
-- Confirmation Popup
-------------------------------------------------

function OnYes( )
	Controls.PolicyConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
	
	Network.SendUpdatePolicies(m_gPolicyID, m_gAdoptingPolicy, true);
	Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");
	UpdateDisplay();
end
Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );

function OnNo( )
	Controls.PolicyConfirm:SetHide(true);
	Controls.BGBlock:SetHide(false);
end
Controls.No:RegisterCallback( Mouse.eLClick, OnNo );

-------------------------------------------------
-- On Popup Message
-------------------------------------------------
function OnPopupMessage(popupInfo)
	local popupType = popupInfo.Type;
	if popupType ~= ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY then
		return;
	end
	
	m_PopupInfo = popupInfo;

	UpdateDisplay();
	
	if( m_PopupInfo.Data1 == 1 ) then
		if( ContextPtr:IsHidden() == false ) then
			OnClose();
		else
			UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
		end
	else
		UIManager:QueuePopup( ContextPtr, PopupPriority.SocialPolicy );
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopupMessage );

-------------------------------------------------
-- Switch Tabs
-------------------------------------------------
function SwitchTabs(iBranchClass, iType)
	for i, button in pairs(tableTabButtons) do
		if button.TabButtonHL	~= nil then button.TabButtonHL:SetHide(true);	end
	end
	local eBranchClass = tableTabs[iBranchClass];

	-- iType == 0 then TechTreeClass
	-- iType == 1 then PolicyBranchClass

	if iType == 0 then
		currentView.Type = "TECH";
		--print("Tech Type");
	elseif iType == 1 then
		currentView.Type = "POLICY";
		--print("Policy Type");
	end

	--print(string.format("%s: %s - %s", iBranchClass, eBranchClass.Type, eBranchClass.Style));
	
	currentView.Class = eBranchClass;
	tableTabButtons[eBranchClass.Type].TabButtonHL:SetHide(false);

	if eBranchClass.Style == "SOCIAL_POLICY" then
		currentView.Style = "SOCIAL_POLICY";
		currentView.Branch = nil;
		--print("Policy Style");
	elseif eBranchClass.Style == "IDEOLOGY" then
		currentView.Style = "IDEOLOGY";
		currentView.Branch = nil;
		--print("Ideology Style");
	elseif eBranchClass.Style == "TECH_TREE" then
		currentView.Style = "TECH_TREE";
		currentView.Branch = nil;
		--print("Tech Tree Style");
	else
		currentView = {["Class"]=nil,["Style"]=nil,["Branch"]=nil,["Type"]=nil};
		--print("Nothing Style");
	end
	UpdateDisplay();
end

-------------------------------------------------
-- Update Display
-------------------------------------------------
function UpdateDisplay()
    local pPlayer = Players[Game.GetActivePlayer()];
    if pPlayer == nil then
		return;
    end
	PopulateTabList();
	
	Controls.InfoLabel11:SetText("");
	Controls.InfoLabel12:SetText("");
	Controls.InfoLabel21:SetText("");
	Controls.InfoLabel22:SetText("");
	Controls.InfoLabel31:SetText("");
	Controls.InfoLabel32:SetText("");

    local pTeam = Teams[pPlayer:GetTeam()];
    local playerHas1City = pPlayer:GetNumCities() > 0;
    local bShowAll = OptionsManager.GetPolicyInfo();
	if currentView.Type == "TECH" then
		local eCurrentTech = GameInfo.Technologies[pPlayer:GetCurrentResearch()];
		if eCurrentTech ~= nil then
			local iProgress = pPlayer:GetResearchProgress(eCurrentTech.ID);
			local iTechCost = pPlayer:GetResearchCost(eCurrentTech.ID);
			Controls.InfoLabel12:LocalizeAndSetText("TXT_KEY_ADV_TECH_CURRENT_TECH", Locale.ConvertTextKey(eCurrentTech.Description), iProgress, iTechCost);
		else
			Controls.InfoLabel12:LocalizeAndSetText("TXT_KEY_ADV_TECH_CURRENT_TECH_NOTHING");
		end

		local iSciencePerTurn = pPlayer:GetScience();
		Controls.InfoLabel11:LocalizeAndSetText("TXT_KEY_ADV_TECH_PROGRESS_PER_TURN", iSciencePerTurn);
		if iSciencePerTurn > 0 and eCurrentTech ~= nil then
 			local iTurnsLeft = pPlayer:GetResearchTurnsLeft( eCurrentTech.ID, true );
			Controls.InfoLabel21:LocalizeAndSetText("TXT_KEY_ADV_TECH_TURNS_LEFT", Locale.ConvertTextKey("TXT_KEY_ADV_TECH_TURNS", iTurnsLeft));
		else
			Controls.InfoLabel21:LocalizeAndSetText("TXT_KEY_ADV_TECH_TURNS_LEFT", Locale.ConvertTextKey("TXT_KEY_ADV_TECH_NEVER"));
		end
		
		local iFreeTechs = pPlayer:GetNumFreeTechs();
		if iFreeTechs > 0 then
			Controls.InfoLabel31:SetText("[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_FREE_TECHS", iFreeTechs) .. "[ENDCOLOR]");
			Controls.InfoLabel21:LocalizeAndSetText("TXT_KEY_ADV_TECH_TURNS_LEFT", "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_NOW") .. "[ENDCOLOR]");
		else
			Controls.InfoLabel31:SetText();
		end

		Controls.InfoStack:ReprocessAnchoring();
		Controls.InfoStack2:ReprocessAnchoring();
		Controls.InfoStack3:ReprocessAnchoring();

		Controls.InfoStack:SetHide(false);
		Controls.InfoStack2:SetHide(false);
		Controls.InfoStack3:SetHide(false);
	elseif currentView.Type == "POLICY" then
		local iTurns;
		local iYieldNeeded = pPlayer:GetNextPolicyCost() - pPlayer:GetJONSCulture();
		if (iYieldNeeded <= 0) then
			iTurns = 0;
		else
			if (pPlayer:GetTotalJONSCulturePerTurn() == 0) then
				iTurns = "?";
			else
				iTurns = iYieldNeeded / pPlayer:GetTotalJONSCulturePerTurn();
				iTurns = iTurns + 1;
				iTurns = math.floor(iTurns);
			end
		end
		
		Controls.InfoLabel11:LocalizeAndSetText("TXT_KEY_CULTURE_PER_TURN_LABEL", pPlayer:GetTotalJONSCulturePerTurn());
		Controls.InfoLabel12:LocalizeAndSetText("TXT_KEY_CURRENT_CULTURE_LABEL", pPlayer:GetJONSCulture());
		Controls.InfoLabel21:LocalizeAndSetText("TXT_KEY_NEXT_POLICY_COST_LABEL", pPlayer:GetNextPolicyCost());
		Controls.InfoLabel22:LocalizeAndSetText("TXT_KEY_NEXT_POLICY_TURN_LABEL", iTurns);

		local iNumFreePolicies = pPlayer:GetNumFreePolicies();
		if (iNumFreePolicies > 0) then
			Controls.InfoLabel31:SetText("[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_ADV_TECH_FREE_TECHS", iNumFreePolicies) .. "[ENDCOLOR]");
		else
			Controls.InfoLabel31:SetText("");
		end
    
		Controls.InfoStack:ReprocessAnchoring();
		Controls.InfoStack2:ReprocessAnchoring();
		Controls.InfoStack3:ReprocessAnchoring();

		Controls.InfoStack:SetHide(false);
		Controls.InfoStack2:SetHide(false);
		Controls.InfoStack3:SetHide(false);
	else
		Controls.InfoStack:SetHide(true);
		Controls.InfoStack2:SetHide(true);
		Controls.InfoStack3:SetHide(true);
	end
	
	if currentView.Class ~= nil then
		Controls.TechStyle:SetHide(true);
		Controls.TenetStyle:SetHide(true);
		Controls.PolicyStyle:SetHide(true);
		--print(string.format("%s - %s", Locale.ConvertTextKey(currentView.Class.Description), currentView.Style));
		if currentView.Style == "IDEOLOGY" then
			Controls.TenetStyle:SetHide(false);
			PopulateIdeologyList(currentView.Class.Type);
			ViewIdeology(currentView.Branch);
		elseif currentView.Style == "SOCIAL_POLICY" then
			Controls.PolicyStyle:SetHide(false);
			PopulateBranchList(currentView.Class.Type);
			ViewPolicyBranch(currentView.Branch);
		elseif currentView.Style == "TECH_TREE" then
			Controls.TechStyle:SetHide(false);
			PopulateTechBranchList(currentView.Class.Type);
			ViewTechTree(currentView.Branch);
		end
	else
		Controls.TechStyle:SetHide(true);
		Controls.TenetStyle:SetHide(true);
		Controls.PolicyStyle:SetHide(true);
	end
end
Events.EventPoliciesDirty.Add( UpdateDisplay );
Events.SerialEventResearchDirty.Add( UpdateDisplay );

-------------------------------------------------
-- On Show All Tenets
-------------------------------------------------
function OnShowAllTenets(bIsChecked)
	if bIsChecked then bShowAllTenets = true; else bShowAllTenets = false; end
	UpdateDisplay();
end
Controls.ShowAllCheck:RegisterCheckHandler( OnShowAllTenets );

-------------------------------------------------
-- Find Policy By ID
-------------------------------------------------
function GetPolicyByID(iBranchID)
	local i = 0;
	local policyInfo = GameInfo.Policies[i];
	while policyInfo ~= nil do
		if policyInfo.ID == iBranchID then
			return policyInfo;
		end
		i = i + 1;
		policyInfo = GameInfo.Policies[i];
	end
	return nil;
end

-------------------------------------------------
-- Get Policies
-------------------------------------------------
function GetPolicies(eBranch)
	local policies = {};

	local i = 0;
	local policyInfo = GameInfo.Policies[i];
	while policyInfo ~= nil do
		if (policyInfo.PolicyBranchType == eBranch.Type) then
			policies[policyInfo.Type] = policyInfo;
			--print(string.format("%s - %s", policyInfo.ID, policyInfo.Type));
		end
		i = i + 1;
		policyInfo = GameInfo.Policies[i];
	end
	return policies;
end

-------------------------------------------------
-- Find Tech By ID
-------------------------------------------------
function GetTechByID(iTechID)
	local i = 0;
	local techInfo = GameInfo.Technologies[i];
	while techInfo ~= nil do
		if techInfo.ID == iTechID then
			return techInfo;
		end
		i = i + 1;
		techInfo = GameInfo.Technologies[i];
	end
	return nil;
end

-------------------------------------------------
-- Get Techs
-------------------------------------------------
function GetTechs(eBranch)
	local techs = {};

	local i = 0;
	local techInfo = GameInfo.Technologies[i];
	--print(techInfo ~= nil);
	while techInfo ~= nil do
		if (techInfo.TechTreeType == eBranch.Type) then
			techs[techInfo.Type] = techInfo;
		end
		i = i + 1;
		techInfo = GameInfo.Technologies[i];
	end
	return techs;
end

-------------------------------------------------
-- Build Policy Button
-- Builds the buttons for the policy branch's tree
-------------------------------------------------
function BuildPolicyButton(pPlayer, ePolicy, instance)
	local bIsAdopted = pPlayer:HasPolicy(ePolicy.ID);
	local bCanAdopt = pPlayer:CanAdoptPolicy(ePolicy.ID);
	local bUnlocked = pPlayer:CanAdoptPolicy(ePolicy.ID, true);
	local bBlocked = pPlayer:IsPolicyBlocked(i);

	local strTooltip = Locale.ConvertTextKey( ePolicy.Help );
	
    local playerHas1City = pPlayer:GetNumCities() > 0;
	
	local justLooking = true;
	if pPlayer:GetJONSCulture() >= pPlayer:GetNextPolicyCost() then
		justLooking = false;
	end

	-- If Player has adopted the policy
	if (bIsAdopted) then 
		instance.MouseOverContainer:SetHide( true );
		instance.PolicyIcon:SetDisabled( true );
		instance.PolicyImage:SetColor( fullColor );
		IconHookup( ePolicy.PortraitIndex, 64, ePolicy.IconAtlasAchieved, instance.PolicyImage );

	 -- if Player has no cities
	elseif (not playerHas1City) then
		instance.MouseOverContainer:SetHide( true );
		instance.PolicyIcon:SetDisabled( true );
		instance.PolicyImage:SetColor( fadeColorRV );
		IconHookup( ePolicy.PortraitIndex, 64, ePolicy.IconAtlas, instance.PolicyImage );
		-- Tooltip
		strTooltip = strTooltip .. "[NEWLINE][NEWLINE]"

	 -- if Player can Adopt the policy right now
	elseif (bCanAdopt) then
		instance.MouseOverContainer:SetHide( false );
		instance.PolicyIcon:SetDisabled( false );
		if justLooking then
			instance.PolicyImage:SetColor( fullColor );
		else
			instance.PolicyIcon:SetVoid1( i ); -- indicates policy to be chosen
			instance.PolicyImage:SetColor( fullColor );
		end
		IconHookup( ePolicy.PortraitIndex, 64, ePolicy.IconAtlas, instance.PolicyImage );
		
	-- if Player can Adopt the policy, but lacks culture
	elseif (bUnlocked) then
		instance.MouseOverContainer:SetHide( true );
		instance.PolicyIcon:SetDisabled( true );
		instance.PolicyImage:SetColor( fadeColorRV );
		IconHookup( ePolicy.PortraitIndex, 64, ePolicy.IconAtlas, instance.PolicyImage );
		-- Tooltip
		strTooltip = strTooltip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_CANNOT_UNLOCK_CULTURE", pPlayer:GetNextPolicyCost());
	else
		instance.MouseOverContainer:SetHide( true );
		instance.PolicyIcon:SetDisabled( true );
		instance.PolicyImage:SetColor( fadeColorRV );
		IconHookup( ePolicy.PortraitIndex, 64, ePolicy.IconAtlas, instance.PolicyImage );
		-- Tooltip
		strTooltip = strTooltip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_CANNOT_UNLOCK");
	end

	-- if Policy is Blocked by another Policy
	if pPlayer:IsPolicyBlocked(i) then
		instance.PolicyImage:SetColor( fadeColorRV );
		IconHookup( ePolicy.PortraitIndex, 64, ePolicy.IconAtlas, instance.PolicyImage );
				
		-- Update tooltip if we have this Policy
		if pPlayer:HasPolicy( i ) then
			strTooltip = strTooltip .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_POLICY_BRANCH_BLOCKED");
		end
	end
	instance.PolicyIcon:SetToolTipString( strTooltip );

	IconHookup(ePolicy.PortraitIndex, 64, ePolicy.IconAtlas, instance.PolicyImage);
	instance.PolicyIcon:SetOffsetVal((ePolicy.GridX-1)*g_PolicyXOffset+16,(ePolicy.GridY-1)*g_PolicyYOffset+12);
	instance.PolicyIcon:SetVoid1( ePolicy.ID );
	instance.PolicyIcon:RegisterCallback( Mouse.eLClick, PolicySelected );
end

-------------------------------------------------
-- Build Tenet
-- Builds the instances for the Tenet stacks
-------------------------------------------------
function BuildTenet(pPlayer, ePolicy, instance)
	if ePolicy ~= nil and instance ~= nil then
		local bIsAdopted = pPlayer:HasPolicy(ePolicy.ID);
		local bCanAdopt = pPlayer:CanAdoptPolicy(ePolicy.ID);
		
		if bIsAdopted then
			instance.Box:SetColor({x=0.24, y=0.48, z=0.24, w=0.5});
			instance.TenetButton:SetHide(false);
		elseif bCanAdopt then
			instance.TenetButton:SetHide(false);
			instance.TenetAdoptButton:SetHide(false);
			instance.TenetAdoptButton:SetToolTipString(Locale.ConvertTextKey(ePolicy.Help));
		elseif bShowAllTenets then
			instance.TenetButton:SetHide(false);
		else
			instance.TenetButton:SetHide(true);
			return false;
		end
		
		instance.TenetLabel:LocalizeAndSetText(ePolicy.Description);
		instance.TenetButton:SetToolTipString(Locale.ConvertTextKey(ePolicy.Help));
		instance.TenetAdoptButton:SetVoid1( ePolicy.ID );
		instance.TenetAdoptButton:RegisterCallback( Mouse.eLClick, PolicySelected );
		return true;
	else
		return false;
	end
end

-------------------------------------------------
-- Build Tech Button
-- Builds the buttons for the Tech branch's tree
-------------------------------------------------
function BuildTechButton(pPlayer, eTech, instance)
	local pTeam = Teams[pPlayer:GetTeam()];
	local bIsResearched = pTeam:GetTeamTechs():HasTech(eTech.ID);
	local bIsAvailable = pPlayer:CanResearch(eTech.ID);
	local bIsLocked = not pPlayer:CanEverResearch(eTech.ID);
	local bInProgress = pPlayer:GetCurrentResearch() == eTech.ID;
	local iFreeTechs = pPlayer:GetNumFreeTechs();
 	local iTurnsLeft = pPlayer:GetResearchTurnsLeft( eTech.ID, true );
	
	local queuePosition = pPlayer:GetQueuePosition( eTech.ID );
	if queuePosition == -1 then else
		instance.TechQueueLabel:SetText( tostring( queuePosition-1 ) );
		instance.TechQueue:SetHide( false );
	end

	if bIsLocked then
		instance.LabelBox:SetHide(false);
		instance.Label:LocalizeAndSetText("TXT_KEY_ADV_TECH_LOCKED");
		instance.Locked:SetHide(false);
	elseif bIsResearched then
		instance.Researched:SetHide(false);
	elseif not bIsAvailable then
		instance.Unavailable:SetHide(false);
	elseif bInProgress then
		instance.TechQueue:SetHide( true );
		if iFreeTechs > 0 then 
			instance.FreeTech:SetHide(false);
			instance.LabelBox:SetHide(false);
			instance.Label:LocalizeAndSetText("TXT_KEY_ADV_TECH_FREE_LABEL");
		else 
			instance.CurrentlyResearching:SetHide(false);
			instance.TurnsLeft:SetHide(false);
 			if pPlayer:GetScience() > 0 then
				instance.TurnsLeftLabel:SetText( iTurnsLeft );
  			else
				instance.TurnsLeftLabel:SetText( "-" );
  			end
		end
	elseif bIsAvailable then
		if iFreeTechs > 0 then 
			instance.FreeTech:SetHide(false);
			instance.LabelBox:SetHide(false);
			instance.Label:LocalizeAndSetText("TXT_KEY_ADV_TECH_FREE_LABEL");
		else 
			instance.Available:SetHide(false); 
		end
	else
		instance.Unavailable:SetHide(false);
	end
	
	IconHookup(eTech.PortraitIndex, 64, eTech.IconAtlas, instance.TechPortrait);
	instance.TechButton:SetOffsetVal((eTech.GridY+1)*g_TechYOffset-36,(eTech.GridX)*g_TechXOffset);
	instance.TechButton:SetToolTipString( AdvScreenTechHelp( eTech.ID ) );
	instance.TechButton:SetVoid1( eTech.ID );
	instance.TechButton:SetVoid2( iFreeTechs );
	techPediaSearchStrings[tostring(instance.TechButton)] = eTech.Description;
	instance.TechButton:RegisterCallback( Mouse.eLClick, TechSelected );
	instance.TechButton:RegisterCallback( Mouse.eRClick, GetTechPedia );
end

-------------------------------------------------
-- Build Pipe Paths
-- Builds the Pipe Connectors of the current tree,
-- indicating which policies require others
-------------------------------------------------
function BuildPipePaths( iBranchIndex )
	local eBranch = GetBranchByID(iBranchIndex);
	if eBranch == nil then
		--print("Branch Index Nil Value Error - BuildPipePaths");
		return;
	end
	if currentView.Type == "POLICY" then
		local PolicyTable = GetPolicies(eBranch);
		local PrereqsTable = {};
		local policyPipes = {};

		local cnxCenter = 1; 
		local cnxLeft = 2; 
		local cnxRight = 4;

		for i, row in pairs(PolicyTable) do
			policyPipes[row.Type] = 
			{
				upConnectionLeft = false;
				upConnectionRight = false;
				upConnectionCenter = false;
				upConnectionType = 0;
				downConnectionLeft = false;
				downConnectionRight = false;
				downConnectionCenter = false;
				downConnectionType = 0;
				yOffset = 0;
				policyType = row.Type;
			};
		end
	
		-- Get the prereqs that involve the policies in the active tree
		for row in GameInfo.Policy_PrereqPolicies() do
			local bValidType = false;
			local bValidPrereq = false;
			for _, policy in pairs(PolicyTable) do
				if row.PolicyType == policy.Type then
					bValidType = true;
				elseif row.PrereqPolicy == policy.Type then
					bValidPrereq = true;
				end		
			end
			if bValidPrereq and bValidType then
				table.insert(PrereqsTable, row);

			end
		end

		-- Evaluate all the pipe "bends" to make sure the right ones are being used
		for _, row in pairs(PrereqsTable) do
			local prereq = GameInfo.Policies[row.PrereqPolicy];
			local policy = GameInfo.Policies[row.PolicyType];
			if policy and prereq then
				if policy.GridX < prereq.GridX then
					policyPipes[policy.Type].upConnectionRight = true;
					policyPipes[prereq.Type].downConnectionLeft = true;
				elseif policy.GridX > prereq.GridX then
					policyPipes[policy.Type].upConnectionLeft = true;
					policyPipes[prereq.Type].downConnectionRight = true;
				else
					policyPipes[policy.Type].upConnectionCenter = true;
					policyPipes[prereq.Type].downConnectionCenter = true;
				end
				local yOffset = (policy.GridY - prereq.GridY) - 1;
				if yOffset > policyPipes[prereq.Type].yOffset then
					policyPipes[prereq.Type].yOffset = yOffset;
				end
			end
		end
	
		for pipeIndex, thisPipe in pairs(policyPipes) do
			if thisPipe.upConnectionLeft then thisPipe.upConnectionType = thisPipe.upConnectionType + cnxLeft; end 
			if thisPipe.upConnectionRight then thisPipe.upConnectionType = thisPipe.upConnectionType + cnxRight; end 
			if thisPipe.upConnectionCenter then thisPipe.upConnectionType = thisPipe.upConnectionType + cnxCenter; end 
			if thisPipe.downConnectionLeft then thisPipe.downConnectionType = thisPipe.downConnectionType + cnxLeft; end 
			if thisPipe.downConnectionRight then thisPipe.downConnectionType = thisPipe.downConnectionType + cnxRight; end 
			if thisPipe.downConnectionCenter then thisPipe.downConnectionType = thisPipe.downConnectionType + cnxCenter; end 
		end
	
		-- Draw the straight connecting pipes
		for _, prereq in pairs(PrereqsTable) do
			local currentPipe = policyPipes[prereq.PrereqPolicy];
			local currentPolicy = PolicyTable[prereq.PolicyType];
			local currentPrereq = PolicyTable[prereq.PrereqPolicy];

			if currentPolicy.GridY - currentPrereq.GridY > 1 or currentPolicy.GridY - currentPrereq.GridY < -1 then
				local xOffset = (currentPrereq.GridX-1)*g_PolicyPipeXOffset + 30;
				local pipe = g_PolicyPipeManager:GetInstance();
				local size = { x = 19; y = g_PolicyPipeYOffset*(currentPolicy.GridY - currentPrereq.GridY - 1); };
				pipe.ConnectorImage:SetOffsetVal(xOffset, (currentPrereq.GridY-1)*g_PolicyPipeYOffset + 58);
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe.ConnectorImage:SetSize(size);
			end

			--Generalize this like so?
			local distance = math.abs(currentPolicy.GridX - currentPrereq.GridX);
			local xOffset = 0;
			if currentPolicy.GridX - currentPrereq.GridX > 0 then
				xOffset = (currentPrereq.GridX-1)*g_PolicyPipeXOffset + 30;
			elseif currentPolicy.GridX - currentPrereq.GridX < 0 then
				xOffset = (currentPolicy.GridX-1)*g_PolicyPipeXOffset + 30;
			end
			local pipe = g_PolicyPipeManager:GetInstance();
			local sizeX = distance*20*(1 + (distance/20));
			local size = { x = sizeX; y = 19; };
			pipe.ConnectorImage:SetOffsetVal(xOffset + 16, (currentPrereq.GridY-1 + currentPipe.yOffset)*g_PolicyPipeYOffset + 58);
			pipe.ConnectorImage:SetTexture(hTexture);
			pipe.ConnectorImage:SetSize(size);
		end
	
		-- Draw the downward bend connecting pipes
		for pipeIndex, thisPipe in pairs(policyPipes) do
			local policy = GameInfo.Policies[thisPipe.policyType];
			local xOffset = (policy.GridX-1)*g_PolicyPipeXOffset + 30;
			if thisPipe.downConnectionType >= 1 then
			
				local startPipe = g_PolicyPipeManager:GetInstance();
				startPipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 48 );
				startPipe.ConnectorImage:SetTexture(vTexture);
			
				local pipe = g_PolicyPipeManager:GetInstance();			
				if thisPipe.downConnectionType == 1 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(vTexture);
				elseif thisPipe.downConnectionType == 2 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomRightTexture);
				elseif thisPipe.downConnectionType == 3 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(vTexture);
					pipe = g_PolicyPipeManager:GetInstance();			
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomRightTexture);
				elseif thisPipe.downConnectionType == 4 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomLeftTexture);
				elseif thisPipe.downConnectionType == 5 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(vTexture);
					pipe = g_PolicyPipeManager:GetInstance();			
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomLeftTexture);
				elseif thisPipe.downConnectionType == 6 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomRightTexture);
					pipe = g_PolicyPipeManager:GetInstance();		
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomLeftTexture);
				else
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(vTexture);
					pipe = g_PolicyPipeManager:GetInstance();		
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomRightTexture);
					pipe = g_PolicyPipeManager:GetInstance();
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1 + thisPipe.yOffset)*g_PolicyPipeYOffset + 58 );
					pipe.ConnectorImage:SetTexture(bottomLeftTexture);
				end
			end
		end

		-- Draw the upward bend connecting pipes
		for pipeIndex, thisPipe in pairs(policyPipes) do
			local policy = GameInfo.Policies[thisPipe.policyType];
			local xOffset = (policy.GridX-1)*g_PolicyPipeXOffset + 30;
		
			if thisPipe.upConnectionType >= 1 then
			
				local startPipe = g_PolicyPipeManager:GetInstance();
				startPipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset + 0 );
				startPipe.ConnectorImage:SetTexture(vTexture);
			
				local pipe = g_PolicyPipeManager:GetInstance();			
				if thisPipe.upConnectionType == 1 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(vTexture);
				elseif thisPipe.upConnectionType == 2 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topRightTexture);
				elseif thisPipe.upConnectionType == 3 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(vTexture);
					pipe = g_PolicyPipeManager:GetInstance();			
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topRightTexture);
				elseif thisPipe.upConnectionType == 4 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topLeftTexture);
				elseif thisPipe.upConnectionType == 5 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(vTexture);
					pipe = g_PolicyPipeManager:GetInstance();			
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topLeftTexture);
				elseif thisPipe.upConnectionType == 6 then
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topRightTexture);
					pipe = g_PolicyPipeManager:GetInstance();		
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topLeftTexture);
				else
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(vTexture);
					pipe = g_PolicyPipeManager:GetInstance();		
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topRightTexture);
					pipe = g_PolicyPipeManager:GetInstance();
					pipe.ConnectorImage:SetOffsetVal( xOffset, (policy.GridY-1)*g_PolicyPipeYOffset - 10 );
					pipe.ConnectorImage:SetTexture(topLeftTexture);
				end
			end
		end
	elseif currentView.Type == "TECH" then
		local TechTable = GetTechs(eBranch);
		local PrereqsTable = {};
		local pipes = {};

		local cnxCenter = 1; 
		local cnxLeft = 2; 
		local cnxRight = 4;
		
		-- Get the prereqs that involve the techs in the active tree
		for row in GameInfo.Technology_PrereqTechs() do
			local bValidType = false;
			local bValidPrereq = false;
			for _, tech in pairs(TechTable) do
				if row.TechType == tech.Type then
					bValidType = true;
				elseif row.PrereqTech == tech.Type then
					bValidPrereq = true;
				end
			end
			if bValidPrereq and bValidType then
				table.insert(PrereqsTable, row);
			end
		end
		
		for i, row in pairs(PrereqsTable) do
			pipes[row.PrereqTech.."->"..row.TechType] = 
			{
				BendConnectionType = 0;
				EndConnectionType = 0;
				yMidOffset = 0;
				TechType = row.TechType;
				PrereqTech = row.PrereqTech;
			};
		end
		
		-- Evaluate all the pipe "bends" to make sure the right ones are being used
		for _, row in pairs(pipes) do
			local prereq = GameInfo.Technologies[row.PrereqTech];
			local tech = GameInfo.Technologies[row.TechType];
			if tech and prereq then
				row.yMidOffset = (tech.GridX - prereq.GridX) ;
				if tech.GridY < prereq.GridY then
					row.BendConnectionType = cnxLeft;
					row.EndConnectionType = cnxRight;
				elseif tech.GridY > prereq.GridY then
					row.BendConnectionType = cnxRight;
					row.EndConnectionType = cnxLeft;
				else
					row.BendConnectionType = cnxCenter;
					row.EndConnectionType = cnxCenter;
				end
			end
		end
		
		-- Draw the straight connecting pipes
		for _, currentPipe in pairs(pipes) do
			local currentTech = TechTable[currentPipe.TechType];
			local currentPrereq = TechTable[currentPipe.PrereqTech];
			
			-- Vertical Pipes
			if currentTech.GridX - currentPrereq.GridX > 1 or currentTech.GridX - currentPrereq.GridX < -1 then
				local xOffset = (currentPrereq.GridY+1)*g_TechPipeXOffset - 10;
				local pipe = g_TechPipeManager:GetInstance();
				local size = { x = 19; y = g_TechPipeYOffset*(currentPipe.yMidOffset); };
				pipe.ConnectorImage:SetOffsetVal(xOffset, (currentPrereq.GridX)*g_TechPipeYOffset + 64);
				pipe.ConnectorImage:SetTexture(vTexture);
				pipe.ConnectorImage:SetSize(size);
			end
			
			-- Horizontal Pipes
			local distance = math.abs(currentTech.GridY - currentPrereq.GridY);
			local xOffset = 0;
			if currentTech.GridY - currentPrereq.GridY > 0 then
				xOffset = (currentPrereq.GridY+1)*g_TechPipeXOffset - 10;
			elseif currentTech.GridY - currentPrereq.GridY < 0 then
				xOffset = (currentTech.GridY+1)*g_TechPipeXOffset - 10;
			end
			local pipe = g_TechPipeManager:GetInstance();
			local sizeXMult = (g_TechPipeXOffset-8);
			local sizeX = distance*sizeXMult*(1 + (distance/sizeXMult));
			local size = { x = sizeX; y = 19; };
			pipe.ConnectorImage:SetOffsetVal(xOffset + 16, (currentPrereq.GridX + currentPipe.yMidOffset - 1)*g_TechPipeYOffset + 64);
			pipe.ConnectorImage:SetTexture(hTexture);
			pipe.ConnectorImage:SetSize(size);
		end

		-- Draw the bends of the pipes
		for pipeIndex, thisPipe in pairs(pipes) do
			local tech = GameInfo.Technologies[thisPipe.TechType];
			local prereq = GameInfo.Technologies[thisPipe.PrereqTech];
			local xOffset = (prereq.GridY+1)*g_TechPipeXOffset-10;
			local yMult = g_TechPipeYOffset;
			local yMod = 64;
			local yOffset = prereq.GridX * yMult + yMod;
			local yOffsetBend = (prereq.GridX + thisPipe.yMidOffset - 1) * yMult + yMod;
			local manager = g_TechPipeManager;
			if thisPipe.BendConnectionType ~= 0 then
				local pipe = manager:GetInstance();			
				pipe.ConnectorImage:SetOffsetVal( xOffset, yOffsetBend);
	
				if thisPipe.BendConnectionType == cnxCenter then
					pipe.ConnectorImage:SetTexture(vTexture);
				elseif thisPipe.BendConnectionType == cnxLeft then
					pipe.ConnectorImage:SetTexture(bottomRightTexture);
				elseif thisPipe.BendConnectionType == cnxRight then
					pipe.ConnectorImage:SetTexture(bottomLeftTexture);
				end
			end
		end
		
		-- Draw the endpoints of the pipes
		for pipeIndex, thisPipe in pairs(pipes) do
			local tech = GameInfo.Technologies[thisPipe.TechType];
			local xOffset = (tech.GridY+1)*g_TechPipeXOffset-10;
			local yMult = g_TechPipeYOffset;
			local yMod = -16;
			local yOffset = tech.GridX * yMult + yMod;
			local manager = g_TechPipeManager;
			if thisPipe.EndConnectionType ~= 0 then
			
				local pipe = manager:GetInstance();			
				pipe.ConnectorImage:SetOffsetVal( xOffset, yOffset);

				if thisPipe.EndConnectionType == cnxCenter then
					pipe.ConnectorImage:SetTexture(vTexture);
				elseif thisPipe.EndConnectionType == cnxLeft then
					pipe.ConnectorImage:SetTexture(topRightTexture);
				elseif thisPipe.EndConnectionType == cnxRight then
					pipe.ConnectorImage:SetTexture(topLeftTexture);
				end
			end
		end

	end
end

-------------------------------------------------
-- Policy Selected
-- When a policy is elected in the tree, this is run.
-------------------------------------------------
function PolicySelected( iPolicyIndex )
	local ePolicy = GetPolicyByID(iPolicyIndex);
	if ePolicy ~= nil then
		--print(string.format("Policy Selected : %s", Locale.ConvertTextKey(ePolicy.Description)));
		local pPlayer = Players[Game.GetActivePlayer()];
		if pPlayer == nil then
			return;
		end

		local bHasPolicy = pPlayer:HasPolicy(ePolicy.ID);
		local bCanAdoptPolicy = pPlayer:CanAdoptPolicy(ePolicy.ID);
		local bPolicyBlocked = pPlayer:IsPolicyBlocked(ePolicy.ID);
		
		if (bHasPolicy or bCanAdoptPolicy) then
			if (bPolicyBlocked) then
				local strPolicyBranch = GameInfo.Policies[ePolicy.ID].PolicyBranchType;
				local iPolicyBranch = GameInfoTypes[strPolicyBranch];
			
				local popupInfo = {
					Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_POLICY_BRANCH_SWITCH,
					Data1 = iPolicyBranch;
				}
				Events.SerialEventGameMessagePopup(popupInfo);
			end
		end 

		if (bCanAdoptPolicy and not bPolicyBlocked) then
			m_gPolicyID = ePolicy.ID;
			m_gAdoptingPolicy = true;
			Controls.PolicyConfirm:SetHide(false);
			Controls.BGBlock:SetHide(true);
		end
	end
end

-------------------------------------------------
-- Tech Selected
-- When a policy is elected in the tree, this is run.
-------------------------------------------------
function TechSelected( iTechID )
	local pPlayer = Players[Game.GetActivePlayer()];
	if pPlayer == nil then
		return;
	end
	if iTechID > -1 then
   		Network.SendResearch(iTechID, pPlayer:GetNumFreeTechs(), -1, UIManager:GetShift());
   	end
end

-------------------------------------------------
-- Policy Branch Selected
-- When a policy branch's Adopt button is clicked, this is run.
-------------------------------------------------
function PolicyBranchSelected( iBranchIndex )
	local eBranch = GetBranchByID(iBranchIndex);
	if eBranch ~= nil then
		--print(string.format("Branch Selected : %s", Locale.ConvertTextKey(eBranch.Description)));
		local pPlayer = Players[Game.GetActivePlayer()];
		if pPlayer == nil then
			return;
		end

		local bHasPolicyBranch = pPlayer:IsPolicyBranchUnlocked(eBranch.ID);
		local bCanAdoptPolicyBranch = pPlayer:CanUnlockPolicyBranch(eBranch.ID);
		local bUnblockingPolicyBranch = pPlayer:IsPolicyBranchBlocked(eBranch.ID);
		
		if (bHasPolicyBranch or bCanAdoptPolicyBranch) then
			if (bUnblockingPolicyBranch) then
				local popupInfo = {
					Type = ButtonPopupTypes.BUTTONPOPUP_CONFIRM_POLICY_BRANCH_SWITCH,
					Data1 = iPolicyBranch;
				}
				Events.SerialEventGameMessagePopup(popupInfo);
			end
		end 

		if (bCanAdoptPolicyBranch and not bUnblockingPolicyBranch) then
			m_gPolicyID = eBranch.ID;
			m_gAdoptingPolicy = false;
			Controls.PolicyConfirm:SetHide(false);
			Controls.BGBlock:SetHide(true);
		end
	end
end

-------------------------------------------------
-- Find Branch By ID
-------------------------------------------------
function GetBranchByID(iBranchID)
	local i = 0;
	if currentView.Type == "TECH" then
		local branchInfo = GameInfo.TechTreeTypes[i];
		while branchInfo ~= nil do
			if branchInfo.ID == iBranchID then
				return branchInfo;
			end
			i = i + 1;
			branchInfo = GameInfo.TechTreeTypes[i];
		end
	elseif currentView.Type == "POLICY" then
		local branchInfo = GameInfo.PolicyBranchTypes[i];
		while branchInfo ~= nil do
			if branchInfo.ID == iBranchID then
				return branchInfo;
			end
			i = i + 1;
			branchInfo = GameInfo.PolicyBranchTypes[i];
		end
	end
	return nil;
end

-------------------------------------------------
-- Get Branches
-------------------------------------------------
function GetBranches(sBranchType)
	local branches = {};
	local i = 0;

	if currentView.Type == "TECH" then
		local branchInfo = GameInfo.TechTreeTypes[i];
		--print(branchInfo ~= nil);
		while branchInfo ~= nil do
			if branchInfo.BranchClass == sBranchType then
				--print(branchInfo.Type);
				local count = tableLength(GetTechs(branchInfo));
				if (count > 0) then
					table.insert(branches, branchInfo);
				end
			end
			i = i + 1;
			branchInfo = GameInfo.TechTreeTypes[i];
		end
	elseif currentView.Type == "POLICY" then
		local branchInfo = GameInfo.PolicyBranchTypes[i];
		while branchInfo ~= nil do
			if branchInfo.PolicyBranchClass == sBranchType then
				local count = tableLength(GetPolicies(branchInfo));
				if (count > 0) then
					table.insert(branches, branchInfo);
				end
			end
			i = i + 1;
			branchInfo = GameInfo.PolicyBranchTypes[i];
		end
	end
	return branches;
end

-------------------------------------------------
-- Build Branch Button
-- Builds the buttons for the branch list
-------------------------------------------------
function BuildBranchButton(pPlayer, eBranch, instance)
	local bBranchUnlocked	 = pPlayer:IsPolicyBranchUnlocked(eBranch.ID);
	local bBranchBlocked	 = pPlayer:IsPolicyBranchBlocked(eBranch.ID);
	local bBranchFinished	 = pPlayer:IsPolicyBranchFinished(eBranch.ID);
	local bBranchCanAdopt	 = pPlayer:CanUnlockPolicyBranch(eBranch.ID);
	--print(string.format("%s - %s", eBranch.Type,tableLength(GetPolicies(eBranch))));
	if (bBranchUnlocked) then
		instance.PolicyCountLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_POLICY_COUNT_ADOPTED",pPlayer:GetNumPoliciesInBranch(eBranch.ID), tableLength(GetPolicies(eBranch)));
		if (bBranchFinished) then
			instance.BranchStatusLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_COMPLETED");
		else
			instance.BranchStatusLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_ADOPTED");
		end
	else
		instance.PolicyCountLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_POLICY_COUNT_NOT_ADOPTED", tableLength(GetPolicies(eBranch)));
		if (bBranchBlocked) then
			instance.BranchStatusLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_BLOCKED");
		elseif (bBranchCanAdopt) then
			instance.BranchStatusLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_NOT_ADOPTED");
		else
			if eBranch.EraPrereq ~= nil then
				instance.BranchStatusLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_ERA_REQUIRED", GameInfo.Eras[GameInfoTypes[eBranch.EraPrereq]].Description);
			else
				instance.BranchStatusLabel:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_NOT_ADOPTED");
			end
		end
	end
	instance.BranchLabel:LocalizeAndSetText(eBranch.Description);
    instance.BranchButton:SetVoid1( eBranch.ID );
	instance.BranchButton:RegisterCallback( Mouse.eLClick, UpdateBranchView );
	--print("test:%s", instance.BranchLabel:GetText());
end

-------------------------------------------------
-- Build Tech Branch Button
-- Builds the buttons for the branch list
-------------------------------------------------
function BuildTechBranchButton(pPlayer, eBranch, instance)
	instance.BranchLabel:LocalizeAndSetText(eBranch.Description);
    instance.BranchButton:SetVoid1( eBranch.ID );
	instance.BranchButton:RegisterCallback( Mouse.eLClick, UpdateBranchView );
end

-------------------------------------------------
-- Build Ideology Button
-- Builds the buttons for the ideology list
-------------------------------------------------
function BuildIdeologyButton(pPlayer, eBranch, instance)
	local pPlayer = Players[Game.GetActivePlayer()];
    instance.IdeologyButton:SetVoid1( eBranch.ID );
	instance.IdeologyButton:RegisterCallback( Mouse.eLClick, UpdateBranchView );
	if pPlayer:IsPolicyBranchUnlocked(eBranch.ID) then
		instance.IdeologyLabel:SetText(string.format("[COLOR_POSITIVE_TEXT]%s[ENDCOLOR]",Locale.ConvertTextKey(eBranch.Description)));
		if currentView.Branch == nil then currentView.Branch = eBranch; end
	else
		instance.IdeologyLabel:LocalizeAndSetText(eBranch.Description);
	end
	--print("test:%s", instance.BranchLabel:GetText());
end

-------------------------------------------------
-- UpdateBranchView
-- Sets the branch/ideology to be show, and calls the update routine
-------------------------------------------------
function UpdateBranchView( iBranchIndex )
	local eBranch = GetBranchByID(iBranchIndex);
	if eBranch ~= nil then
		local eClass;
		if currentView.Type == "TECH" then
			eClass = GameInfo.TechTreeClassTypes[GameInfoTypes[eBranch.BranchClass]];
		elseif currentView.Type == "POLICY" then
			eClass = GameInfo.PolicyBranchClassTypes[GameInfoTypes[eBranch.PolicyBranchClass]];
		end
		sStyle = eClass.Style;
		sType = currentView.Type;
		currentView = {["Class"] = eClass,["Style"] = sStyle,["Branch"] = eBranch,["Type"] = sType,};
		--print(string.format("Next View - %s - %s - %s",currentView.Class.Description,currentView.Style,currentView.Branch.Description));
	end
	UpdateDisplay();
end

-------------------------------------------------
-- View Policy Branch
-- When a policy branch is selected in the left sidebar, this is run.
-- All policies belonging to that specific branch are loaded, so that
-- the tree for that branch can be built.
-------------------------------------------------
function ViewPolicyBranch( eBranch )
	Controls.PolicyPanel:DestroyAllChildren();
	if eBranch ~= nil then
		currentView.Branch = eBranch;
		
		local pPlayer = Players[Game.GetActivePlayer()];
		local pTeam = Teams[pPlayer:GetTeam()];
		local policies = GetPolicies(eBranch);
		
		local bBranchUnlocked	 = pPlayer:IsPolicyBranchUnlocked(eBranch.ID);
		local bBranchFinished	 = pPlayer:IsPolicyBranchFinished(eBranch.ID);
		local bBranchBlocked	 = pPlayer:IsPolicyBranchBlocked(eBranch.ID);
		local bBranchCanAdopt	 = pPlayer:CanUnlockPolicyBranch(eBranch.ID);

		tableBranchButtons[eBranch.Type].BranchButtonHL:SetHide(false);

		Controls.TreePanelLabel:LocalizeAndSetText(eBranch.Description);
		Controls.AdoptBranchButton:SetToolTipString(Locale.ConvertTextKey(eBranch.Help));
		Controls.BranchImage:SetToolTipString(Locale.ConvertTextKey(eBranch.Help));
		Controls.AdoptBranchButton:SetVoid1( eBranch.ID );
		Controls.AdoptBranchButton:RegisterCallback( Mouse.eLClick, PolicyBranchSelected );
		
   		CivIconHookup( pPlayer:GetID(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
		Controls.BranchImage:SetTexture( eBranch.PolicyBranchImage );

		local iEraPrereq = GameInfoTypes[eBranch.EraPrereq]
		local bEraLock = false;
		if (iEraPrereq ~= nil and pTeam:GetCurrentEra() < iEraPrereq) then
			bEraLock = true;
		end
		
		Controls.AdoptBranchButton:SetDisabled(false);
		Controls.AdoptBranchButton:SetHide(false);
		Controls.BranchImageFade:SetHide(false);
		Controls.Lock:SetHide(false);

		if bEraLock then
			Controls.AdoptBranchButton:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_ERA_REQUIRED", GameInfo.Eras[GameInfoTypes[eBranch.EraPrereq]].Description);
			Controls.AdoptBranchButton:SetDisabled(true);
		else
			if bBranchUnlocked then
				Controls.AdoptBranchButton:SetHide(true);
				Controls.BranchImageFade:SetHide(true);
			else
				if bBranchBlocked then
					Controls.AdoptBranchButton:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_ADOPT_BLOCKED");
				elseif bBranchCanAdopt then
					Controls.AdoptBranchButton:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_ADOPT");
					Controls.Lock:SetHide(true);
				else
					Controls.AdoptBranchButton:LocalizeAndSetText("TXT_KEY_POLICYBRANCH_ADOPT");
					Controls.AdoptBranchButton:SetDisabled(true);
				end
			end
		end
		
		BuildPipePaths( eBranch.ID );
		for i, ePolicy in pairs(policies) do
			local instance = {};
			ContextPtr:BuildInstanceForControl("PolicyButton", instance, Controls.PolicyPanel);
			BuildPolicyButton(pPlayer, ePolicy, instance);
		end
		Controls.PolicyTreePanel:SetHide(false);
	else
		Controls.PolicyTreePanel:SetHide(true);
	end
end

-------------------------------------------------
-- View Ideology
-- Shows the Ideology's tenets in the right-hand area of the popup
-------------------------------------------------
function ViewIdeology( eBranch )
	Controls.TenetWrapper:DestroyAllChildren();
	if eBranch ~= nil then
		tableBranchButtons = {};
		currentView.Branch = eBranch;

		local pPlayer = Players[Game.GetActivePlayer()];

		local pTeam = Teams[pPlayer:GetTeam()];
		local policies = GetPolicies(eBranch);
		local tableTenets = {};
		local topTier = 0;
		
   		CivIconHookup( pPlayer:GetID(), 64, Controls.TenetCivIcon, Controls.TenetCivIconBG, Controls.TenetCivIconShadow, false, true );
		Controls.IdeologyImage:SetTexture( eBranch.PolicyBranchImage );

		for i, tenet in pairs(policies) do 
			if tenet.Level > topTier then topTier = tenet.Level; end 
			if tableTenets[tenet.Level] == nil then
				tableTenets[tenet.Level] = {};
			end
			table.insert(tableTenets[tenet.Level], tenet);
		end

		if topTier > 0 then
			for i = 1, topTier do
				local stackInstance = {};
				ContextPtr:BuildInstanceForControl("TenetStackInstance", stackInstance, Controls.TenetWrapper);
				stackInstance.TenetStackLabel:LocalizeAndSetText("TXT_KEY_TENETSTACK_LABEL", i);
				local tenetIM = InstanceManager:new("TenetInstance", "TenetButton", stackInstance.TenetStack);
				local tenetCount = 0;
				if tableTenets[i] ~= nil then
					for j, tenet in pairs(tableTenets[i]) do
						local tenetInstance = tenetIM:GetInstance();
						local bAdded = BuildTenet(pPlayer, tenet, tenetInstance);
						if bAdded then tenetCount = tenetCount + 1; end
					end
				end
				stackInstance.TenetStack:CalculateSize();
				stackInstance.TenetStack:ReprocessAnchoring();
				stackInstance.StackPanel:SetSizeY( (tenetCount*24) + 57);
				stackInstance.StackPanel:CalculateInternalSize();
			end
			Controls.TenetTreePanel:SetHide(false);
		end

		if pPlayer:IsPolicyBranchUnlocked(eBranch.ID) then
			local szOpinionString;
			local iOpinion = pPlayer:GetPublicOpinionType();
			if (iOpinion == PublicOpinionTypes.PUBLIC_OPINION_DISSIDENTS) then
				szOpinionString = Locale.ConvertTextKey("TXT_KEY_CO_PUBLIC_OPINION_DISSIDENTS");
			elseif (iOpinion == PublicOpinionTypes.PUBLIC_OPINION_CIVIL_RESISTANCE) then
				szOpinionString = Locale.ConvertTextKey("TXT_KEY_CO_PUBLIC_OPINION_CIVIL_RESISTANCE");
			elseif (iOpinion == PublicOpinionTypes.PUBLIC_OPINION_REVOLUTIONARY_WAVE) then
				szOpinionString = Locale.ConvertTextKey("TXT_KEY_CO_PUBLIC_OPINION_REVOLUTIONARY_WAVE");
			else
				szOpinionString = Locale.ConvertTextKey("TXT_KEY_CO_PUBLIC_OPINION_CONTENT");
			end
			Controls.PublicOpinion:SetText(szOpinionString);
			Controls.PublicOpinion:SetToolTipString(pPlayer:GetPublicOpinionTooltip());
			
			local iUnhappiness = -1 * pPlayer:GetPublicOpinionUnhappiness();
			local strPublicOpinionUnhappiness = tostring(0);
			local strChangeIdeologyTooltip = "";
			if (iUnhappiness < 0) then
				strPublicOpinionUnhappiness = Locale.ConvertTextKey("TXT_KEY_CO_PUBLIC_OPINION_UNHAPPINESS", iUnhappiness);
				Controls.SwitchIdeologyButton:SetDisabled(false);	
				local ePreferredIdeology = pPlayer:GetPublicOpinionPreferredIdeology();
				local strPreferredIdeology = GameInfo.PolicyBranchTypes[ePreferredIdeology].Description;
				strChangeIdeologyTooltip = Locale.ConvertTextKey("TXT_KEY_POLICYSCREEN_CHANGE_IDEOLOGY_TT", strPreferredIdeology, (-1 * iUnhappiness), 2);
		    
				Controls.SwitchIdeologyButton:RegisterCallback(Mouse.eLClick, function()
						ChooseChangeIdeology();
				end);
			else
				Controls.SwitchIdeologyButton:SetDisabled(true);	
				strChangeIdeologyTooltip = Locale.ConvertTextKey("TXT_KEY_POLICYSCREEN_CHANGE_IDEOLOGY_DISABLED_TT");
			end
			Controls.PublicOpinionUnhappiness:SetText(strPublicOpinionUnhappiness);
			Controls.PublicOpinionUnhappiness:SetToolTipString(pPlayer:GetPublicOpinionUnhappinessTooltip());
			Controls.SwitchIdeologyButton:SetToolTipString(strChangeIdeologyTooltip);

			Controls.PublicOpinionPanel:SetHide(false);
		else
			Controls.PublicOpinionPanel:SetHide(true);
		end

		Controls.TenetWrapper:CalculateSize();
		Controls.TenetWrapper:ReprocessAnchoring();
		Controls.TenetScrollPanel:CalculateInternalSize();
		Controls.TenetTreePanel:SetHide(false);
	else
		Controls.TenetTreePanel:SetHide(true);
	end
end

-------------------------------------------------
-- View Tech Tree
-- Shows the Tech Tree's techs in the right-hand area of the popup
-------------------------------------------------
function ViewTechTree( eBranch )
	Controls.TreePanel:DestroyAllChildren();
	if eBranch ~= nil then
		currentView.Branch = eBranch;
		
		local pPlayer = Players[Game.GetActivePlayer()];
		local pTeam = Teams[pPlayer:GetTeam()];
		local techs = GetTechs( eBranch );
		
		GatherInfoAboutUniqueStuff(GameInfo.Civilizations[pPlayer:GetCivilizationType()].Type);

		Controls.TreePanelLabel:LocalizeAndSetText(eBranch.Description);
		tableBranchButtons[eBranch.Type].BranchButtonHL:SetHide(false);
		
		if eBranch.BranchImage ~= nil then
   			CivIconHookup( pPlayer:GetID(), 64, Controls.TenetCivIcon, Controls.TenetCivIconBG, Controls.TenetCivIconShadow, false, true );
			Controls.TechBranchImage:SetTexture( eBranch.BranchImage );
			Controls.TechBranchImage:SetHide(false);
			Controls.BranchImageFade:SetHide(false);
		else
			Controls.BranchImageFade:SetHide(true);
			Controls.TechBranchImage:SetHide(true);
		end
		local SizeX = 0;
		BuildPipePaths( eBranch.ID );
		for i, eTech in pairs(techs) do
			local instance = {};
			ContextPtr:BuildInstanceForControl("TechButtonInstance", instance, Controls.TreePanel);
			BuildTechButton(pPlayer, eTech, instance);
			if eTech.GridX > SizeX then SizeX = eTech.GridX; end
		end
		Controls.TreePanel:SetSizeY((SizeX+2)*80);
		Controls.TreePanel:ReprocessAnchoring();
		Controls.TreeWrapper:CalculateSize();
		Controls.TreeWrapper:ReprocessAnchoring();
		Controls.TreeScrollPanel:CalculateInternalSize();
		Controls.TreeScrollPanel:ReprocessAnchoring();
		Controls.TechTreePanel:SetHide(false);
	else
		Controls.TechTreePanel:SetHide(true);
	end
end

-------------------------------------------------
-- Build Policy Class Tab Button
-------------------------------------------------
function BuildTabButton(pPlayer, eTabClass, instance, type, tabID)
	local typeInt;
	if type == "TECH" then typeInt = 0;
	elseif type == "POLICY" then typeInt = 1;
	end
	instance.TabButton:LocalizeAndSetText( eTabClass.Description );
    instance.TabButton:SetVoids( tabID, typeInt );
	instance.TabButton:RegisterCallback( Mouse.eLClick, SwitchTabs );
end

-------------------------------------------------
-- Populate Tech Branch List
-------------------------------------------------
function PopulateTechBranchList(sBranchClass)
	Controls.TechBranchStack:DestroyAllChildren();
	local pPlayer = Players[Game.GetActivePlayer()];
	if pPlayer == nil then return;
	else
		local branchList = GetBranches(sBranchClass);
		--print("Tech Branches for " .. sBranchClass .. ": " .. tableLength(branchList));
		for i, eBranch in pairs(branchList) do
			local instance = {};
			--print("Tech Branch Button - eBranch.Type");
			ContextPtr:BuildInstanceForControl("TechBranchButtonInstance", instance, Controls.TechBranchStack);
			BuildTechBranchButton(pPlayer, eBranch, instance);
			tableBranchButtons[eBranch.Type] = instance;
		end
	end
	Controls.BranchStack:SetHide(false);
	Controls.BranchStack:CalculateSize();
    Controls.BranchStack:ReprocessAnchoring();
    Controls.BranchListScrollPanel:CalculateInternalSize();
end

-------------------------------------------------
-- Populate Branch List
-------------------------------------------------
function PopulateBranchList(sBranchClass)
	Controls.BranchStack:DestroyAllChildren();
	local pPlayer = Players[Game.GetActivePlayer()];
	if pPlayer == nil then return;
	else
		local branchList = GetBranches(sBranchClass);
		for i, eBranch in pairs(branchList) do
			local instance = {};
			ContextPtr:BuildInstanceForControl("BranchButtonInstance", instance, Controls.BranchStack);
			BuildBranchButton(pPlayer, eBranch, instance);
			tableBranchButtons[eBranch.Type] = instance;
		end
	end
	Controls.BranchStack:SetHide(false);
	Controls.BranchStack:CalculateSize();
    Controls.BranchStack:ReprocessAnchoring();
    Controls.BranchListScrollPanel:CalculateInternalSize();
end

-------------------------------------------------
-- Populate Ideology List
-------------------------------------------------
function PopulateIdeologyList(sBranchClass)
	Controls.IdeologyStack:DestroyAllChildren();
	local pPlayer = Players[Game.GetActivePlayer()];
	if pPlayer == nil then return;
	else
		local branchList = GetBranches(sBranchClass);
		for i, eBranch in pairs(branchList) do
			local instance = {};
			ContextPtr:BuildInstanceForControl("IdeologyButtonInstance", instance, Controls.IdeologyStack);
			BuildIdeologyButton(pPlayer, eBranch, instance);
			tableBranchButtons[eBranch.Type] = instance;
		end
	end
	Controls.IdeologyStack:SetHide(false);
	Controls.IdeologyStack:CalculateSize();
    Controls.IdeologyStack:ReprocessAnchoring();
    Controls.IdeologyListScrollPanel:CalculateInternalSize();
end

-------------------------------------------------
-- Populate Tab List
-------------------------------------------------
function PopulateTabList()
	Controls.TabStack:DestroyAllChildren();
	local pPlayer = Players[Game.GetActivePlayer()];
	if pPlayer == nil then return;
	else
		local tabID = 0;
		-- Add the Tech Tree Classes as tabs
		local tabList = DB.Query("SELECT * FROM TechTreeClassTypes");
		for eTechClass in tabList do
			local instance = {};
			ContextPtr:BuildInstanceForControl("TabButtonInstance", instance, Controls.TabStack);
			BuildTabButton(pPlayer, eTechClass, instance, "TECH", tabID);
			tableTabs[tabID] = eTechClass;
			tableTabButtons[eTechClass.Type] = instance;
			tabID = tabID + 1;
		end

		-- Add the Policy Branche Classes as tabs
		tabList = DB.Query("SELECT * FROM PolicyBranchClassTypes");
		for eBranchClass in tabList do
			--print(string.format("%s - %s", eBranchClass.Type, eBranchClass.Style));
			local instance = {};
			ContextPtr:BuildInstanceForControl("TabButtonInstance", instance, Controls.TabStack);
			BuildTabButton(pPlayer, eBranchClass, instance, "POLICY", tabID);
			tableTabs[tabID] = eBranchClass;
			tableTabButtons[eBranchClass.Type] = instance;
			tabID = tabID + 1;
		end
	end
	Controls.TabStack:SetHide(false);
	Controls.TabStack:CalculateSize();
    Controls.TabStack:ReprocessAnchoring();
    Controls.TabPanel:CalculateInternalSize();
end

-------------------------------------------------
-- Init
-------------------------------------------------
function Init()
	PopulateTabList();
	tableBranches = GetBranches("BRANCHCLASS_SOCIAL_POLICY");
	UpdateDisplay();
	ContextPtr:SetHide(true);
end

-- START DEBUG FUNCTIONS --

function tableLength(T)
	local count = 0;
	for _ in pairs(T) do count = count + 1 end;
	return count;
end

-- END DEBUG --
Init();