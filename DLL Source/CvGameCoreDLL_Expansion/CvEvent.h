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
	int getOptionInfoType(int iOption) const;

	void trigger();
	void processEventOption(int iOption);
	void processEventAction(CvEventAction& kAction);

private:
	CvPlayer* m_pPlayer;
	CvCity* m_pCity;
	CvUnit* m_pUnit;
	EventTypes m_eEventType;
	std::map<std::string, std::vector<int> > m_asziScopes;
	int m_iID; //Required/used by FFreeListTrashArray
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
	EventActionTypes getAction();
	void setAction(EventActionTypes eAction);
	int getValue();
	void setValue(int iNewValue);
	int getNumTurns();
	void setNumTurns(int iNewValue);
	void changeNumTurns(int iChange);

private:
	EventActionTypes m_eEventAction;
	int m_iValue;
	int m_iNumTurns;
};

#endif
