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
	Method(GetOption);
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

int CvLuaEvent::lGetOption(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::getOption);
}

int CvLuaEvent::lTrigger(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::trigger);
}

int CvLuaEvent::lProcessEventOption(lua_State* L)
{
	return BasicLuaMethod(L, &CvEvent::processEventOption);
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

void CvLuaEventEffects::PushMethods(lua_State* L, int t)
{
	Method(GetEventType);
	Method(GetOption);
	Method(GetAction);
	Method(SetAction);
	Method(SetType);
	Method(GetType);
	Method(GetValue);
	Method(SetValue);
	Method(GetNumTurns);
	Method(SetNumTurns);
	Method(ChangeNumTurns);
}

//------------------------------------------------------------------------------
void CvLuaEventEffects::HandleMissingInstance(lua_State* L)
{
	DefaultHandleMissingInstance(L);
}
//------------------------------------------------------------------------------
const char* CvLuaEventEffects::GetTypeName()
{
	return "EventEffects";
}

int CvLuaEventEffects::lGetEventType(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::getEventType);
}

int CvLuaEventEffects::lGetOption(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::getOption);
}

int CvLuaEventEffects::lGetAction(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::getAction);
}

int CvLuaEventEffects::lSetAction(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::setAction);
}

int CvLuaEventEffects::lSetType(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::setType);
}

int CvLuaEventEffects::lGetType(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::getType);
}

int CvLuaEventEffects::lGetValue(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::getValue);
}

int CvLuaEventEffects::lSetValue(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::setValue);
}

int CvLuaEventEffects::lGetNumTurns(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::getNumTurns);
}

int CvLuaEventEffects::lSetNumTurns(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::setNumTurns);
}

int CvLuaEventEffects::lChangeNumTurns(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffects::changeNumTurns);
}