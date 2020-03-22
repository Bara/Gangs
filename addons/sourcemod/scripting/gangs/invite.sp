void invite_OnPluginStart()
{
    RegConsoleCmd("sm_ginvite", Command_Invite);
    RegConsoleCmd("sm_ginvites", Command_Invites);
}

void invite_OnClientDisconnect(int client)
{
    RemovePlayerInvitesFromArray(client);
}

void invite_LoadPlayerInvites(int client)
{
    char sQuery[256];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `gangid`, `inviterid`, `playerid` FROM `gang_invites` WHERE `playerid` = '%d' AND accepted IS NULL;", g_pPlayer[client].PlayerID);

    if (g_bDebug)
    {
        LogMessage("(invite_LoadPlayerInvites) \"%L\": \"%s\"", client, sQuery);
    }

    g_dDB.Query(Query_Select_GangInvite, sQuery, GetClientUserId(client));
}

public Action Command_Invite(int inviter, int args)
{
    if (!IsClientValid(inviter))
    {
        return Plugin_Handled;
    }

    if (g_pPlayer[inviter].GangID == -1)
    {
        ReplyToCommand(inviter, "Chat - You are not in a Gang");
        return Plugin_Handled;
    }

    if (!HasClientPermission(inviter, PERM_INVITE))
    {
        ReplyToCommand(inviter, "Chat - You can not invite players");
        return Plugin_Handled;
    }

    ShowPlayerListMenu(inviter);

    return Plugin_Handled;
}

void ShowPlayerListMenu(int inviter)
{
    Menu menu = new Menu(Menu_PlayerInviteList);
    menu.SetTitle("Menu - Invite - Choose a player");

    char sName[MAX_NAME_LENGTH], sUserID[12];
    
    LoopClients(iTarget)
    {
        if (g_pPlayer[iTarget].GangID == -1 && !DoesPlayerInviteExist(iTarget, g_pPlayer[inviter].GangID))
        {
            if (!GetClientName(iTarget, sName, sizeof(sName)))
            {
                return;
            }

            IntToString(GetClientUserId(iTarget), sUserID, sizeof(sUserID));
            menu.AddItem(sUserID, sName);
        }
    }

    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(inviter, MENU_TIME_FOREVER);
}

public int Menu_PlayerInviteList(Menu menu, MenuAction action, int inviter, int param)
{
    if (action == MenuAction_Select)
    {
        char sUserID[12];
        menu.GetItem(param, sUserID, sizeof(sUserID));

        int iUserID = StringToInt(sUserID);
        int iTarget = GetClientOfUserId(iUserID);

        if (IsClientValid(iTarget) && g_pPlayer[iTarget].GangID == -1)
        {
            InvitePlayer(inviter, iTarget);

            CPrintToChat(inviter, "Invite sent to %N", iTarget);
            CPrintToChat(iTarget, "%N has invite you to his gang.", inviter);
        }
        else
        {
            ReplyToCommand(inviter, "Chat - Player is no longer available");
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void InvitePlayer(int inviter, int target)
{
    Invite invite;
    invite.GangID = g_pPlayer[inviter].GangID;
    invite.PlayerID =  g_pPlayer[target].PlayerID;
    invite.InviterID =  g_pPlayer[inviter].PlayerID;
    g_aPlayerInvites.PushArray(invite, sizeof(invite));

    char sQuery[256];
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_invites` (`invitetime`, `gangid`, `playerid`, `inviterid`) VALUES (UNIX_TIMESTAMP(), '%d', '%d', '%d');", invite.GangID, invite.PlayerID, invite.InviterID);

    if (g_bDebug)
    {
        LogMessage("(InvitePlayer) \"%L\": \"%s\"", inviter, sQuery);
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(inviter));
    pack.WriteCell(GetClientUserId(target));
    g_dDB.Query(Query_Insert_GangInvite, sQuery, pack);
}

public void Query_Insert_GangInvite(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Insert_GangInvite) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();

    int inviter = GetClientOfUserId(pack.ReadCell());
    int target = GetClientOfUserId(pack.ReadCell());

    delete pack;

    if (!IsClientValid(inviter) || !IsClientValid(target))
    {
        return;
    }

    char sName[MAX_GANGS_NAME_LENGTH], sPrefix[MAX_GANGS_PREFIX_LENGTH];

    GetGangName(g_pPlayer[inviter].GangID, sName, sizeof(sName));
    GetGangPrefix(g_pPlayer[inviter].GangID, sPrefix, sizeof(sPrefix));

    Menu menu = new Menu(Menu_Invite);
    menu.SetTitle("Menu - You have been invited to\n%s | %s\nInvited by: %N", sPrefix, sName, inviter);
    menu.AddItem("yes", "Menu - Accept invite");
    menu.AddItem("no", "Menu - Decline invite");

    char sBuffer[12];

    IntToString(g_pPlayer[inviter].PlayerID, sBuffer, sizeof(sBuffer));
    menu.AddItem("inviterid", sBuffer, ITEMDRAW_IGNORE);

    IntToString(g_pPlayer[inviter].GangID, sBuffer, sizeof(sBuffer));
    menu.AddItem("gangid", sBuffer, ITEMDRAW_IGNORE);

    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(target, Config.InviteReactionTime.IntValue);
}

public int Menu_Invite(Menu menu, MenuAction action, int target, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[24];
        char sID[12];
        int iInviterID = -1;
        int iGangID = -1;

        for (int i = 0; i < menu.ItemCount; i++)
        {
            menu.GetItem(i, sParam, sizeof(sParam), _, sID, sizeof(sID));

            if (StrEqual("inviterid", sParam))
            {
                iInviterID = StringToInt(sID);
            }
            else if (StrEqual("gangid", sParam))
            {
                iGangID = StringToInt(sID);
            }
        }

        menu.GetItem(param, sParam, sizeof(sParam));

        if (StrEqual(sParam, "yes"))
        {
            AddPlayerToGang(target, iGangID);
        }
        else if (StrEqual(sParam, "no"))
        {
            RemovePlayerInvitesFromArray(target, iGangID);

            char sQuery[256];
            g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `gang_invites` SET `accepted` = '0', `updatetime` = UNIX_TIMESTAMP() WHERE `playerid` = '%d' AND `gangid` = '%d';", g_pPlayer[target].PlayerID, iGangID);

            if (g_bDebug)
            {
                LogMessage("(Menu_Invite) \"%L\": \"%s\"", target, sQuery);
            }

            DataPack pack = new DataPack();
            pack.WriteCell(iInviterID);
            pack.WriteCell(GetClientUserId(target));
            g_dDB.Query(Query_Update_GangInvite0, sQuery, pack);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param < MenuCancel_Disconnected)
        {
            CPrintToChat(target, "Chat - Invite timeout");
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public void Query_Update_GangInvite0(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Update_GangInvite0) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();

    int inviter = GetClientOfPlayerID(pack.ReadCell());
    int target = GetClientOfUserId(pack.ReadCell());

    delete pack;

    if (!IsClientValid(inviter) || !IsClientValid(target))
    {
        return;
    }

    CPrintToChat(inviter, "Chat - Target (%N) has declined your invite", target);
}

public void Query_Select_GangInvite(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Select_GangInvite) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!IsClientValid(client))
    {
        return;
    }

    if(results.RowCount > 0)
    {
        while (results.FetchRow())
        {
            Invite invite;
            invite.GangID = results.FetchInt(0);
            invite.InviterID = results.FetchInt(1);
            invite.PlayerID = results.FetchInt(2);
            g_aPlayerInvites.PushArray(invite, sizeof(invite));

            if (g_bDebug)
            {
                LogMessage("(Query_Select_GangInvite) Adding invite (GangID: %d, InviterID: %d, PlayerID: %d) to arraylist.", invite.GangID, invite.InviterID, invite.PlayerID);
            }

            if (!IsGangValid(invite.GangID))
            {
                LoadGang(invite.GangID);
            }
        }
    }
}

bool DoesPlayerInviteExist(int target, int gangid = -1)
{
    LoopArray(g_aPlayerInvites, i)
    {
        Invite invite;
        g_aPlayerInvites.GetArray(i, invite, sizeof(Invite));

        if (g_pPlayer[target].PlayerID == invite.PlayerID && (gangid == -1 || gangid == invite.GangID))
        {
            return true;
        }
    }

    return false;
}

void RemovePlayerInvitesFromArray(int client, int gangid = -1)
{
    LoopArrayNegative(g_aPlayerInvites, i)
    {
        Invite invite;
        g_aPlayerInvites.GetArray(i, invite, sizeof(Invite));

        if (g_pPlayer[client].PlayerID == invite.PlayerID && (gangid == -1 || gangid == invite.GangID))
        {
            g_aPlayerInvites.Erase(i);
        }
    }
}

void AddPlayerToGang(int target, int gangid, int rank = -1)
{
    RemovePlayerInvitesFromArray(target, gangid);

    if (AreGangSettingsLoaded(gangid))
    {
        LoadSettings(gangid);
    }

    if (AreGangRanksLoaded(gangid))
    {
        LoadRanks(gangid);
    }

    char sQuery[256];
    g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `gang_invites` SET `accepted` = '1', `updatetime` = UNIX_TIMESTAMP() WHERE `playerid` = '%d' AND `gangid` = '%d';", g_pPlayer[target].PlayerID, gangid);

    if (g_bDebug)
    {
        LogMessage("(AddPlayerToGang) \"%L\": \"%s\"", target, sQuery);
    }

    DataPack pack1 = new DataPack();
    pack1.WriteString("AddPlayerToGang - Accepted 1");
    g_dDB.Query(Query_DoNothing, sQuery, pack1);


    g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `gang_invites` SET `accepted` = '0', `updatetime` = UNIX_TIMESTAMP() WHERE `playerid` = '%d' AND `gangid` != '%d';", g_pPlayer[target].PlayerID, gangid);

    if (g_bDebug)
    {
        LogMessage("(AddPlayerToGang) \"%L\": \"%s\"", target, sQuery);
    }

    DataPack pack2 = new DataPack();
    pack2.WriteString("AddPlayerToGang - Accepted 0");
    g_dDB.Query(Query_DoNothing, sQuery, pack2);


    if (rank == -1)
    {
        rank = GetTrialRankID(gangid);
    }

    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_players` (`playerid`, `gangid`, `rank`) VALUES ('%d', '%d', '%d');", g_pPlayer[target].PlayerID, gangid, rank);

    if (g_bDebug)
    {
        LogMessage("(AddPlayerToGang) \"%L\": \"%s\"", target, sQuery);
    }

    DataPack pack3 = new DataPack();
    pack3.WriteCell(GetClientUserId(target));
    pack3.WriteCell(gangid);
    pack3.WriteCell(rank);
    g_dDB.Query(Query_Insert_GangPlayers, sQuery, pack3);

    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_logs_players` (`gangid`, `time`, `playerid`, `join`, `reason`) VALUES ('%d', UNIX_TIMESTAMP(), '%d', '1', \"Join\");", gangid, g_pPlayer[target].PlayerID);
    
    if (g_bDebug)
    {
        LogMessage("(AddPlayerToGang) \"%L\": \"%s\"", target, sQuery);
    }
    
    DataPack pack4 = new DataPack();
    pack4.WriteString("AddPlayerToGang - Player Log");
    g_dDB.Query(Query_DoNothing, sQuery, pack4);
}

public void Query_Insert_GangPlayers(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Insert_GangPlayers) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();

    int target = GetClientOfUserId(pack.ReadCell());
    int iGang = pack.ReadCell();
    int iRank = pack.ReadCell();

    delete pack;

    if (!IsClientValid(target))
    {
        return;
    }

    g_pPlayer[target].GangID = iGang;
    g_pPlayer[target].RankID = iRank;

    char sName[MAX_GANGS_NAME_LENGTH];
    GetGangName(iGang, sName, sizeof(sName));
    CPrintToGang(iGang, "Chat - {prefix}[%s] {player}%N {default}has joined the gang.", sName, target);
}

public Action Command_Invites(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Handled;
    }

    if (g_pPlayer[client].GangID > 0)
    {
        CReplyToCommand(client, "You are already in a gang.");
        return Plugin_Handled;
    }

    ShowPlayerInvites(client);

    return Plugin_Handled;
}

void ShowPlayerInvites(int client)
{
    if (!DoesPlayerInviteExist(client))
    {
        CPrintToChat(client, "Chat - No invite");
        return;
    }

    Menu menu = new Menu(Menu_PlayerInvites);
    menu.SetTitle("Select gang to accept the invite.\nBy accepting an invite,\nwill all others invites will declined.");

    char sName[MAX_GANGS_NAME_LENGTH];
    char sPrefix[MAX_GANGS_PREFIX_LENGTH];
    char sText[MAX_GANGS_NAME_LENGTH + MAX_GANGS_PREFIX_LENGTH + 4];
    char sID[12];

    LoopArray(g_aPlayerInvites, i)
    {
        Invite invite;
        g_aPlayerInvites.GetArray(i, invite, sizeof(invite));

        if (invite.PlayerID == g_pPlayer[client].PlayerID)
        {
            GetGangName(invite.GangID, sName, sizeof(sName));
            GetGangPrefix(invite.GangID, sPrefix, sizeof(sPrefix));
            Format(sText, sizeof(sText), "%s (%s)", sName, sPrefix);
            IntToString(invite.GangID, sID, sizeof(sID));

            menu.AddItem(sID, sText);
        }
    }

    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_PlayerInvites(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sID[12];
        menu.GetItem(param, sID, sizeof(sID));

        int iGang = StringToInt(sID);


        if (IsGangValid(iGang))
        {
            AddPlayerToGang(client, iGang);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}
