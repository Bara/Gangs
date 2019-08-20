#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <autoexecconfig>
#include <multicolors>

#include "gangs/structs.sp"
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
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("gangs");
    g_cNameRegex = AutoExecConfig_CreateConVar("gangs_name_regex", "^[a-zA-Z0-9 _,.!/#+-*]+$", "Allowed characters in gang name. (Default: \"^[a-zA-Z0-9 _,.!/#+-*]+$\"");
    g_cPrefixRegex = AutoExecConfig_CreateConVar("gangs_prefix_regex", "^[a-zA-Z0-9 _,.!/#+-*]+$", "Allowed characters in gang prefix. (Default: \"^[a-zA-Z0-9 _,.!/#+-*]+$\"");
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    CSetPrefix("{green}[ Gangs ]{default}");

    if (g_cNameRegex || g_cPrefixRegex) {}

    sql_OnPluginStart();
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client) || IsClientSourceTV(client))
    {
        return;
    }

    if (!GetClientAuthId(client, AuthId_SteamID64, g_pPlayer[client].CommunityID, sizeof(Player::CommunityID)))
    {
        return;
    }

    char sQuery[128];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `id`, `communityid`, `name` FROM `players` WHERE `communityid` = \"%s\"", g_pPlayer[client].CommunityID);
    LogMessage("Select \"%L\": \"%s\"", client, sQuery);
    g_dDB.Query(Query_SelectPlayer, sQuery, GetClientUserId(client));
}
