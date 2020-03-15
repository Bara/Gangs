static bool g_bName[MAXPLAYERS + 1] = { false, ... };
static bool g_bPrefix[MAXPLAYERS + 1] = { false, ... };

static char g_sName[MAXPLAYERS + 1][MAX_GANGS_NAME_LENGTH];
static char g_sPrefix[MAXPLAYERS + 1][MAX_GANGS_PREFIX_LENGTH];

void create_OnPluginStart()
{
    RegConsoleCmd("sm_gcreate", Command_CreateGang);
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

    if (g_pPlayer[client].GangID != -1)
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
            CPrintToChat(client, "Chat - Type your gang name (min. length: %d, max. length: %d) into the (public) chat or \"!abort\" to abort this process.", Config.NameMinLength.IntValue, Config.NameMaxLength.IntValue);
            g_bName[client] = true;
        }
        else if (StrEqual(sParam, "prefix", false))
        {
            CPrintToChat(client, "Chat - Type your gang prefix (min. length: %d, max. length: %d) into the (public) chat or \"!abort\" to abort this process.", Config.PrefixMinLength.IntValue, Config.PrefixMaxLength.IntValue);
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
            Format(g_sName[client], sizeof(g_sName[]), message);

            TrimString(g_sName[client]);
            StripQuotes(g_sName[client]);

            bool bRegex = IsStringValid(client, g_sName[client], "name", Config.NameRegex);

            int iLen = strlen(g_sName[client]);

            if (g_bDebug)
            {
                PrintToChat(client, "[OnClientSayCommand] (Name) bRegex: %d, Min: %d (iLen: %d, CVar: %d), Max: %d (iLen: %d, CVar: %d)", bRegex, (iLen >= Config.NameMinLength.IntValue), iLen, Config.NameMinLength.IntValue, (iLen <= Config.NameMaxLength.IntValue), iLen, Config.NameMaxLength.IntValue);
            }

            if (bRegex && iLen >= Config.NameMinLength.IntValue && iLen <= Config.NameMaxLength.IntValue)
            {
                if (g_bDebug)
                {
                    CPrintToChat(client, "Your gang name will be: %s", g_sName[client]);
                }
            }
            else
            {
                Format(g_sName[client], sizeof(g_sName[]), "");

                if (g_bDebug)
                {
                    CPrintToChat(client, "Gang name invalid.");
                }
            }
        }
        else if (g_bPrefix[client])
        {
            Format(g_sPrefix[client], sizeof(g_sPrefix[]), message);

            TrimString(g_sPrefix[client]);
            StripQuotes(g_sPrefix[client]);

            bool bRegex = IsStringValid(client, g_sPrefix[client], "prefix", Config.PrefixRegex);

            int iLen = strlen(g_sPrefix[client]);

            if (g_bDebug)
            {
                PrintToChat(client, "[OnClientSayCommand] (Prefix) bRegex: %d, Min: %d (iLen: %d, CVar: %d), Max: %d (iLen: %d, CVar: %d)", bRegex, (iLen >= Config.NameMinLength.IntValue), iLen, Config.NameMinLength.IntValue, (iLen <= Config.NameMaxLength.IntValue), iLen, Config.NameMaxLength.IntValue);
            }

            if (bRegex && iLen >= Config.PrefixMinLength.IntValue && iLen <= Config.PrefixMaxLength.IntValue)
            {
                if (g_bDebug)
                {
                    CPrintToChat(client, "Your gang prefix will be: %s", g_sPrefix[client]);
                }
            }
            else
            {
                Format(g_sPrefix[client], sizeof(g_sPrefix[]), "");

                if (g_bDebug)
                {
                    CPrintToChat(client, "Gang prefix invalid.");
                }
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

    bool bRegex = true;
    if(rRegex.Match(name) != 1)
    {
        CPrintToChat(client, "Chat - We found invalid chars in your gang %s!", type);
        bRegex = false;
    }

    delete rRegex;
    return bRegex;
}

void CheckNames(int client)
{
    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `id` FROM `gangs` WHERE `name` = \"%s\" OR `prefix` = \"%s\";", g_sName[client], g_sPrefix[client]);
    
    if (g_bDebug)
    {
        LogMessage("(CheckNames) \"%L\": \"%s\"", client, sQuery);
    }

    g_dDB.Query(Query_CheckNames, sQuery, GetClientUserId(client));
}

public void Query_CheckNames(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_CheckNames) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!IsClientValid(client))
    {
        return;
    }

    if (results.RowCount == 0)
    {
        CreateGang(client);
    }
    else
    {
        CPrintToChat(client, "Chat - Your name and/or prefix are already taken!");
        ResetCreateSettings(client);
    }
}

void CreateGang(int client)
{
    char sQuery[1024];

    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gangs` (`name`, `prefix`, `created`, `points`, `founder`) VALUES (\"%s\", \"%s\", UNIX_TIMESTAMP(), '0', \"%d\");", g_sName[client], g_sPrefix[client], g_pPlayer[client].PlayerID);
    
    if (g_bDebug)
    {
        LogMessage("(CreateGang) \"%L\": \"%s\"", client, sQuery);
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteString(g_sName[client]);
    pack.WriteString(g_sPrefix[client]);
    g_dDB.Query(Query_Insert_Gangs, sQuery, pack);
}

public void Query_Insert_Gangs(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Insert_Gangs) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();
    int userid = pack.ReadCell();

    char sName[32];
    pack.ReadString(sName, sizeof(sName));

    char sPrefix[16];
    pack.ReadString(sPrefix, sizeof(sPrefix));

    delete pack;

    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        int iGang = results.InsertId;

        if (g_bDebug)
        {
            CPrintToChat(client, "Your gang %s (%d) has been added to \"gangs\"-table!", sName, iGang);
        }

        Gang gang;
        gang.GangID = iGang;
        gang.Created = GetTime();
        strcopy(gang.Name, sizeof(Gang::Name), sName);
        strcopy(gang.Prefix, sizeof(Gang::Prefix), sPrefix);
        gang.Points = 0;
        gang.Founder = g_pPlayer[client].PlayerID;
        g_aGangs.PushArray(gang, sizeof(gang));

        Transaction action = new Transaction();

        char sQuery[1024];
        g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_settings` (`gangid`, `key`, `value`, `purchased`) VALUES ('%d', \"slots\", \"%d\", '1');", iGang, Config.StartSlots.IntValue);

        if (g_bDebug)
        {
            LogMessage("(Query_Insert_Gangs) \"%L\": \"%s\"", client, sQuery);
        }

        action.AddQuery(sQuery, -1);

        Settings setting;
        setting.GangID = iGang;
        Format(setting.Key, sizeof(Settings::Key), "slots");
        Config.StartSlots.GetString(setting.Value, sizeof(Settings::Value));
        setting.Bought = true;
        g_aGangSettings.PushArray(setting, sizeof(setting));

        ArrayList aRangs = AddRangsToTransaction(iGang, action);

        pack = new DataPack();
        pack.WriteCell(userid);
        pack.WriteCell(iGang);
        pack.WriteCell(aRangs);
        pack.WriteString(gang.Name);
        pack.WriteString(gang.Prefix);
        g_dDB.Execute(action, TXN_OnSuccess, TXN_OnError, pack);
    }
}

public void TXN_OnSuccess(Database db, DataPack pack, int numQueries, DBResultSet[] results, any[] queryData)
{
    if (g_bDebug)
    {
        LogMessage("(TXN_OnSuccess) numQueries: %d", numQueries);
    }

    pack.Reset();
    int userid = pack.ReadCell();
    int gangid = pack.ReadCell();
    ArrayList aRangs = view_as<ArrayList>(pack.ReadCell());
    char sName[32];
    pack.ReadString(sName, sizeof(sName));
    char sPrefix[16];
    pack.ReadString(sPrefix, sizeof(sPrefix));
    delete pack;

    for (int i = 0; i < numQueries; i++)
    {
        if (g_bDebug)
        {
            LogMessage("(TXN_OnSuccess) queryData[%d] - Process: %d", i, queryData[i]);
        }

        if (queryData[i] >= 1 && queryData[i] <= Config.MaxLevel.IntValue)
        {
            int iRang = results[i].InsertId;

            Rangs rRang;
            for (int j = 0; j < aRangs.Length; j++)
            {
                Rang rang;
                aRangs.GetArray(j, rang, sizeof(rang));

                if (queryData[i] == rang.Level)
                {
                    rRang.GangID = gangid;
                    rRang.RangID = iRang;
                    strcopy(rRang.Name, sizeof(Rangs::Name), rang.Name);
                    rRang.Level = rang.Level;
                    rRang.Invite = rang.Invite;
                    rRang.Kick = rang.Kick;
                    rRang.Promote = rang.Promote;
                    rRang.Demote = rang.Demote;
                    rRang.Upgrade = rang.Upgrade;
                    rRang.Manager = rang.Manager;
                    g_aGangRangs.PushArray(rRang, sizeof(rRang));
                }
            }

            int client = GetClientOfUserId(userid);

            if (IsClientValid(client) && queryData[i] == Config.MaxLevel.IntValue)
            {
                if (g_bDebug)
                {
                    LogMessage("(TXN_OnSuccess) ID for Rang Owner should be %d.", iRang);
                }

                pack = new DataPack();
                pack.WriteCell(userid);
                pack.WriteCell(gangid);
                pack.WriteCell(iRang);
                pack.WriteString(sName);
                pack.WriteString(sPrefix);

                char sQuery[512];
                g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_players` (`playerid`, `gangid`, `rang`) VALUES ('%d', '%d', '%d');", g_pPlayer[client].PlayerID, gangid, iRang);

                if (g_bDebug)
                {
                    LogMessage("(TXN_OnSuccess) \"%L\": \"%s\"", client, sQuery);
                }

                g_dDB.Query(Query_Insert_PlayerOwner, sQuery, pack);
            }
        }
    }

    // TODO: Reset
}

public void TXN_OnError(Database db, DataPack pack, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    LogError("(TXN_OnError) Error executing query (rang level: %d) %d of %d queries: %s", queryData[failIndex], failIndex, numQueries, error);
    delete pack;
}

public void Query_Insert_PlayerOwner(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Insert_PlayerOwner) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();

    int userid = pack.ReadCell();
    int gangid = pack.ReadCell();
    int rangid = pack.ReadCell();

    char sName[32];
    pack.ReadString(sName, sizeof(sName));

    char sPrefix[16];
    pack.ReadString(sPrefix, sizeof(sPrefix));

    delete pack;

    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        CPrintToChatAll("Chat - {player}%N {default}has been created a new Gang! Name: {highlight}%s{default}, Prefix: {highlight}%s", client, sName, sPrefix);

        InsertGangLogs(gangid, g_pPlayer[client].PlayerID, "create");
        InsertGangPlayerLogs(gangid, g_pPlayer[client].PlayerID, true, "create");

        g_pPlayer[client].GangID = gangid;
        g_pPlayer[client].RangID = rangid;
    }
}
