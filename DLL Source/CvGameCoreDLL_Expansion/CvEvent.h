#pragma once

#define NOTIFICATION_EVENT (NotificationTypes)0x27EA083 //FString::Hash("NOTIFICATION_EVENT")

#ifndef CV_EVENTS_H
#define CV_EVENTS_H

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS: CvEvent
//!  \brief Handles all types of events, players, global, unit etc.
//
//!  Key Attributes:
//!  - This object is created inside the CvPlayer object and accessed through CvPlayer
//!  - Handles triggering of events and the effects of the option chosen
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

class CvEvent
{
public:
	CvEvent();
	virtual ~CvEvent();
	void init(int iID, EventTypes eEvent, std::map< std::string, std::vector<int> > *asziScopes, CvPlayer* pPlayer, CvCity* pCity = NULL, CvUnit* pUnit = NULL);
	void uninit();

	void read(FDataStream& kStream);
	void write(FDataStream& kStream) const;

	int GetID();
	void SetID(int iID);

	EventTypes getEventType() const;
	CvEventInfo& getEventInfo() const;

	//These functions are for lua. We need to be certain we are checking the right options.
	int getNumOptions() const;
	int getOption(int iOption) const;

	void trigger();
	void processEventOption(int iOption);
	void processEventAction(EventActionTypes eAction, EventOptionTypes eOption);

private:
	CvPlayer* m_pPlayer;
	CvCity* m_pCity;
	CvUnit* m_pUnit;
	EventTypes m_eEventType;
	std::map<std::string, std::vector<int> > m_asziScopes;
	int m_iID;
};

FDataStream& operator<<(FDataStream&, const CvEvent&);
FDataStream& operator>>(FDataStream&, CvEvent&);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS: CvEventEffects
//!  \brief Handles temporary event effects
//
//!  Key Attributes:
//!  - This object is created inside the relevant objects and accessed through them
//!  - Handles temporary event effects
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class CvEventEffects
{
public:
	CvEventEffects();
	virtual ~CvEventEffects();

	void init(EventTypes eEvent, EventOptionTypes eOption, EventActionTypeTypes eEventAction = NO_EVENTACTION, int iNumTurns = 1, int iType = -1, int iValue = 0);
	EventTypes getEventType() const;
	EventOptionTypes getOption() const;
	EventActionTypeTypes getAction() const;
	void setAction(EventActionTypeTypes eAction);
	void setType(int iType);
	int getType() const;
	int getValue() const;
	void setValue(int iNewValue);
	int getNumTurns() const;
	void setNumTurns(int iNewValue);
	void changeNumTurns(int iChange);

private:

	EventActionTypeTypes m_eEventAction;
	EventTypes m_eEventType;
	EventOptionTypes m_eOption;
	int m_iType;
	int m_iValue;
	int m_iNumTurns;
};

#endif
