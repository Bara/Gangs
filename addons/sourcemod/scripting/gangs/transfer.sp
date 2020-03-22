void ShowTransferPlayerlist(int owner)
{
    Menu menu = new Menu(Menu_GangTransferPlayer);
    menu.SetTitle("Choose new owner:");

    char sPlayer[MAX_NAME_LENGTH];
    char sUserID[12];

    LoopClients(i)
    {
        if (i != owner && (!Config.TransferToMembers.BoolValue || Config.TransferToMembers.BoolValue && g_pPlayer[i].GangID == g_pPlayer[owner].GangID))
        {
            if (GetClientName(i, sPlayer, sizeof(sPlayer)))
            {
                IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
                menu.AddItem(sUserID, sPlayer, ITEMDRAW_DISABLED);
            }
        }
    }

    menu.ExitBackButton = true;
    menu.ExitButton = true;
    menu.Display(owner, MENU_TIME_FOREVER);
}

public int Menu_GangTransferPlayer(Menu menu, MenuAction action, int owner, int param)
{
    if (action == MenuAction_Cancel)
    {
        if(param == MenuCancel_ExitBack)
        {
            ShowGangMenu(owner);
        }
        else
        {
            char sUserID[12];
            menu.GetItem(param, sUserID, sizeof(sUserID));

            int target = GetClientOfUserId(StringToInt(sUserID));

            if (!IsClientValid(target))
            {
                CPrintToChat(owner, "Chat - Target is no longer valid");
                return;
            }

            if (g_pPlayer[owner].GangID == g_pPlayer[target].GangID)
            {
                if (Config.TransferRank.BoolValue)
                {
                    int iTargetRank = g_pPlayer[target].RankID;

                    g_pPlayer[target].RankID = g_pPlayer[owner].RankID;
                    g_pPlayer[owner].RankID = iTargetRank;
                }
                else
                {
                    g_pPlayer[target].RankID = g_pPlayer[owner].RankID;
                    g_pPlayer[owner].RankID = GetTrialRankID(g_pPlayer[owner].GangID);
                }
            }
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}
