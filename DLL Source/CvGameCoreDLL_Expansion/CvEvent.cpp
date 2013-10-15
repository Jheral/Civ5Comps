#include "CvGameCoreDLLPCH.h"
#include "CvGlobals.h"
#include "CvPlayer.h"
#include "CvPlayerAI.h"
#include "CvUnit.h"
#include "CvCity.h"
#include "CvEvent.h"
#include "CvGameCoreUtils.h"
#include "CvModEnumSerialization.h"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS: CvEvent
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/// Constructor
CvEvent::CvEvent():
m_eEventType(NO_EVENT),
m_ePlayer(NO_PLAYER),
m_pCity(NULL),
m_pUnit(NULL)
{
}

/// Destructor
CvEvent::~CvEvent()
{
}

/// Initialize
void CvEvent::init(int iID, EventTypes eEvent, std::map<std::string, int >& asziSets, PlayerTypes ePlayer, CvCity* pCity, CvUnit* pUnit)
{
	m_iID = iID;
	m_eEventType = eEvent;
	m_ePlayer = ePlayer;
	m_pCity = pCity;
	m_pUnit = pUnit;
	m_asziSets = asziSets;
	m_iNotificationIndex = -1;
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
	// Because this file is not Firaxis made we don't need a (seperate) mod version number
	uint uiVersion = 1;
	kStream << uiVersion;

	kStream << m_ePlayer;

	if (m_pCity)
	{
		kStream << true;
		kStream << m_pCity->GetID();
	}
	else
	{
		kStream << false;
	}
	if (m_pUnit)
	{
		kStream << true;
		kStream << m_pUnit->GetID();
	}
	else
	{
		kStream << false;
	}

	WriteSetInfo(kStream);

	// Write out a hash for the event type, instead of storing ID, which can change.
	if (m_eEventType != NO_EVENT)
		kStream << FString::Hash(GC.getEventInfo(m_eEventType)->GetType());
	else
		kStream << (uint)0;

	kStream << m_iNotificationIndex;
}

void CvEvent::WriteSetInfo(FDataStream& kStream) const
{
	uint iNumEntries = m_asziSets.size();
	kStream << iNumEntries;

	// We are going to store the hash of the items, because the ID can change between games (especially if a mod is changed).
	// But in order to do this we need to know what the item actually is.
	// Since we don't know what type of item we are dealing with, this is problematic.
	std::map<std::string, int >::const_iterator it;
	bool bFound;
	for(it = m_asziSets.begin(); it != m_asziSets.end(); ++it)
	{
		bFound = false;
		for (int iI = 0; iI < getNumOptions(); iI++)
		{
			CvEventOptionInfo* pOption = GC.getEventOptionInfo((EventOptionTypes)getOption(iI));
			for (int iJ = 0; iJ < pOption->getNumActions(); iJ++)
			{
				CvEventActionInfo* pAction = GC.getEventActionInfo(pOption->getAction(iJ));
				if (pAction->getSet() == it->first)
				{
					switch(pAction->getActionType())
					{
						// TODO not needlessly repeat the same code over and over here.
					case EVENTACTION_YIELD:
					case EVENTACTION_YIELDMOD:
					case EVENTACTION_CITY_YIELD:
					case EVENTACTION_CITY_YIELDMOD:
						bFound = true;
						kStream << it->first;
						kStream << FString::Hash(GC.getYieldInfo((YieldTypes)it->second)->GetType());
						break;

					case EVENTACTION_TECH:
						bFound = true;
						kStream << it->first;
						kStream << FString::Hash(GC.getTechInfo((TechTypes)it->second)->GetType());
						break;

					case EVENTACTION_POLICY:
						bFound = true;
						kStream << it->first;
						kStream << FString::Hash(GC.getPolicyInfo((PolicyTypes)it->second)->GetType());
						break;

					case EVENTACTION_BELIEF:
						bFound = true;
						kStream << it->first;
						kStream << FString::Hash(GC.getBeliefInfo((BeliefTypes)it->second)->GetType());
						break;

					case EVENTACTION_SPECIALIST_YIELD:
					case EVENTACTION_CITY_FREE_SPECIALIST:
					case EVENTACTION_CITY_SPECIALIST_YIELD:
						bFound = true;
						kStream << it->first;
						kStream << FString::Hash(GC.getSpecialistInfo((SpecialistTypes)it->second)->GetType());
						break;

					case EVENTACTION_CITY_ADD_BUILDING:
						bFound = true;
						kStream << it->first;
						kStream << FString::Hash(GC.getBuildingInfo((BuildingTypes)it->second)->GetType());
						break;

					default:
						FAssert(false);
					}
					break;
				}
			}
			if (bFound)
				break;
		}
		// If we didn't find it we will still save it, to get the number of saved items to match with the count.
		if (!bFound)
		{
			kStream << it->first;
			kStream << -1;
		}
	}
}

void CvEvent::read(FDataStream& kStream)
{
	uint iNumEntries;
	uint uiVersion;
	kStream >> uiVersion;

	kStream >> m_ePlayer;

	bool bLoad;
	kStream >> bLoad;
	if (bLoad)
	{
		int iCity;
		kStream >> iCity;
		m_pCity = GET_PLAYER(m_ePlayer).getCity(iCity);
	}
	kStream >> bLoad;
	if (bLoad)
	{
		int iUnit;
		kStream >> iUnit;
		m_pUnit = GET_PLAYER(m_ePlayer).getUnit(iUnit);
	}

	kStream >> iNumEntries;
	for (uint iI = 0; iI < iNumEntries; iI++)
	{
		std::string szName;
		uint idItem;
		kStream >> szName;
		kStream >> idItem;
		// If idItem is 0 we couldn't find anything to hash.
		// That should mean that the Set isn't used for any of the actions, so we don't need it.
		if (idItem != 0)
			m_asziSets[szName] = GC.getInfoTypeForHash(idItem);
	}

	{
		uint idEventType;
		kStream >> idEventType;
		if (idEventType != 0)
		{
			EventTypes eEventIndex = (EventTypes)GC.getInfoTypeForHash(idEventType);
			if (NO_EVENT != eEventIndex)
				m_eEventType = eEventIndex;
		}
	}

	kStream >> m_iNotificationIndex;
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

int CvEvent::getNotificationID() const
{
	return m_iNotificationIndex;
}

void CvEvent::trigger()
{
	// CvEventInfo* kEvent = GC.getEventInfo(eEvent);

	if (GET_PLAYER(m_ePlayer).isHuman())
	{
		CvNotifications* pNotifications = GET_PLAYER(m_ePlayer).GetNotifications();
		if(pNotifications)
		{
			int iX = -1;
			int iY = -1;
			if (m_pCity != NULL)
			{
				iX = m_pCity->getX();
				iY = m_pCity->getY();
			}
			else if (m_pUnit != NULL)
			{
				iX = m_pUnit->getX();
				iY = m_pUnit->getY();
			}
			m_iNotificationIndex = pNotifications->Add(NOTIFICATION_EVENT, GC.getEventInfo(m_eEventType)->getNotificationText(), "Event", iX, iY, (int)m_eEventType, GetID());
		}
	}
	// TODO?
}

void CvEvent::processEventOption(int iOption)
{
	EventOptionTypes eOption = GC.getEventInfo(m_eEventType)->getOption(iOption);
	CvEventOptionInfo* pOption = GC.getEventOptionInfo(eOption);

	for (int iI = 0; iI < pOption->getNumActions(); iI++)
	{
		processEventAction(pOption->getAction(iI), eOption);
	}
}

void CvEvent::processEventAction(EventActionTypes eAction, EventOptionTypes eOption)
{
	CvEventActionInfo kAction = *GC.getEventActionInfo(eAction);
	CvPlayerAI& kPlayer = GET_PLAYER(m_ePlayer);
	if ((kAction.getChance() == -1) || (kAction.getChance() > GC.getGame().getJonRandNum(100, "EventAction Chance")))
	{
		int iTypeToAction;
		if (kAction.getSet() != "default")
		{
			std::map<std::string, int>::const_iterator it = m_asziSets.find(kAction.getSet());
			if (it != m_asziSets.end())
				iTypeToAction = m_asziSets.find(kAction.getSet())->second;
			else
			{
				FAssert(false);
				iTypeToAction = -1;
			}
		}
		else
			iTypeToAction = kAction.getTypeToAction();

		if (kAction.getNumTurns() > 0)
		{
			CvEventEffect kEventEffect;
			kEventEffect.init(m_eEventType, eOption, kAction.getActionType(), kAction.getNumTurns(), iTypeToAction, eAction);
			if (kAction.getActionType() > EVENTACTION_PLAYER_START && kAction.getActionType() < EVENTACTION_PLAYER_END)
				kPlayer.addTempEventEffect(kEventEffect);
			else if (kAction.getActionType() > EVENTACTION_CITY_START && kAction.getActionType() < EVENTACTION_CITY_END && m_pCity != NULL)
				m_pCity->addTempEventEffect(kEventEffect);
			else if (kAction.getActionType() > EVENTACTION_UNIT_START && kAction.getActionType() < EVENTACTION_UNIT_END && m_pUnit != NULL)
				m_pUnit->addTempEventEffect(kEventEffect);
		}

		switch (kAction.getActionType())
		{
		case EVENTACTION_YIELD:
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (iTypeToAction != NO_YIELD)
				kPlayer.changeYieldFromEvents((YieldTypes)iTypeToAction, kAction.getValue1());
			break;

		case EVENTACTION_YIELDMOD:
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (iTypeToAction != NO_YIELD)
				kPlayer.changeYieldModifierFromEvents((YieldTypes)iTypeToAction, kAction.getValue1());
			break;

		case EVENTACTION_HAPPY:
			kPlayer.changeHappyFromEvents(kAction.getValue1());
			break;

		case EVENTACTION_TECH:
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (kAction.getTypeToAction() != NO_TECH)
				GET_TEAM(kPlayer.getTeam()).setHasTech((TechTypes)iTypeToAction, kAction.getBool1(), m_ePlayer, true, true);
			break;

		case EVENTACTION_POLICY:
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (kAction.getTypeToAction() != NO_POLICY)
				kPlayer.setHasPolicy((PolicyTypes)iTypeToAction, kAction.getBool1());
			break;

		case EVENTACTION_BELIEF:
			// TODO
			break;

		case EVENTACTION_REVEAL_TILE:
			{
				CvPlot* pPlot = GC.getMap().plot(kAction.getValue1(), kAction.getValue2());
				if (pPlot)
					GC.getMap().plot(kAction.getValue1(), kAction.getValue2())->setRevealed(kPlayer.getTeam(), true);
				break;
			}

		case EVENTACTION_SET_FLAG:
			if (kAction.getBool1())
				kPlayer.changeFlag(kAction.getString1(), kAction.getValue1());
			else
				kPlayer.setFlag(kAction.getString1(), kAction.getValue1());
			break;

		case EVENTACTION_SPECIALIST_YIELD:
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (iTypeToAction != NO_SPECIALIST)
				kPlayer.changeSpecialistExtraYield((SpecialistTypes)iTypeToAction, (YieldTypes)kAction.getValue1(), kAction.getValue2());
			break;

		case EVENTACTION_EVENT_FOR_CAPITAL:
			{
				CvCity* pCapitalCity = GET_PLAYER(m_ePlayer).getCapitalCity();
				if (pCapitalCity != NULL && (EventTypes)iTypeToAction != NO_EVENT)
					GET_PLAYER(m_ePlayer).triggerEvent((EventTypes)iTypeToAction, kAction.getBool1(), m_asziSets, pCapitalCity);
			}
			break;

		case EVENTACTION_EVENT_FOR_ALL_CITIES:
			{
				if (iTypeToAction != NO_EVENT)
				{
					int iLoop;
					CvCity* pLoopCity;
					for(pLoopCity = GET_PLAYER(m_ePlayer).firstCity(&iLoop); pLoopCity != NULL; pLoopCity = GET_PLAYER(m_ePlayer).nextCity(&iLoop))
					{
						GET_PLAYER(m_ePlayer).triggerEvent((EventTypes)iTypeToAction, kAction.getBool1(), m_asziSets, pLoopCity);
					}
				}
			}
			break;

		case EVENTACTION_EVENT_FOR_ALL_UNITS:
			{
				if (iTypeToAction != NO_EVENT)
				{
					int iLoop;
					CvUnit* pLoopUnit;
					for(pLoopUnit = GET_PLAYER(m_ePlayer).firstUnit(&iLoop); pLoopUnit != NULL; pLoopUnit = GET_PLAYER(m_ePlayer).nextUnit(&iLoop))
					{
						GET_PLAYER(m_ePlayer).triggerEvent(m_eEventType, kAction.getBool1(), m_asziSets, NULL, pLoopUnit);
					}
				}
			}
			break;

		case EVENTACTION_EVENT:
			if (iTypeToAction != NO_EVENT)
				GET_PLAYER(m_ePlayer).triggerEvent((EventTypes)iTypeToAction, kAction.getBool1(), m_asziSets, m_pCity, m_pUnit);
			break;

		case EVENTACTION_CITY_ADD_BUILDING:
			{
				if (m_pCity == NULL)
				{
					FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_ADD_BUILDING");
					return;
				}
				FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
				CvCityBuildings* pBuildings = m_pCity->GetCityBuildings();
				if (iTypeToAction != NO_BUILDING && pBuildings != NULL)
				{
					if (kAction.getBool1())
						pBuildings->SetNumFreeBuilding((BuildingTypes)iTypeToAction, range(pBuildings->GetNumFreeBuilding((BuildingTypes)iTypeToAction) + kAction.getValue1(), 0, GC.getCITY_MAX_NUM_BUILDINGS()));
					else
						pBuildings->SetNumRealBuilding((BuildingTypes)iTypeToAction, range(pBuildings->GetNumBuilding((BuildingTypes)iTypeToAction) + kAction.getValue1(), 0, GC.getCITY_MAX_NUM_BUILDINGS()));
				}
			}
			break;

		case EVENTACTION_CITY_YIELD:
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_CITY_YIELD");
				return;
			}
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (iTypeToAction != NO_YIELD)
				m_pCity->ChangeBaseYieldRateFromEvents((YieldTypes)iTypeToAction, kAction.getValue1());
			break;

		case EVENTACTION_CITY_YIELDMOD:
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_CITY_YIELDMOD");
				return;
			}
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (iTypeToAction != NO_YIELD)
				m_pCity->ChangeEventYieldRateModifier((YieldTypes)iTypeToAction, kAction.getValue1());
			break;

		case EVENTACTION_CITY_POPULATION:
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_CITY_POPULATION");
				return;
			}
			// std::max so we don't make city size 0 or less.
			m_pCity->changePopulation(std::max(1 - m_pCity->getPopulation(), kAction.getValue1()));
			break;

		case EVENTACTION_CITY_LOCAL_HAPPY:
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_CITY_LOCAL_HAPPY");
				return;
			}
			m_pCity->ChangeHappinessFromEvents(kAction.getValue1());
			break;

		case EVENTACTION_CITY_FREE_SPECIALIST:
			{
				if (m_pCity == NULL)
				{
					FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_CITY_FREE_SPECIALIST");
					return;
				}
				FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
				if (iTypeToAction != NO_SPECIALIST)
				{
					int iNumSpecialist = m_pCity->GetCityCitizens()->GetNumFreeSpecialist((SpecialistTypes)iTypeToAction);
					m_pCity->GetCityCitizens()->ChangeNumFreeSpecialist((SpecialistTypes)iTypeToAction, std::max(-iNumSpecialist, kAction.getValue1()));
				}
			}
			break;

		case EVENTACTION_CITY_SPECIALIST_YIELD:
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_CITY_SPECIALIST_YIELD");
				return;
			}
			FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
			if (iTypeToAction != NO_SPECIALIST)
				m_pCity->changeCitySpecialistExtraYield((SpecialistTypes)iTypeToAction, (YieldTypes)kAction.getValue1(), kAction.getValue2());
			break;

		case EVENTACTION_CITY_SET_FLAG:
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_CITY_SET_FLAG");
				return;
			}
			if (kAction.getBool1())
				m_pCity->changeFlag(kAction.getString1(), kAction.getValue1());
			else
				m_pCity->setFlag(kAction.getString1(), kAction.getValue1());
			break;

		case EVENTACTION_UNIT_EXPERIENCE:
			{
				if (m_pUnit == NULL)
				{
					FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::processEventAction, EVENTACTION_UNIT_EXPERIENCE");
					return;
				}
				int iMax = kAction.getValue2();
				if (iMax == 0) // A max of 0 makes no sense, but is the default value. So make the default be -1 instead.
					iMax = -1;
				m_pUnit->changeExperience(kAction.getValue1(), iMax);
			}
			break;

		case EVENTACTION_UNIT_PROMOTION:
			if (m_pUnit == NULL)
			{
				FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::processEventAction, EVENTACTION_UNIT_PROMOTION");
				return;
			}
			if (iTypeToAction != NO_PROMOTION)
				m_pUnit->setHasPromotion((PromotionTypes)iTypeToAction, kAction.getBool1());
			break;

		case EVENTACTION_UNIT_CLASS:
			{
				if (m_pUnit == NULL)
				{
					FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::processEventAction, EVENTACTION_UNIT_CLASS");
					return;
				}
				if (iTypeToAction != NO_UNIT)
				{
					CvCivilizationInfo& kCiv = GET_PLAYER(m_ePlayer).getCivilizationInfo();
					UnitTypes eUnitType = (UnitTypes)kCiv.getCivilizationUnits(iTypeToAction);
					if (eUnitType != NO_UNIT && eUnitType != m_pUnit->getUnitType())
					{
						CvUnit* pNewUnit = GET_PLAYER(m_ePlayer).initUnit(eUnitType, m_pUnit->getX(), m_pUnit->getY(), NO_UNITAI, NO_DIRECTION, false, false);
						m_pUnit->convert(pNewUnit, false);
					}
				}
			}
			break;

		case EVENTACTION_UNIT_DAMAGE:
			if (m_pUnit == NULL)
			{
				FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::processEventAction, EVENTACTION_UNIT_DAMAGE");
				return;
			}
			m_pUnit->changeDamage(kAction.getValue1());
			break;

		case EVENTACTION_UNIT_SPAWN_UNIT:
			{
				if (m_pUnit == NULL)
				{
					FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::processEventAction, EVENTACTION_UNIT_DAMAGE");
					return;
				}
				CvUnit* pNewUnit = GET_PLAYER(m_ePlayer).initUnit((UnitTypes)iTypeToAction, m_pUnit->getX(), m_pUnit->getY(), NO_UNITAI, NO_DIRECTION, false, false);
				pNewUnit->jumpToNearestValidPlot();
			}
			break;

		case EVENTACTION_UNIT_SET_FLAG:
			if (m_pUnit == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::processEventAction, EVENTACTION_UNIT_SET_FLAG");
				return;
			}
			if (kAction.getBool1())
				m_pUnit->changeFlag(kAction.getString1(), kAction.getValue1());
			else
				m_pUnit->setFlag(kAction.getString1(), kAction.getValue1());
			break;


		default:
			FAssert(false);
			break;
		}
	}
}

void CvEvent::getToolTip(int iOption, CvString* toolTipSink)
{
	EventOptionTypes eOption = GC.getEventInfo(m_eEventType)->getOption(iOption);
	CvEventOptionInfo* pOption = GC.getEventOptionInfo(eOption);

	for (int iI = 0; iI < pOption->getNumActions(); iI++)
	{
		buildActionTooltip(pOption->getAction(iI), toolTipSink);
	}
}

void CvEvent::buildActionTooltip(EventActionTypes eAction, CvString* toolTipSink)
{	
	CvEventActionInfo* pkAction = GC.getEventActionInfo(eAction);
	int iChance = pkAction->getChance();
	int iTurns = pkAction->getNumTurns();
	CvString tmpString = "";
	int iTypeToAction = -1;		

	if (pkAction->getSet() != "default")
	{
		std::map<std::string, int>::const_iterator it = m_asziSets.find(pkAction->getSet());
		if (it != m_asziSets.end())
			iTypeToAction = m_asziSets.find(pkAction->getSet())->second;
		else
		{
			FAssert(false);
			iTypeToAction = -1;
		}
	}
	else
		iTypeToAction = pkAction->getTypeToAction();

	switch (pkAction->getActionType())
	{
	case EVENTACTION_YIELD:
		FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
		if (iTypeToAction != NO_YIELD)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_YIELD", pkAction->getValue1(), GC.getYieldInfo((YieldTypes)iTypeToAction)->getIconString());
		break;

	case EVENTACTION_YIELDMOD:
		FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
		if (iTypeToAction != NO_YIELD)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_YIELDMOD", pkAction->getValue1(), GC.getYieldInfo((YieldTypes)iTypeToAction)->getIconString());
		break;

	case EVENTACTION_HAPPY:
		tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_HAPPY", pkAction->getValue1());
		break;

	case EVENTACTION_TECH:
		FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
		if (iTypeToAction != NO_TECH)
		{
			if (pkAction->getBool1())
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_TECH", GC.getTechInfo((TechTypes)iTypeToAction)->GetDescription());
			else
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_NO_TECH", GC.getTechInfo((TechTypes)iTypeToAction)->GetDescription());
		}
		break;

	case EVENTACTION_POLICY:
		FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
		if (iTypeToAction != NO_POLICY)
		{
			if (pkAction->getBool1())
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_POLICY", GC.getPolicyInfo((PolicyTypes)iTypeToAction)->GetDescription());
			else
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_NO_POLICY", GC.getPolicyInfo((PolicyTypes)iTypeToAction)->GetDescription());
		}
		break;

	case EVENTACTION_BELIEF:
		tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_BELIEF");
		break;

	case EVENTACTION_REVEAL_TILE:
		tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_REVEAL_TILE", pkAction->getValue1(), pkAction->getValue2());
		break;

	case EVENTACTION_SET_FLAG:
		if (pkAction->getBool1())
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CHANCE_FLAG", pkAction->getString1().c_str(), pkAction->getValue1());
		else
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_SET_FLAG", pkAction->getString1().c_str(), pkAction->getValue1());
		break;

	case EVENTACTION_SPECIALIST_YIELD:
		FAssertMsg(iTypeToAction != -1, "iTypeToAction was -1 when proccessing an EventAction that expected otherwise");
		if (iTypeToAction != NO_SPECIALIST)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_SPECIALIST_YIELD", GC.getYieldInfo((YieldTypes)pkAction->getValue1())->getIconString(), GC.getSpecialistInfo((SpecialistTypes)iTypeToAction)->GetDescription(), pkAction->getValue2());
		break;

	case EVENTACTION_EVENT_FOR_CAPITAL:
		{
			CvCity* pCapitalCity = GET_PLAYER(m_ePlayer).getCapitalCity();
			if (pCapitalCity != NULL && (EventTypes)iTypeToAction != NO_EVENT)
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_EVENT_FOR_CAPITAL", GC.getEventInfo((EventTypes)iTypeToAction)->GetDescription(), pCapitalCity->getName().c_str());
		}
		break;

	case EVENTACTION_EVENT_FOR_ALL_CITIES:
		if (iTypeToAction != NO_EVENT)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_EVENT_FOR_ALL_CITIES", GC.getEventInfo((EventTypes)iTypeToAction)->GetDescription());
		break;

	case EVENTACTION_EVENT_FOR_ALL_UNITS:
		if (iTypeToAction != NO_EVENT)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_EVENT_FOR_ALL_UNITS", GC.getEventInfo((EventTypes)iTypeToAction)->GetDescription());
		break;

	case EVENTACTION_EVENT:
		if (iTypeToAction != NO_EVENT)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_EVENT", GC.getEventInfo((EventTypes)iTypeToAction)->GetDescription());

	case EVENTACTION_CITY_ADD_BUILDING:
		{
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_ADD_BUILDING");
				return;
			}
			CvCityBuildings* pBuildings = m_pCity->GetCityBuildings();
			if (iTypeToAction != NO_BUILDING && pBuildings != NULL)
			{
				int iNumBuilding = (pkAction->getBool1() ? pBuildings->GetNumFreeBuilding((BuildingTypes)iTypeToAction) : pBuildings->GetNumBuilding((BuildingTypes)iTypeToAction));
				int iNum = range(iNumBuilding + pkAction->getValue1(), 0, GC.getCITY_MAX_NUM_BUILDINGS()) - iNumBuilding;
				if (iNum > 0)
				{
					if (pkAction->getBool1())
						tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_ADD_FREE_BUILDING", iNum, GC.getBuildingInfo((BuildingTypes)iTypeToAction)->GetDescription(), m_pCity->getName().c_str());
					else
						tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_ADD_BUILDING", iNum, GC.getBuildingInfo((BuildingTypes)iTypeToAction)->GetDescription(), m_pCity->getName().c_str());
				}
				else if (iNum < 0)
					tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_REM_BUILDING", iNum, GC.getBuildingInfo((BuildingTypes)iTypeToAction)->GetDescription(), m_pCity->getName().c_str());
			}
		}
		break;

	case EVENTACTION_CITY_YIELD:
		if (m_pCity == NULL)
		{
			FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_CITY_YIELD");
			return;
		}
		if (iTypeToAction != NO_YIELD)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_YIELD", GC.getYieldInfo((YieldTypes)iTypeToAction)->getIconString(), pkAction->getValue1(), m_pCity->getName().c_str());
		break;

	case EVENTACTION_CITY_YIELDMOD:
		if (m_pCity == NULL)
		{
			FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_CITY_YIELDMOD");
			return;
		}
		if (iTypeToAction != NO_YIELD)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_YIELDMOD", GC.getYieldInfo((YieldTypes)iTypeToAction)->getIconString(), pkAction->getValue1(), m_pCity->getName().c_str());
		break;

	case EVENTACTION_CITY_POPULATION:
		if (m_pCity == NULL)
		{
			FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_CITY_POPULATION");
			return;
		}
		tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_POPULATION", std::max(1 - m_pCity->getPopulation(), pkAction->getValue1()), m_pCity->getName().c_str());
		break;

	case EVENTACTION_CITY_LOCAL_HAPPY:
		if (m_pCity == NULL)
		{
			FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_CITY_LOCAL_HAPPY");
			return;
		}
		tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_LOCAL_HAPPY", pkAction->getValue1(), m_pCity->getName().c_str());
		break;

	case EVENTACTION_CITY_FREE_SPECIALIST:
		{
			if (m_pCity == NULL)
			{
				FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_CITY_FREE_SPECIALIST");
				return;
			}
			if (iTypeToAction != NO_SPECIALIST)
			{
				int iNumSpecialist = std::max(-(m_pCity->GetCityCitizens()->GetNumFreeSpecialist((SpecialistTypes)iTypeToAction)), pkAction->getValue1());
				if (iNumSpecialist > 0)
					tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_FREE_SPECIALIST", iNumSpecialist, GC.getSpecialistInfo((SpecialistTypes)iTypeToAction)->GetDescription(), m_pCity->getName().c_str());
				else if (iNumSpecialist < 0)
					tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_LOSE_FREE_SPECIALIST", iNumSpecialist, GC.getSpecialistInfo((SpecialistTypes)iTypeToAction)->GetDescription(), m_pCity->getName().c_str());
			}
		}
		break;

	case EVENTACTION_CITY_SPECIALIST_YIELD:
		if (m_pCity == NULL)
		{
			FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_CITY_SPECIALIST_YIELD");
			return;
		}
		if (iTypeToAction != NO_SPECIALIST)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_SPECIALIST_YIELD", GC.getYieldInfo((YieldTypes)pkAction->getValue1())->getIconString(), GC.getSpecialistInfo((SpecialistTypes)iTypeToAction)->GetDescription(), pkAction->getValue2(), m_pCity->getName().c_str());
		break;

	case EVENTACTION_CITY_SET_FLAG:
		if (m_pCity == NULL)
		{
			FAssertMsg(false, "Expected m_pCity to be a valid city, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_CITY_SET_FLAG");
			return;
		}
		tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_CITY_SET_FLAG", pkAction->getString1().c_str(), pkAction->getValue1(), m_pCity->getName().c_str());
		break;

	case EVENTACTION_UNIT_EXPERIENCE:
		{
			if (m_pUnit == NULL)
			{
				FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_UNIT_EXPERIENCE");
				return;
			}
			int iMax = pkAction->getValue2();
			if (iMax == 0) // A max of 0 makes no sense, but is the default value. So make the default be -1 instead.
				iMax = -1;
			int iExperience = std::min(iMax, m_pUnit->getExperience() + pkAction->getValue1());
			if (iExperience != 0)
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_EXPERIENCE", m_pUnit->getName().c_str(), iExperience);
		}
		break;

	case EVENTACTION_UNIT_PROMOTION:
		if (m_pUnit == NULL)
		{
			FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_UNIT_PROMOTION");
			return;
		}
		if (iTypeToAction != NO_PROMOTION)
		{
			if (pkAction->getBool1() && !(m_pUnit->isHasPromotion((PromotionTypes)iTypeToAction)))
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_PROMOTION", m_pUnit->getName().c_str(), GC.getPromotionInfo((PromotionTypes)iTypeToAction)->GetDescription());
			else if (!(pkAction->getBool1()) && m_pUnit->isHasPromotion((PromotionTypes)iTypeToAction))
				tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_REM_PROMOTION", m_pUnit->getName().c_str(), GC.getPromotionInfo((PromotionTypes)iTypeToAction)->GetDescription());
		}
		break;

	case EVENTACTION_UNIT_CLASS:
		{
			if (m_pUnit == NULL)
			{
				FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_UNIT_CLASS");
				return;
			}
			if (iTypeToAction != NO_UNIT)
			{
				CvCivilizationInfo& kCiv = GET_PLAYER(m_ePlayer).getCivilizationInfo();
				UnitTypes eUnitType = (UnitTypes)kCiv.getCivilizationUnits(iTypeToAction);
				if (eUnitType != NO_UNIT && eUnitType != m_pUnit->getUnitType())
					tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_CLASS", m_pUnit->getName().c_str(), GC.getUnitInfo((UnitTypes)iTypeToAction)->GetDescription());
			}
		}
		break;

	case EVENTACTION_UNIT_DAMAGE:
		{
			if (m_pUnit == NULL)
			{
				FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::buildActionTooltip, EVENTACTION_UNIT_DAMAGE");
				return;
			}
			int iDamage = pkAction->getValue1();
			if (iDamage != 0)
			{
				bool bDead = (m_pUnit->getDamage() + iDamage) >= m_pUnit->GetMaxHitPoints();
				if (bDead)
					tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_DAMAGE_KILL", m_pUnit->getName().c_str());
				else if (iDamage > 0)
					tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_DAMAGE", m_pUnit->getName().c_str(), iDamage);
				else if (m_pUnit->getDamage() > 0)
					tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_DAMAGE_HEAL", m_pUnit->getName().c_str(), std::min(m_pUnit->getDamage(), iDamage));
			}
		}
		break;

	case EVENTACTION_UNIT_SPAWN_UNIT:
		if (m_pUnit == NULL)
		{
			FAssertMsg(false, "Expected m_pUnit to be a valid unit, got NULL instead in CvEvent::processEventAction, EVENTACTION_UNIT_DAMAGE");
			return;
		}
		if (iTypeToAction != NO_UNIT)
			tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_SPAWN_UNIT", m_pUnit->getName().c_str(), GC.getUnitInfo((UnitTypes)iTypeToAction)->GetDescription());
		break;

	case EVENTACTION_UNIT_SET_FLAG:
		tmpString = GetLocalizedText("TXT_KEY_EVENTACTION_UNIT_SET_FLAG", m_pUnit->getName().c_str(), pkAction->getValue1(), pkAction->getString1().c_str());
		break;
	}

	if (tmpString != "")
	{
		if (iChance > 0)
		{
			*toolTipSink += GetLocalizedText("TXT_KEY_EVENT_ACTION_CHANCE", iChance);
			*toolTipSink += "[SPACE]";
		}

		*toolTipSink += tmpString;

		if (iTurns > 0)
		{
			*toolTipSink += "[SPACE]";
			*toolTipSink += GetLocalizedText("TXT_KEY_EVENT_ACTION_TURNS", iTurns);
		}

		*toolTipSink += ".[NEWLINE]";
	}
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS: CvEventEffect
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/// Constructor
CvEventEffect::CvEventEffect()
{
}

/// Destructor
CvEventEffect::~CvEventEffect()
{
}

void CvEventEffect::init(EventTypes eEvent, EventOptionTypes eOption, EventActionTypeTypes eEventAction, int iNumTurns, int iTypeToAction, EventActionTypes eAction)
{
	m_eEventType = eEvent;
	m_eOption = eOption;
	m_eEventAction = eEventAction;
	m_eAction = eAction;
	m_iNumTurns = iNumTurns;
	m_iTypeToAction = iTypeToAction;
}

EventTypes CvEventEffect::getEventType() const
{
	return m_eEventType;
}

EventOptionTypes CvEventEffect::getOption() const
{
	return m_eOption;
}

EventActionTypeTypes CvEventEffect::getEventAction() const
{
	return m_eEventAction;
}

int CvEventEffect::getTypeToAction() const
{
	return m_iTypeToAction;
}

EventActionTypes CvEventEffect::getAction() const
{
	return m_eAction;
}

int CvEventEffect::getNumTurns() const
{
	return m_iNumTurns;
}

void CvEventEffect::setNumTurns(int iNewValue)
{
	m_iNumTurns = iNewValue;
}

void CvEventEffect::changeNumTurns(int iChange)
{
	m_iNumTurns = m_iNumTurns + iChange;
}

void CvEventEffect::Read(FDataStream& kStream)
{
	kStream >> m_eEventAction;

	{
		uint idEventType;
		kStream >> idEventType;
		if (idEventType != 0)
		{
			EventTypes eEventIndex = (EventTypes)GC.getInfoTypeForHash(idEventType);
			if (NO_EVENT != eEventIndex)
				m_eEventType = eEventIndex;
		}
	}

	{
		uint idOption;
		kStream >> idOption;
		if (idOption != 0)
		{
			EventOptionTypes eOptionIndex = (EventOptionTypes)GC.getInfoTypeForHash(idOption);
			if (NO_EVENT_OPTION != eOptionIndex)
				m_eOption = eOptionIndex;
		}
	}

	{
		uint idAction;
		kStream >> idAction;
		if (idAction != 0)
		{
			EventActionTypes eActionIndex = (EventActionTypes)GC.getInfoTypeForHash(idAction);
			if (NO_EVENT_ACTION != eActionIndex)
				m_eAction = eActionIndex;
		}
	}

	kStream >> m_iTypeToAction;
	kStream >> m_iNumTurns;
}

void CvEventEffect::Write(FDataStream& kStream) const
{
	kStream << m_eEventAction;

	// Write out a hash for the event type, instead of storing ID, which can change.
	if (m_eEventType != NO_EVENT)
		kStream << FString::Hash(GC.getEventInfo(m_eEventType)->GetType());
	else
		kStream << (uint)0;

	// And same for option type
	if (m_eOption != NO_EVENT_OPTION)
		kStream << FString::Hash(GC.getEventOptionInfo(m_eOption)->GetType());
	else
		kStream << (uint)0;

	// And same for action type
	if (m_eAction != NO_EVENT_ACTION)
		kStream << FString::Hash(GC.getEventActionInfo(m_eAction)->GetType());
	else
		kStream << (uint)0;

	kStream << m_iTypeToAction;
	kStream << m_iNumTurns;
}