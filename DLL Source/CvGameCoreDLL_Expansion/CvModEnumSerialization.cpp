// EventEngine - v0.1, Snarko
#include "CvGameCoreDLLPCH.h"
#include "CvModEnumSerialization.h"

FDataStream& operator<<(FDataStream& saveTo, const EventActionTypeTypes& readFrom)
{
	saveTo << static_cast<int>(readFrom);
	return saveTo;
}
//------------------------------------------------------------------------------
FDataStream& operator>>(FDataStream& loadFrom, EventActionTypeTypes& writeTo)
{
	int v;
	loadFrom >> v;
	writeTo = static_cast<EventActionTypeTypes>(v);
	return loadFrom;
}
// END EventEngine