void invite_OnPluginStart()
{
    RegConsoleCmd("sm_ginvite", Command_Invite);
    // RegConsoleCmd("sm_ginvites", Command_Invites);
    // RegConsoleCmd("sm_gaccept", Command_Invites);
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

    PlayerInviteList(inviter);

    return Plugin_Handled;
}

void PlayerInviteList(int inviter)
{
    Menu menu = new Menu(Menu_PlayerInviteList);
    menu.SetTitle("Menu - Invite - Choose a player");

    char sName[MAX_NAME_LENGTH], sUserID[12];
    
    LoopClients(iTarget)
    {
        if (g_pPlayer[iTarget].GangID == -1)
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
    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_invites` (`invitetime`, `gangid`, `playerid`, `inviterid`) VALUES (UNIX_TIMESTAMP(), '%d', '%d', '%d');", g_pPlayer[inviter].GangID, g_pPlayer[target].PlayerID, g_pPlayer[inviter].PlayerID);
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
    menu.ExitBackButton = false;
    menu.ExitButton = false;
    menu.Display(target, Config.InviteReactionTime.IntValue);
}

public int Menu_Invite(Menu menu, MenuAction action, int target, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[12];
        menu.GetItem(param, sParam, sizeof(sParam));

        if (StrEqual(sParam, "yes"))
        {

        }
        else if (StrEqual(sParam, "no"))
        {

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
