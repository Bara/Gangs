#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#include "gangs/globals.sp"
#include "gangs/stocks.sp"
#include "gangs/sql.sp"

public Plugin myinfo =
{
    name = "Gangs", 
    author = "Bara", 
    description = "", 
    version = "1.0.0", 
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    sql_OnPluginStart();
}