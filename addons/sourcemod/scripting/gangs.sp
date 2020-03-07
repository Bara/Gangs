#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <regex>
#include <autoexecconfig>
#include <multicolors>
#include <gangs>

bool g_bDebug = true;

#include "gangs/structs.sp"
#include "gangs/globals.sp"
#include "gangs/configs.sp"
#include "gangs/stocks.sp"
#include "gangs/sql.sp"
#include "gangs/create.sp"

public Plugin myinfo =
{
    name = GANGS_PLUGIN_NAME, 
    author = GANGS_PLUGIN_AUTHOR, 
    description = GANGS_PLUGIN_DESCRIPTION, 
    version = GANGS_PLUGIN_VERSION, 
    url = GANGS_PLUGIN_URL
};

public void OnPluginStart()
{
    configs_OnPluginStart();
    sql_OnPluginStart();
    create_OnPluginStart();
}

public void OnConfigsExecuted()
{
    char sBuffer[PLATFORM_MAX_PATH];
    Config.PluginPrefix.GetString(sBuffer, sizeof(sBuffer));
    CSetPrefix(sBuffer);
}

public void OnClientPutInServer(int client)
{
    if (!IsClientValid(client))
    {
        return;
    }

    if (!GetClientAuthId(client, AuthId_SteamID64, g_pPlayer[client].CommunityID, sizeof(Player::CommunityID)))
    {
        return;
    }

    g_pPlayer[client].PlayerID = -1;
    g_pPlayer[client].InGang = false;
    g_pPlayer[client].GangID = -1;
    g_pPlayer[client].Rank = -1;

    char sQuery[128];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `id`, `communityid`, `name` FROM `players` WHERE `communityid` = \"%s\"", g_pPlayer[client].CommunityID);
    LogMessage("Select \"%L\": \"%s\"", client, sQuery);
    g_dDB.Query(Query_SelectPlayer, sQuery, GetClientUserId(client));
}
