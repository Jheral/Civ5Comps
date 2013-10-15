#pragma once

// EventEngine - v0.1, Snarko
FDataStream& operator<<(FDataStream&, const EventActionTypeTypes&);
FDataStream& operator>>(FDataStream&, EventActionTypeTypes&);
// END EventEngine