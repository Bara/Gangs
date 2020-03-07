static bool g_bName[MAXPLAYERS + 1] = { false, ... };
static bool g_bPrefix[MAXPLAYERS + 1] = { false, ... };

static char g_sName[MAXPLAYERS + 1][MAX_GANGS_NAME_LENGTH];
static char g_sPrefix[MAXPLAYERS + 1][MAX_GANGS_PREFIX_LENGTH];

void create_OnPluginStart()
{
    RegConsoleCmd("sm_creategang", Command_CreateGang);
}

public Action Command_CreateGang(int client, int args)
{
    ShowCreateGangMenu(client);
}

void ShowCreateGangMenu(int client)
{
    if (!IsClientValid(client))
    {
        return;
    }

    Menu menu = new Menu(Menu_CreateGang);
    menu.SetTitle("Menu - Setup your gang:\n ");

    bool bName = (strlen(g_sName[client]) > 1);
    bool bPrefix = (strlen(g_sPrefix[client]) > 1);

    if (!bName)
    {
        menu.AddItem("name", "Menu - Set Gang Name");
    }
    else
    {
        char sBuffer[128];
        Format(sBuffer, sizeof(sBuffer), "Menu - Set Gang Name\nName: %s", g_sName[client]);
        menu.AddItem("name", sBuffer);
    }
    if (!bPrefix)
    {
        menu.AddItem("prefix", "Menu - Set Gang Prefix");
    }
    else
    {
        char sBuffer[128];
        Format(sBuffer, sizeof(sBuffer), "Menu - Set Gang Prefix\nPrefix: %s\n ", g_sPrefix[client]);
        menu.AddItem("prefix", sBuffer);
    }

    if (bName && bPrefix)
    {
        menu.AddItem("create", "Create Gang");
    }
    
    menu.Display(client, MENU_TIME_FOREVER);
    menu.ExitBackButton = false;
    menu.ExitButton = true;
}

public int Menu_CreateGang(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[12];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (StrEqual(sParam, "name", false))
        {
            CPrintToChat(client, "Type your gang name (max. length: %d) into the (public) chat or \"!abort\" to abort this process.", Config.NameLength.IntValue);
            g_bName[client] = true;
        }
        else if (StrEqual(sParam, "prefix", false))
        {
            CPrintToChat(client, "Type your gang prefix (max. length: %d) into the (public) chat or \"!abort\" to abort this process.", Config.PrefixLength.IntValue);
            g_bPrefix[client] = true;
        }
        else if (StrEqual(sParam, "create", false))
        {
            CheckNames(client);
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

            bool bValid = IsStringValid(client, g_sName[client], "name", Config.NameRegex);

            int iLen = strlen(g_sName[client]);

            if (g_bDebug && bValid && iLen >= 2 && iLen <= Config.NameLength.IntValue)
            {
                CPrintToChat(client, "Your gang name will be: %s", g_sName[client]);   
            }
        }
        else if (g_bPrefix[client])
        {
            strcopy(g_sPrefix[client], sizeof(g_sPrefix[]), message);

            TrimString(g_sPrefix[client]);
            StripQuotes(g_sPrefix[client]);

            bool bValid = IsStringValid(client, g_sPrefix[client], "prefix", Config.PrefixRegex);

            int iLen = strlen(g_sPrefix[client]);

            if (g_bDebug && bValid && iLen >= 2 && iLen <= Config.PrefixLength.IntValue)
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

void CheckNames(int client)
{
    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `id` FROM `gangs` WHERE `name` = \"%s\" OR `prefix` = \"%s\"", g_sName[client], g_sPrefix[client]);
    g_dDB.Query(Query_CheckNames, sQuery, GetClientUserId(client));
}

void CreateGang(int client)
{
    char sQuery[1024];

    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gangs` (`name`, `prefix`, `created`, `points`, `founder`) VALUES (\"%s\", \"%s\", UNIX_TIMESTAMP(), '0', \"%d\")", g_sName[client], g_sPrefix[client], g_pPlayer[client].PlayerID);
    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteString(g_sName[client]);
    pack.WriteString(g_sPrefix[client]);
    g_dDB.Query(Query_InsertGangs, sQuery, pack);
}
