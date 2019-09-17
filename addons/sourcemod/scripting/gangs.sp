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
#include "gangs/stocks.sp"
#include "gangs/sql.sp"
#include "gangs/create.sp"

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
    g_cNameLength = AutoExecConfig_CreateConVar("gangs_max_name_length", "32", "Maximal length of a gang name.", _, true, 2.0, true, 32.0);
    g_cPrefixLength = AutoExecConfig_CreateConVar("gangs_max_prefix_length", "16", "Maximal length of a gang prefix.", _, true, 2.0, true, 16.0);
    g_cNameRegex = AutoExecConfig_CreateConVar("gangs_name_regex", "^[a-zA-Z0-9 _,.!#+*]+$", "Allowed characters in gang name. (Default: \"^[a-zA-Z0-9 _,.!#+*]+$\"");
    g_cPrefixRegex = AutoExecConfig_CreateConVar("gangs_prefix_regex", "^[a-zA-Z0-9 _,.!#+*]+$", "Allowed characters in gang prefix. (Default: \"^[a-zA-Z0-9 _,.!#+*]+$\"");
    g_cStartSlots = AutoExecConfig_CreateConVar("gangs_start_slots", "4", "With how many slots should start a gang after creation?", _, true, 1.0);
    g_cMaxLevel = AutoExecConfig_CreateConVar("gangs_max_rank_level", "10", "What should be the highest level for ranks? This could be used for max gang ranks.", _, true, 10.0);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    CSetPrefix("{green}[ Gangs ]{default}");

    sql_OnPluginStart();
    create_OnPluginStart();
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
