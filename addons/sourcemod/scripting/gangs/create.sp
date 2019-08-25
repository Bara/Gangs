static bool g_bName[MAXPLAYERS + 1] = { false, ... };
static bool g_bPrefix[MAXPLAYERS + 1] = { false, ... };

static char g_sName[MAXPLAYERS + 1][MAX_GANG_NAME_LENGTH];
static char g_sPrefix[MAXPLAYERS + 1][MAX_GANG_PREFIX_LENGTH];

void create_OnPluginStart()
{
    RegConsoleCmd("sm_creategang", Command_CreateGang);
}

public Action Command_CreateGang(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Handled;
    }

    if (g_bPrefix[client] || g_bName[client]) {}

    Menu menu = new Menu(Menu_CreateGang);
    menu.SetTitle("Menu - Setup your gang:\n ");

    if (strlen(g_sName[client]) < 2)
    {
        menu.AddItem("name", "Menu - Set Gang Name");
    }
    else
    {
        char sBuffer[128];
        Format(sBuffer, sizeof(sBuffer), "Menu - Set Gang Name\nName: %s", g_sName[client]);
        menu.AddItem("name", sBuffer);
    }
    if (strlen(g_sPrefix[client]) < 2)
    {
        menu.AddItem("prefix", "Menu - Set Gang Prefix");
    }
    else
    {
        char sBuffer[128];
        Format(sBuffer, sizeof(sBuffer), "Menu - Set Gang Prefix\nPrefix: %s", g_sPrefix[client]);
        menu.AddItem("prefix", sBuffer);
    }
    
    menu.Display(client, MENU_TIME_FOREVER);
    menu.ExitBackButton = false;
    menu.ExitButton = true;
    return Plugin_Continue;
}

public int Menu_CreateGang(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[12];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (StrEqual(sParam, "name"))
        {
            CPrintToChat(client, "Type your gang name (max. length: %d) into the (public) chat or \"!abort\" to abort this process.", g_cNameLength.IntValue);
            g_bName[client] = true;
        }
        else if (StrEqual(sParam, "prefix"))
        {
            CPrintToChat(client, "Type your gang prefix (max. length: %d) into the (public) chat or \"!abort\" to abort this process.", g_cPrefixLength.IntValue);
            g_bPrefix[client] = true;
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
    if (IsClientValid(client) && CheckClientStatus(client))
    {
        if (StrEqual(message, "!abort", false))
        {
            ResetCreateSettings(client);
            return Plugin_Stop;
        }

        if (g_bName[client])
        {
            strcopy(g_sName[client], sizeof(g_sName[]), message);

            TrimString(g_sName[client]);
            StripQuotes(g_sName[client]);

            bool bValid = IsStringValid(client, g_sName[client], "name", g_cNameRegex);

            int iLen = strlen(g_sName[client]);

            if (bValid && iLen >= 2 && iLen <= g_cNameLength.IntValue)
            {
                CPrintToChat(client, "Your gang name will be: %s", g_sName[client]);   
            }
        }
        else if (g_bPrefix[client])
        {
            strcopy(g_sPrefix[client], sizeof(g_sPrefix[]), message);

            TrimString(g_sPrefix[client]);
            StripQuotes(g_sPrefix[client]);

            bool bValid = IsStringValid(client, g_sPrefix[client], "prefix", g_cPrefixRegex);

            int iLen = strlen(g_sPrefix[client]);

            if (bValid && iLen >= 2 && iLen <= g_cPrefixLength.IntValue)
            {
                CPrintToChat(client, "Your gang prefix will be: %s", g_sPrefix[client]);   
            }
        }

        g_bName[client] = false;
        g_bPrefix[client] = false;

        Command_CreateGang(client, 0);

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

bool CheckClientStatus(int client)
{
    return (g_bName[client] || g_bPrefix[client]);
}

void ResetCreateSettings(int client)
{
    g_bName[client] = false;
    Format(g_sName[client], sizeof(g_sName[]), "");

    g_bPrefix[client] = false;
    Format(g_sPrefix[client], sizeof(g_sPrefix[]), "");
}

bool IsStringValid(int client, const char[] name, const char[] type, ConVar cvar)
{
    char sRegex[128];
    cvar.GetString(sRegex, sizeof(sRegex));
    Regex rRegex = new Regex(sRegex);

    bool bValid = true;
    if(rRegex.Match(name) != 1)
    {
        CPrintToChat(client, "Chat - We found invalid chars in your gang %s!", type);
        bValid = false;
    }

    delete rRegex;
    return bValid;
}
