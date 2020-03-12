#if defined _gangs_included
 #endinput
#endif
#define _gangs_included

#define GANGS_PLUGIN_NAME "Gangs"
#define GANGS_PLUGIN_AUTHOR "Bara"
#define GANGS_PLUGIN_DESCRIPTION ""
#define GANGS_PLUGIN_VERSION "<VERSION>"
#define GANGS_PLUGIN_URL "https://github.com/Bara/Gangs"

#define MAX_GANGS_NAME_LENGTH 32
#define MAX_GANGS_PREFIX_LENGTH 16

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))
#define LoopArray(%1,%2) for (int %2 = 0; %2 < %1.Length; %2++)

enum Permissions
{
    PERM_INVITE = 0,
    PERM_KICK,
    PERM_PROMOTE,
    PERM_DEMOTE,
    PERM_UPGRADE,
    PERM_MANAGER
}

stock bool IsClientValid(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
        {
            return true;
        }
    }

    return false;
}

public SharedPlugin __pl_gangs =
{
    name = "gangs",
    file = "gangs.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_gangs_SetNTVOptional()
{
    
}
#endif
