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
#include "gangs/connect.sp"
#include "gangs/create.sp"
#include "gangs/menu.sp"
#include "gangs/invite.sp"
#include "gangs/leave.sp"

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
    connect_OnPluginStart();
    create_OnPluginStart();
    menu_OnPluginStart();
    invite_OnPluginStart();
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
    g_pPlayer[client].GangID = -1;
    g_pPlayer[client].RangID = -1;
    g_pPlayer[client].Leaving = false;

    char sQuery[128];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `id`, `communityid`, `name` FROM `players` WHERE `communityid` = \"%s\";", g_pPlayer[client].CommunityID);

    if (g_bDebug)
    {
        LogMessage("(OnClientPutInServer) \"%L\": \"%s\"", client, sQuery);
    }

    g_dDB.Query(Query_Select_Player, sQuery, GetClientUserId(client));
}

public void OnClientDisconnect(int client)
{
    g_pPlayer[client].Leaving = true;

    invite_OnClientDisconnect(client);
    RemoveInactiveGangFromArrays(g_pPlayer[client].GangID);

    g_pPlayer[client].Leaving = false;
}
