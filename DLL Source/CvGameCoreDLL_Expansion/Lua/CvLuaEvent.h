#pragma once
#ifndef CVLUAEVENT_H
#define CVLUAEVENT_H

#include "CvLuaScopedInstance.h"

class CvLuaEvent : public CvLuaScopedInstance<CvLuaEvent, CvEvent>
{
public:

	//! Push CvEvent methods into table t
	static void PushMethods(lua_State* L, int t);

	//! Required by CvLuaScopedInstance.
	static void HandleMissingInstance(lua_State* L);

	//! Required by CvLuaScopedInstance.
	static const char* GetTypeName();

protected:

	static int lIsNone(lua_State* L);

	static int lGetID(lua_State* L);

	static int lGetEventType(lua_State* L);

	static int lGetNumOptions(lua_State* L);
	static int lGetOptionInfoType(lua_State* L);

	static int lTrigger(lua_State* L);
	static int lProcessEventOption(lua_State* L);

};

#endif //CVLUAEVENT_H