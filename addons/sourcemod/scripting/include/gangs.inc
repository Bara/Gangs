#if defined _gangs_included
 #endinput
#endif
#define _gangs_included

#define MAX_GANG_NAME_LENGTH 32
#define MAX_GANG_PREFIX_LENGTH 16

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
