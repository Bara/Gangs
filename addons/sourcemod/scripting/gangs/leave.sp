void ShowGangLeaveConfirmation(int client)
{
    char sName[MAX_GANGS_NAME_LENGTH], sPrefix[MAX_GANGS_PREFIX_LENGTH];
    GetGangName(g_pPlayer[client].GangID, sName, sizeof(sName));
    GetGangPrefix(g_pPlayer[client].GangID, sPrefix, sizeof(sPrefix));

    Menu menu = new Menu(Menu_GangLeave);
    menu.SetTitle("%s | %s\nAre you sure to leave the gang?", sPrefix, sName);
    menu.AddItem("yes", "Yes, I am.");
    menu.AddItem("no", "No, I stay here.");
    menu.ExitBackButton = false;
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_GangLeave(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sOption[6];
        menu.GetItem(param, sOption, sizeof(sOption));

        if (StrEqual(sOption, "yes", false))
        {
            LeaveGang(client);
        }
        else if (StrEqual(sOption, "no", false))
        {
            ShowGangMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void LeaveGang(int client)
{
    /*
        TODO:
            - Config: Remove invites
                - Array: Invite::InviterID
                - MySQL: gang_invites (UPDATE)
    */

    char sQuery[256];
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_logs_players` (`gangid`, `time`, `playerid`, `join`, `reason`) VALUES ('%d', UNIX_TIMESTAMP(), '%d', '0', \"Leave\");", g_pPlayer[client].GangID, g_pPlayer[client].PlayerID);
    
    if (g_bDebug)
    {
        LogMessage("(LeaveGang) \"%L\": \"%s\"", client, sQuery);
    }
    
    DataPack pack1 = new DataPack();
    pack1.WriteString("LeaveGang - Player Log");
    g_dDB.Query(Query_DoNothing, sQuery, pack1);

    if (Config.RemoveInvites.BoolValue)
    {
        g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `gang_invites` SET `accepted` = '0', `updatetime` = UNIX_TIMESTAMP() WHERE `inviterid` = '%d';", g_pPlayer[client].PlayerID);
        
        if (g_bDebug)
        {
            LogMessage("(LeaveGang) \"%L\": \"%s\"", client, sQuery);
        }
        
        DataPack pack2 = new DataPack();
        pack2.WriteString("LeaveGang - Update invites");
        g_dDB.Query(Query_DoNothing, sQuery, pack2);

        RemoveInviterInvitesFromArray(client);
    }

    g_dDB.Format(sQuery, sizeof(sQuery), "DELETE FROM `gang_players` WHERE `playerid` = '%d';", g_pPlayer[client].PlayerID);

    if (g_bDebug)
    {
        LogMessage("(LeaveGang) \"%L\": \"%s\"", client, sQuery);
    }
    
    DataPack pack3 = new DataPack();
    pack3.WriteCell(GetClientUserId(client));
    pack3.WriteCell(g_pPlayer[client].GangID);
    g_dDB.Query(Query_Delete_GangPlayer, sQuery, pack3);
}


public void Query_Delete_GangPlayer(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Delete_GangPlayer) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();

    int client = GetClientOfUserId(pack.ReadCell());
    int iGang = pack.ReadCell();

    delete pack;

    g_pPlayer[client].GangID = -1;
    g_pPlayer[client].RangID = -1;

    if (IsClientValid(client))
    {
        CPrintToGang(iGang, "Chat - %N left the gang.", client);
        CPrintToChat(client, "Chat - You left the gang.");
    }

    RemoveInactiveGangFromArrays();
}

void RemoveInviterInvitesFromArray(int client)
{
    LoopArray(g_aPlayerInvites, i)
    {
        Invite invite;
        g_aPlayerInvites.GetArray(i, invite, sizeof(Invite));

        if (g_pPlayer[client].PlayerID == invite.InviterID)
        {
            g_aPlayerInvites.Erase(i);
        }
    }
}
