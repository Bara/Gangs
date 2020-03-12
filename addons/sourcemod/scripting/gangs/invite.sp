void invite_OnPluginStart()
{
    RegConsoleCmd("sm_ginvite", Command_Invite);
    // RegConsoleCmd("sm_ginvites", Command_Invites);
    // RegConsoleCmd("sm_gaccept", Command_Invites);
}

public Action Command_Invite(int client, int args)
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

    if (!HasClientPermission(client, PERM_INVITE))
    {
        ReplyToCommand(client, "Chat - You can not invite players");
        return Plugin_Handled;
    }

    PlayerInviteList(client);

    return Plugin_Handled;
}

void PlayerInviteList(int client)
{
    Menu menu = new Menu(Menu_PlayerInviteList);
    menu.SetTitle("Menu - Invite - Choose a player");

    char sName[MAX_NAME_LENGTH], sUserID[12];
    
    LoopClients(target)
    {
        if (g_pPlayer[client].GangID == -1)
        {
            if (!GetClientName(target, sName, sizeof(sName)))
            {
                return;
            }

            IntToString(GetClientUserId(target), sUserID, sizeof(sUserID));
            menu.AddItem(sUserID, sName);
        }
    }

    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_PlayerInviteList(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sUserID[12];
        menu.GetItem(param, sUserID, sizeof(sUserID));

        int iUserID = StringToInt(sUserID);
        int target = GetClientOfUserId(iUserID);

        if (IsClientValid(target))
        {
            	
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}
