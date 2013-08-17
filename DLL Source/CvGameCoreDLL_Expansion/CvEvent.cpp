#include "CvGameCoreDLLPCH.h"
#include "CvGlobals.h"
#include "CvPlayer.h"
#include "CvUnit.h"
#include "CvCity.h"
#include "CvEvent.h"


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS: CvEvent
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/// Constructor
CvEvent::CvEvent():
	m_eEventType(NO_EVENT),
	m_pPlayer(NULL),
	m_pCity(NULL),
	m_pUnit(NULL)
{
}

/// Destructor
CvEvent::~CvEvent()
{
}

/// Initialize
void CvEvent::init(int iID, EventTypes eEvent, std::map<std::string, std::vector<int> > *asziScopes, CvPlayer* pPlayer, CvCity* pCity, CvUnit* pUnit)
{
	m_iID = iID;
	m_eEventType = eEvent;
	m_pPlayer = pPlayer;
	m_pCity = pCity;
	m_pUnit = pUnit;
	m_asziScopes = *asziScopes;
	gDLL->netMessageDebugLog("We got to 7");
}

void CvEvent::SetID(int iID)
{
	VALIDATE_OBJECT
	m_iID = iID;
}

int CvEvent::GetID()
{
	return m_iID;
}

/// Deallocate memory created in initialize
void CvEvent::uninit()
{
}

void CvEvent::write(FDataStream& kStream) const
{
	// Current version number
	//Because this file is not Firaxis made we don't need a (seperate) mod version number
	uint uiVersion = 1;
	kStream << uiVersion;
	if (m_pCity)
	{
		kStream << 1;
		kStream << m_pCity->GetID();
	}
	else
	{
		kStream << 0;
	}
	if (m_pUnit)
	{
		kStream << 1;
		kStream << m_pUnit->GetID();
	}
	else
	{
		kStream << 0;
	}
	kStream << m_asziScopes;

	// Write out a hash for the event type, instead of storing ID, which can change.
	if (m_eEventType != NO_EVENT)
		kStream << FString::Hash(GC.getEventInfo(m_eEventType)->GetType());
	else
		kStream << (uint)0;

}

void CvEvent::read(FDataStream& kStream)
{
	uint uiVersion;
	kStream >> uiVersion;
	int iTemp;
	kStream >> iTemp;
	if (iTemp == 1)
	{
		int iCity;
		kStream >> iCity;
		m_pCity = m_pPlayer->getCity(iCity);
	}
	kStream >> iTemp;
	if (iTemp == 1)
	{
		int iUnit;
		kStream >> iUnit;
		m_pUnit = m_pPlayer->getUnit(iUnit);
	}
	kStream >> m_asziScopes;

	{
		uint idEventType;
		kStream >> idEventType;
		if (idEventType != 0)
		{
			EventTypes eEventIndex = (EventTypes)GC.getInfoTypeForHash(idEventType);
			if (NO_UNIT != eEventIndex)
				m_eEventType = eEventIndex;
		}
	}
}

EventTypes CvEvent::getEventType() const
{
	return m_eEventType;
}

CvEventInfo& CvEvent::getEventInfo() const
{
	VALIDATE_OBJECT
	return *GC.getEventInfo(m_eEventType);
}

int CvEvent::getNumOptions() const
{
	return GC.getEventInfo(m_eEventType)->getNumOptions();
}
int CvEvent::getOption(int iOption) const
{
	return GC.getEventInfo(m_eEventType)->getOption(iOption);
}

void CvEvent::trigger()
{
	//CvEventInfo* kEvent = GC.getEventInfo(eEvent);

	if (m_pPlayer->isHuman())
	{
		CvNotifications* pNotifications = m_pPlayer->GetNotifications();
		if(pNotifications)
		{
			gDLL->netMessageDebugLog("We got to 8");
			pNotifications->Add(NOTIFICATION_EVENT, "An event has happened", "Event", -1, -1, (int)m_eEventType, GetID());
		}
	}
	else
	{
		//TODO
	}
	//TODO
	gDLL->netMessageDebugLog("We got to 9");
}

void CvEvent::processEventOption(int iOption)
{
	gDLL->netMessageDebugLog("Processing option EventType " + FSerialization::toString((int)getEventType()) + " Option " + FSerialization::toString(iOption));
	EventOptionTypes eOption = GC.getEventInfo(m_eEventType)->getOption(iOption);
	CvEventOptionInfo* pOption = GC.getEventOptionInfo(eOption);

	gDLL->netMessageDebugLog("Number of actions are " + FSerialization::toString(pOption->getNumActions()));
	for (int iI = 0; iI < pOption->getNumActions(); iI++)
	{
		processEventAction(pOption->getAction(iI), eOption);
	}
}

void CvEvent::processEventAction(EventActionTypes eAction, EventOptionTypes eOption)
{
	gDLL->netMessageDebugLog("Processing EventAction");
	CvEventActionInfo kAction = *GC.getEventActionInfo(eAction);
	if ((kAction.getChance() == -1) || (kAction.getChance() > GC.getGame().getJonRandNum(100, "EventAction Chance")))
	{
		int iTypeToAction = -1;
		if (kAction.getTypeToAction() != -1 || kAction.getScope() == "default")
		{
			iTypeToAction = kAction.getTypeToAction();
		}
		else if (kAction.getScope() != "default")
		{
			std::vector<int> aScopes = m_asziScopes[kAction.getScope()];
			if (aScopes.empty())
			{
				//This should never happen.
				return;
			}
			if (aScopes.size() == 1)
			{
				//This should always happen.
				iTypeToAction = aScopes[0];
				FAssertMsg(iTypeToAction != -1, "iTypeToAction was unexpectedly -1 when processing an action");
			}
			else
			{
				//Just in case. 
				//THIS SHOULD BE DONE BEFORE WE GET HERE AND ONLY ONE CHOICE REMAIN, TO GET CONSISTENCY BETWEEN ACTIONS.
				int iRnd = GC.getGame().getJonRandNum(aScopes.size(), "Choosing a random target for an action");
				iTypeToAction = aScopes[iRnd];
				FAssertMsg(iTypeToAction != -1, "iTypeToAction was unexpectedly -1 when processing an action");
			}
		}
		//else probably something which does not need TypeToAction.

		if (kAction.getTurns() > 0)
		{
			m_pPlayer->addTempEventEffect(m_eEventType, eOption, kAction.getActionType(), kAction.getTurns(), iTypeToAction, -kAction.getValue1());
		}

		switch (kAction.getActionType())
		{
		case EVENTACTION_YIELD:
			gDLL->netMessageDebugLog("Processing Yield!");
			m_pPlayer->changeYieldFromEvents((YieldTypes)iTypeToAction, kAction.getValue1());
			break;

		case EVENTACTION_YIELDMOD:
			gDLL->netMessageDebugLog("Processing YieldMod!");
			m_pPlayer->changeYieldModifierFromEvents((YieldTypes)iTypeToAction, kAction.getValue1());
			break;

		case EVENTACTION_HAPPY:
			gDLL->netMessageDebugLog("Processing Happy!");
			m_pPlayer->changeHappyFromEvents(kAction.getValue1());
			break;

		case EVENTACTION_TECH:
			gDLL->netMessageDebugLog("Processing Tech!");
			if ((TechTypes)kAction.getTypeToAction() != NO_TECH)
				GET_TEAM(m_pPlayer->getTeam()).setHasTech((TechTypes)iTypeToAction, kAction.getBool1(), m_pPlayer->GetID(), true, true);
			break;

		case EVENTACTION_POLICY:
			gDLL->netMessageDebugLog("Processing Policy!");
			if ((PolicyTypes)kAction.getTypeToAction() != NO_POLICY)
				m_pPlayer->setHasPolicy((PolicyTypes)iTypeToAction, kAction.getBool1());
			break;
		
		case EVENTACTION_BELIEF:
			gDLL->netMessageDebugLog("Processing Belief!");
			//TODO
			break;

		case EVENTACTION_REVEAL_TILE:
			{
				gDLL->netMessageDebugLog("Processing Reveal Tile!");
				CvPlot* pPlot = GC.getMap().plot(kAction.getValue1(), kAction.getValue2());
				if (pPlot)
					GC.getMap().plot(kAction.getValue1(), kAction.getValue2())->setRevealed(m_pPlayer->getTeam(), true);
				break;
			}

		case EVENTACTION_SET_FLAG:
			gDLL->netMessageDebugLog("Processing Set Flag!");
			m_pPlayer->setFlag(kAction.getString1(), kAction.getValue1());
			break;

		case EVENTACTION_EVENT_FOR_CAPITAL:
			//TODO
			break;

		case EVENTACTION_EVENT_FOR_ALL_CITIES:
			//TODO
			break;

		case EVENTACTION_EVENT_FOR_ALL_UNITS:
			//TODO
			break;

		case EVENTACTION_EVENT:
			//TODO
			break;
		default:
			gDLL->netMessageDebugLog("Processing Unknown action " + FSerialization::toString((int)kAction.getActionType()));
		}
	}
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS: CvEventEffects
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/// Constructor
CvEventEffects::CvEventEffects()
{
}

/// Destructor
CvEventEffects::~CvEventEffects()
{
}

void CvEventEffects::init(EventTypes eEvent, EventOptionTypes eOption, EventActionTypeTypes eEventAction, int iNumTurns, int iType, int iValue)
{
	m_eEventType = eEvent;
	m_eOption = eOption;
	m_eEventAction = eEventAction;
	m_iType = iType;
	m_iValue = iValue;
	m_iNumTurns = iNumTurns;
}

EventTypes CvEventEffects::getEventType() const
{
	return m_eEventType;
}

EventOptionTypes CvEventEffects::getOption() const
{
	return m_eOption;
}

EventActionTypeTypes CvEventEffects::getAction() const
{
	return m_eEventAction;
}

void CvEventEffects::setAction(EventActionTypeTypes eAction)
{
	m_eEventAction = eAction;
}

void CvEventEffects::setType(int iType)
{
	m_iType = iType;
}
int CvEventEffects::getType() const
{
	return m_iType;
}

int CvEventEffects::getValue() const
{
	return m_iValue;
}

void CvEventEffects::setValue(int iNewValue)
{
	m_iValue = iNewValue;
}

int CvEventEffects::getNumTurns() const
{
	return m_iNumTurns;
}

void CvEventEffects::setNumTurns(int iNewValue)
{
	m_iNumTurns = iNewValue;
}

void CvEventEffects::changeNumTurns(int iChange)
{
	m_iNumTurns = m_iNumTurns + iChange;
}