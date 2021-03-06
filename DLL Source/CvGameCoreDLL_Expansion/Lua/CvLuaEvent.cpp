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
	Method(GetToolTip);
	Method(GetToolTipByOptionID);
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

int CvLuaEvent::lGetToolTip(lua_State* L)
{
	CvString toolTip;
	CvEvent* pkEvent = GetInstance(L);
	const int iOption = lua_tointeger(L, 2);

	pkEvent->getToolTip(iOption, &toolTip);

	lua_pushstring(L, toolTip.c_str());
	return 1;
}

int CvLuaEvent::lGetToolTipByOptionID(lua_State* L)
{
	CvString toolTip;
	CvEvent* pkEvent = GetInstance(L);
	const int iOption = lua_tointeger(L, 2);

	for (int iI = 0; iI < pkEvent->getNumOptions(); iI++)
	{
		if (pkEvent->getOption(iI) == iOption)
		{
			pkEvent->getToolTip(iI, &toolTip);
			break;
		}
	}
		

	lua_pushstring(L, toolTip.c_str());
	return 1;
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

void CvLuaEventEffects::PushMethods(lua_State* L, int t)
{
	Method(GetEventType);
	Method(GetOption);
	Method(GetEventAction);
	Method(GetAction);
	Method(GetType);
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
	return BasicLuaMethod(L, &CvEventEffect::getEventType);
}

int CvLuaEventEffects::lGetOption(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffect::getOption);
}

int CvLuaEventEffects::lGetEventAction(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffect::getEventAction);
}

int CvLuaEventEffects::lGetAction(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffect::getAction);
}

int CvLuaEventEffects::lGetType(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffect::getTypeToAction);
}
int CvLuaEventEffects::lGetNumTurns(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffect::getNumTurns);
}

int CvLuaEventEffects::lSetNumTurns(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffect::setNumTurns);
}

int CvLuaEventEffects::lChangeNumTurns(lua_State* L)
{
	return BasicLuaMethod(L, &CvEventEffect::changeNumTurns);
}