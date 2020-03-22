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

                UpdateMySQLRanks(owner, target);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void UpdateMySQLRanks(int iOwner, int iTarget)
{
    char sQuery[128];
    g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `gang_players` SET rang = '%d' WHERE `playerid` = '%d';", g_pPlayer[iOwner].RankID, g_pPlayer[iOwner].PlayerID);

    DataPack pack = new DataPack();
    pack.WriteCell(g_pPlayer[iTarget].PlayerID);
    pack.WriteCell(g_pPlayer[iTarget].RankID);
    pack.WriteCell(g_pPlayer[iOwner].PlayerID);

    g_dDB.Query(transfer_Query_Update_RankOwner, sQuery, pack);
}

public void transfer_Query_Update_RankOwner(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(transfer_Query_Update_RankOwner) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();
    int iTargetID = pack.ReadCell();
    int iRankID = pack.ReadCell();
    int iOwnerID = pack.ReadCell();
    delete pack;

    char sQuery[128];
    g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `gang_players` SET rang = '%d' WHERE `playerid` = '%d';", iRankID, iTargetID);

    pack = new DataPack();
    pack.WriteCell(iTargetID);
    pack.WriteCell(iOwnerID);

    g_dDB.Query(transfer_Query_Update_RankTarget, sQuery, pack);
}

public void transfer_Query_Update_RankTarget(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(transfer_Query_Update_RankTarget) Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();

    int iTarget = GetClientOfPlayerID(pack.ReadCell());
    int iOwner = GetClientOfPlayerID(pack.ReadCell());

    delete pack;

    CPrintToGang(g_pPlayer[iTarget].GangID, "Chat - %N transferred the gang ownership to %N", iOwner, iTarget);
}
