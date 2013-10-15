#pragma once

#define NOTIFICATION_EVENT (NotificationTypes)0x27EA083 //FString::Hash("NOTIFICATION_EVENT")
#define BUTTONPOPUP_EVENT (ButtonPopupTypes)0xD8C95AE6 //FString::Hash("BUTTONPOPUP_EVENT")

// This is the base modifier number for the item for Sets
// We modify this later on and then compare it to the other numbers in that Set
// We need a reasonably large number since modifiers are multiplicative 
// We don't want to have to worry about issues due to rounding
// When multiplying the chance with the item's modifier we take into account that we started with this number
#define BASE_MODIFIER_CHANCE_SETS 1000

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
	void init(int iID, EventTypes eEvent, std::map< std::string, int >& asziSets, PlayerTypes ePlayer, CvCity* pCity = NULL, CvUnit* pUnit = NULL);
	void uninit();

	void read(FDataStream& kStream);
	void write(FDataStream& kStream) const;
	void WriteSetInfo(FDataStream& kStream) const;

	int GetID();
	void SetID(int iID);

	EventTypes getEventType() const;
	CvEventInfo& getEventInfo() const;

	int getNumOptions() const;
	int getOption(int iOption) const;

	int getNotificationID() const;

	void trigger();
	void processEventOption(int iOption);
	void processEventAction(EventActionTypes eAction, EventOptionTypes eOption);

	void getToolTip(int iOption, CvString* toolTipSink);
	void buildActionTooltip(EventActionTypes eAction, CvString* toolTipSink);

private:
	PlayerTypes m_ePlayer;
	CvCity* m_pCity;
	CvUnit* m_pUnit;
	EventTypes m_eEventType;
	std::map<std::string, int > m_asziSets;
	int m_iID;
	int m_iNotificationIndex;
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
class CvEventEffect
{
public:
	CvEventEffect();
	virtual ~CvEventEffect();

	void init(EventTypes eEvent, EventOptionTypes eOption, EventActionTypeTypes eEventAction, int iNumTurns, int iTypeToAction, EventActionTypes eAction);
	EventTypes getEventType() const;
	EventOptionTypes getOption() const;
	EventActionTypeTypes getEventAction() const;
	EventActionTypes getAction() const;
	int getTypeToAction() const;
	int getNumTurns() const;
	void setNumTurns(int iNewValue);
	void changeNumTurns(int iChange);

	void Read(FDataStream& kStream);
	void Write(FDataStream& kStream) const;

private:

	EventActionTypeTypes m_eEventAction;
	EventTypes m_eEventType;
	EventOptionTypes m_eOption;
	EventActionTypes m_eAction;

	int m_iTypeToAction;
	int m_iNumTurns;
};

#endif
