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
	static int lGetOption(lua_State* L);

	static int lTrigger(lua_State* L);
	static int lProcessEventOption(lua_State* L);

};

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

class CvLuaEventEffects : public CvLuaScopedInstance<CvLuaEventEffects, CvEventEffects>
{
public:

	//! Push CvEvent methods into table t
	static void PushMethods(lua_State* L, int t);

	//! Required by CvLuaScopedInstance.
	static void HandleMissingInstance(lua_State* L);

	//! Required by CvLuaScopedInstance.
	static const char* GetTypeName();

protected:
	static int lGetEventType(lua_State* L);
	static int lGetOption(lua_State* L);
	static int lGetAction(lua_State* L);
	static int lSetAction(lua_State* L);
	static int lSetType(lua_State* L);
	static int lGetType(lua_State* L);
	static int lGetValue(lua_State* L);
	static int lSetValue(lua_State* L);
	static int lGetNumTurns(lua_State* L);
	static int lSetNumTurns(lua_State* L);
	static int lChangeNumTurns(lua_State* L);

};


#endif //CVLUAEVENT_H