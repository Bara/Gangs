void menu_OnPluginStart()
{
    RegConsoleCmd("sm_gang", Command_Gang);
}

public Action Command_Gang(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Handled;
    }

    if (g_pPlayer[client].GangID == -1)
    {
        ReplyToCommand(client, "Chat - You are not in a Gang");
        return Plugin_Handled;
    }

    ShowGangMenu(client);

    return Plugin_Handled;
}

void ShowGangMenu(int client)
{
    Profiler profiler = new Profiler();
    profiler.Start();

    char sName[MAX_GANGS_NAME_LENGTH], sPrefix[MAX_GANGS_PREFIX_LENGTH], sRank[sizeof(Rank::Name)];

    int iSlots = GetGangSlots(g_pPlayer[client].GangID);
    GetGangName(g_pPlayer[client].GangID, sName, sizeof(sName));
    GetGangPrefix(g_pPlayer[client].GangID, sPrefix, sizeof(sPrefix));
    
    int iOnline = GetGangOnlineCount(g_pPlayer[client].GangID);
    GetRankName(g_pPlayer[client].GangID, g_pPlayer[client].RankID, sRank, sizeof(sRank));

    if (g_bDebug)
    {
        PrintToChat(client, "(ShowGangMenu) Name: %s, Prefix: %s", sName, sPrefix);
    }

    Menu menu = new Menu(Menu_GangMain);
    menu.SetTitle("%s | %s\n \nOnline: %d/%d\nPoints: %d\n \nYour rank: %s", sPrefix, sName, iOnline, iSlots, sRank);
    menu.AddItem("online", "Online players");
    menu.AddItem("players", "All players\n ");

    if (!IsClientOwner(client))
    {
        menu.AddItem("leave", "Leave gang");
    }
    else
    {
        menu.AddItem("transfer", "Transfer ownership");
        menu.AddItem("delete", "Delete gang");
    }
    
    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);

    profiler.Stop();
    PrintToChat(client, "Time elapsed to build this menu: %.f seconds", profiler.Time);
    delete profiler;
}

public int Menu_GangMain(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[18];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (StrEqual(sParam, "online", false))
        {
            ShowGangOnlinePlayers(client);
        }
        else if (StrEqual(sParam, "players", false))
        {
            ShowGangPlayers(client);
        }
        else if (StrEqual(sParam, "leave", false))
        {
            ShowGangLeaveConfirmation(client);
        }
        else if (StrEqual(sParam, "transfer", false))
        {
            ShowTransferPlayerlist(client);
        }
        else if (StrEqual(sParam, "delete", false))
        {
            ConfirmGangDeletion(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void ShowGangOnlinePlayers(int client)
{
    char sName[MAX_GANGS_NAME_LENGTH], sPrefix[MAX_GANGS_PREFIX_LENGTH];

    GetGangName(g_pPlayer[client].GangID, sName, sizeof(sName));
    GetGangPrefix(g_pPlayer[client].GangID, sPrefix, sizeof(sPrefix));

    Menu menu = new Menu(Menu_GangOnlinePlayers);
    menu.SetTitle("%s | %s\nPlayers online:\n ", sPrefix, sName);

    char sPlayer[MAX_NAME_LENGTH];
    LoopClients(i)
    {
        if (g_pPlayer[i].GangID == g_pPlayer[client].GangID)
        {
            if (GetClientName(i, sPlayer, sizeof(sPlayer)))
            {
                menu.AddItem("", sPlayer, ITEMDRAW_DISABLED);
            }
        }
    }

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_GangOnlinePlayers(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Cancel)
    {
        if(param == MenuCancel_ExitBack)
        {
            ShowGangMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    
}

void ShowGangPlayers(int client)
{
    char sQuery[256];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT players.name, gang_ranks.rank FROM players, gang_players, gang_ranks WHERE gang_players.gangid = '%d' AND gang_players.playerid = players.id AND gang_players.rank = gang_ranks.id;", g_pPlayer[client].GangID);
    g_dDB.Query(menu_Query_Select_GangPlayers, sQuery, GetClientUserId(client));
}

public void menu_Query_Select_GangPlayers(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(menu_Query_Select_GangPlayers) Error: %s", error);
        return;
    }
    
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
            char sName[MAX_GANGS_NAME_LENGTH], sPrefix[MAX_GANGS_PREFIX_LENGTH];

            GetGangName(g_pPlayer[client].GangID, sName, sizeof(sName));
            GetGangPrefix(g_pPlayer[client].GangID, sPrefix, sizeof(sPrefix));

            Menu menu = new Menu(Menu_GangPlayers);
            menu.SetTitle("%s | %s\nAll players:\n ", sPrefix, sName);

            char sPlayer[MAX_NAME_LENGTH];
            char sRank[24];
            char sText[MAX_NAME_LENGTH + 32];

            while (results.FetchRow())
            {
                results.FetchString(0, sPlayer, sizeof(sPlayer));
                results.FetchString(1, sRank, sizeof(sRank));

                Format(sText, sizeof(sText), "%s | %s", sRank, sPlayer);
                menu.AddItem("", sText, ITEMDRAW_DISABLED);
            }

            menu.ExitBackButton = true;
            menu.ExitButton = true;
            menu.Display(client, MENU_TIME_FOREVER);

    }
}

public int Menu_GangPlayers(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Cancel)
    {
        if(param == MenuCancel_ExitBack)
        {
            ShowGangMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    
}
