void ConfirmGangDeletion(int owner)
{
    char sName[MAX_GANGS_NAME_LENGTH], sPrefix[MAX_GANGS_PREFIX_LENGTH];
    GetGangName(g_pPlayer[owner].GangID, sName, sizeof(sName));
    GetGangPrefix(g_pPlayer[owner].GangID, sPrefix, sizeof(sPrefix));

    Menu menu = new Menu(Menu_ConfirmDeletion);
    menu.SetTitle("Are you sure to delete your gang?\nName: %s - Prefix: %s\nThis action is permanently and can not be restored.", sName, sPrefix);
    menu.AddItem("yes", "Yes, delete my gang!");
    menu.AddItem("no", "No, I keep my gang.");
    menu.ExitBackButton = false;
    menu.ExitButton = false;
    menu.Display(owner, MENU_TIME_FOREVER);
}

public int Menu_ConfirmDeletion(Menu menu, MenuAction action, int owner, int param)
{
    if (action == MenuAction_Select)
    {
        char sOption[6];

        menu.GetItem(param, sOption, sizeof(sOption));

        if (StrEqual(sOption, "yes"))
        {
            DeleteGang(owner);
        }
        else
        {
            ShowGangMenu(owner);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void DeleteGang(int owner)
{
    int iGang = g_pPlayer[owner].GangID;

    char sName[MAX_GANGS_NAME_LENGTH];
    GetGangName(g_pPlayer[owner].GangID, sName, sizeof(sName));
    
    LoopClients(client)
    {
        if (g_pPlayer[client].GangID == iGang)
        {
            g_pPlayer[client].GangID = -1;
            g_pPlayer[client].RankID = -1;
        }
    }
    
    RemoveInvitesFromArray(iGang);
    RemoveRanksFromArray(iGang);
    RemoveSettingsFromArray(iGang);
    RemoveGangFromArray(iGang);

    Transaction action = new Transaction();

    char sQuery[256];
    g_dDB.Format(sQuery, sizeof(sQuery), "DELETE FROM `gang_invites` WHERE `gangid` = '%d';", iGang);
    action.AddQuery(sQuery);
    g_dDB.Format(sQuery, sizeof(sQuery), "DELETE FROM `gang_settings` WHERE `gangid` = '%d';", iGang);
    action.AddQuery(sQuery);
    g_dDB.Format(sQuery, sizeof(sQuery), "DELETE FROM `gang_ranks` WHERE `gangid` = '%d';", iGang);
    action.AddQuery(sQuery);
    g_dDB.Format(sQuery, sizeof(sQuery), "DELETE FROM `gang_players` WHERE `gangid` = '%d';", iGang);
    action.AddQuery(sQuery);
    g_dDB.Format(sQuery, sizeof(sQuery), "DELETE FROM `gangs` WHERE `id` = '%d';", iGang);
    action.AddQuery(sQuery);
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_logs` (`gangid`, `time`, `playerid`, `type`) VALUES ('%d', UNIX_TIMESTAMP(), '%d', \"delete\");", iGang, g_pPlayer[owner].PlayerID);
    action.AddQuery(sQuery);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(owner));
    pack.WriteString(sName);
    g_dDB.Execute(action, delete_TXN_OnSuccess, delete_TXN_OnError, pack);
}

public void delete_TXN_OnSuccess(Database db, DataPack pack, int numQueries, DBResultSet[] results, any[] queryData)
{
    if (g_bDebug)
    {
        LogMessage("(delete_TXN_OnSuccess) numQueries: %d", numQueries);
    }

    pack.Reset();
    int owner = GetClientOfUserId(pack.ReadCell());
    char sName[32];
    pack.ReadString(sName, sizeof(sName));
    delete pack;

    if (IsClientValid(owner))
    {
        CPrintToChatAll("Chat - %N deleted his gang %s", owner, sName);
    }
}

public void delete_TXN_OnError(Database db, DataPack pack, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    LogError("(delete_TXN_OnError) Error executing query (rank level: %d) %d of %d queries: %s", queryData[failIndex], failIndex, numQueries, error);
    delete pack;
}
