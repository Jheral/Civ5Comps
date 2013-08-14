#include "CvGameCoreDLLPCH.h"
#include "CvLuaEvent.h"

//Utility macro for registering methods
#define Method(Name)			\
	lua_pushcclosure(L, l##Name, 0);	\
	lua_setfield(L, t, #Name);

//------------------------------------------------------------------------------
void CvLuaEvent::PushMethods(lua_State* L, int t)
{
	Method(IsNone);
	Method(GetID);
	Method(GetEventType);
	Method(GetNumOptions);
	Method(GetOptionInfoType);
	Method(Trigger);
	Method(ProcessEventOption);
}

//------------------------------------------------------------------------------
void CvLuaEvent::HandleMissingInstance(lua_State* L)
{
	DefaultHandleMissingInstance(L);
}
//------------------------------------------------------------------------------
const char* CvLuaEvent::GetTypeName()
{
	return "Event";
}

//------------------------------------------------------------------------------
// Lua Methods
//------------------------------------------------------------------------------
//bool isNone();
int CvLuaEvent::lIsNone(lua_State* L)
{
	const bool bDoesNotExist = (GetInstance(L, 1, false) == NULL);
	lua_pushboolean(L, bDoesNotExist);

	return 1;
}

//int getID();
int CvLuaEvent::lGetID(lua_State* L)
{
	CvEvent* pkEvent = GetInstance(L);

	const int iResult = pkEvent->GetID();
	lua_pushinteger(L, iResult);
	return 1;
}

int CvLuaEvent::lGetEventType(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::getEventType);
}

int CvLuaEvent::lGetNumOptions(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::getNumOptions);
}

int CvLuaEvent::lGetOptionInfoType(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::getOptionInfoType);
}

int CvLuaEvent::lTrigger(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::trigger);
}

int CvLuaEvent::lProcessEventOption(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::processEventOption);
}