bool IsValidDatabase(Database db, const char[] error)
{
    if (db == null || strlen(error))
    {
        return false;
    }

    return true;
}

void LateLoadPlayers()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientValid(i))
        {
            OnClientPutInServer(i);
        }
    }
}

ArrayList AddRangsToTransaction(int gangid, Transaction action)
{
    char sFile[PLATFORM_MAX_PATH + 1];
    BuildPath(Path_SM, sFile, sizeof(sFile), "configs/gangs/default_rangs.cfg");

    if (!FileExists(sFile))
    {
        SetFailState("(AddRangsToTransaction) The config file \"%s\" doesn't exist!", sFile);
        return null;
    }

    KeyValues kvConfig = new KeyValues("Gangs");

    if (!kvConfig.ImportFromFile(sFile))
    {
        SetFailState("(AddRangsToTransaction) Can't read \"%s\"! (ImportFromFile)", sFile);
        delete kvConfig;
        return null;
    }

    if (!kvConfig.JumpToKey("Rangs"))
    {
        SetFailState("(AddRangsToTransaction) Can't read \"%s\"! (JumpToKey.Rangs)", sFile);
        delete kvConfig;
        return null;
    }

    ArrayList aRangs = new ArrayList(sizeof(Rang));

    Rang rang;
    Format(rang.Name, sizeof(Rang::Name), "Owner");
    rang.Level = Config.MaxLevel.IntValue;
    rang.Invite = true;
    rang.Kick = true;
    rang.Promote = true;
    rang.Demote = true;
    rang.Upgrade = true;
    rang.Manager = true;
    aRangs.PushArray(rang, sizeof(rang));

    Format(rang.Name, sizeof(Rang::Name), "Trial");
    rang.Level = 1;
    rang.Invite = false;
    rang.Kick = false;
    rang.Promote = false;
    rang.Demote = false;
    rang.Upgrade = false;
    rang.Manager = false;
    aRangs.PushArray(rang, sizeof(rang));

    if (kvConfig.GotoFirstSubKey(false))
    {
        do
        {
            kvConfig.GetSectionName(rang.Name, sizeof(Rang::Name));
            rang.Level = kvConfig.GetNum("Level", -1);
            rang.Invite = view_as<bool>(kvConfig.GetNum("Invite", -1));
            rang.Kick = view_as<bool>(kvConfig.GetNum("Kick", -1));
            rang.Promote = view_as<bool>(kvConfig.GetNum("Promote", -1));
            rang.Demote = view_as<bool>(kvConfig.GetNum("Demote", -1));
            rang.Upgrade = view_as<bool>(kvConfig.GetNum("Upgrade", -1));
            rang.Manager = view_as<bool>(kvConfig.GetNum("Manager", -1));

            if (rang.Level < Config.MaxLevel.IntValue)
            {
                aRangs.PushArray(rang, sizeof(rang));
            }
            else
            {
                // TODO: Reset
            }

        } while (kvConfig.GotoNextKey(false));

        kvConfig.GoBack();
    }
    kvConfig.GoBack();


    char sQuery[1024];
    for (int i = 0; i < aRangs.Length; i++)
    {
        aRangs.GetArray(i, rang, sizeof(rang));
        
        if (g_bDebug)
        {
            LogMessage("(AddRangsToTransaction) Rang: %s, iLevel: %d, iInvite: %d, iKick: %d, iPromote: %d, iDemote: %d, iUpgrade: %d, iManager: %d", rang.Name, rang.Level, rang.Invite, rang.Kick, rang.Promote, rang.Demote, rang.Upgrade, rang.Manager);
        }

        g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_rangs` (`gangid`, `rang`, `level`, `perm_invite`, `perm_kick`, `perm_promote`, `perm_demote`, `perm_upgrade`, `perm_manager`) VALUES ('%d', \"%s\", '%d', '%d', '%d', '%d', '%d', '%d', '%d');", gangid, rang.Name, rang.Level, rang.Invite, rang.Kick, rang.Promote, rang.Demote, rang.Upgrade, rang.Manager);

        if (g_bDebug)
        {
            LogMessage("(AddRangsToTransaction) Query: \"%s\"", sQuery);
        }

        action.AddQuery(sQuery, rang.Level);
    }

    delete kvConfig;
    return aRangs;
}

bool GetGangName(int id, char[] name, int length)
{
    LoopArray(g_aGangs, i)
    {
        Gang gang;
        g_aGangs.GetArray(i, gang, sizeof(Gang));

        if (gang.GangID == id)
        {
            Format(name, length, gang.Name);
            return true;
        }
    }

    return false;
}

bool GetGangPrefix(int id, char[] name, int length)
{
    LoopArray(g_aGangs, i)
    {
        Gang gang;
        g_aGangs.GetArray(i, gang, sizeof(Gang));

        if (gang.GangID == id)
        {
            Format(name, length, gang.Prefix);
            return true;
        }
    }

    return false;
}

void InsertGangLogs(int gangid, int playerid, const char[] type)
{
    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_logs` (`gangid`, `time`, `playerid`, `type`) VALUES ('%d', UNIX_TIMESTAMP(), '%d', \"%s\");", gangid, playerid, type);

    if (g_bDebug)
    {
        LogMessage("(InsertGangLogs - %s) PlayerID \"%d\": \"%s\"", type, playerid, sQuery);
    }

    g_dDB.Query(Query_Insert_GangLogs, sQuery);
}

public void Query_Insert_GangLogs(Database db, DBResultSet results, const char[] error, any data)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Insert_GangLogs) Error: %s", error);
        return;
    }
}

void InsertGangPlayerLogs(int gangid, int playerid, bool join, const char[] reason)
{
    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_logs_players` (`gangid`, `time`, `playerid`, `join`, `reason`) VALUES ('%d', UNIX_TIMESTAMP(), '%d', '%d', \"%s\");", gangid, playerid, join, reason);

    if (g_bDebug)
    {
        LogMessage("(InsertGangPlayerLogs) PlayerID \"%d\": \"%s\"", playerid, sQuery);
    }

    g_dDB.Query(Query_Insert_GangPlayerLogs, sQuery);
}

public void Query_Insert_GangPlayerLogs(Database db, DBResultSet results, const char[] error, any data)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Insert_GangPlayerLogs) Error: %s", error);
        return;
    }
}

bool HasClientPermission(int client, Permissions perm)
{
    LoopArray(g_aGangRangs, i)
    {
        Rangs rang;
        g_aGangRangs.GetArray(i, rang, sizeof(Rangs));

        if (rang.GangID == g_pPlayer[client].GangID && rang.RangID == g_pPlayer[client].RangID)
        {
            if (perm == PERM_INVITE && rang.Invite)
            {
                return true;
            }
            else if (perm == PERM_KICK && rang.Kick)
            {
                return true;
            }
            else if (perm == PERM_PROMOTE && rang.Promote)
            {
                return true;
            }
            else if (perm == PERM_DEMOTE && rang.Demote)
            {
                return true;
            }
            else if (perm == PERM_UPGRADE && rang.Upgrade)
            {
                return true;
            }else if (perm == PERM_MANAGER && rang.Manager)
            {
                return true;
            }
        }
    }

    return false;
}

int GetClientOfPlayerID(int playerid)
{
    LoopClients(client)
    {
        if (g_pPlayer[client].PlayerID == playerid)
        {
            return client;
        }
    }

    return -1;
}

int GetLowerGangRang(int gangid)
{
    int iRang = -1;
    int iLevel = -1;
    LoopArray(g_aGangRangs, i)
    {
        Rangs rang;
        g_aGangRangs.GetArray(i, rang, sizeof(rang));

        if (rang.GangID == gangid)
        {
            if (iLevel == -1 || iLevel > rang.Level)
            {
                iLevel = rang.Level;
                iRang = rang.RangID;
            }
        }
    }

    return iRang;
}

public void Query_DoNothing(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    pack.Reset();
    char sFrom[64];
    pack.ReadString(sFrom, sizeof(sFrom));
    delete pack;

    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_DoNothing) (%s) Error: %s", sFrom, error);
        return;
    }
}

void CPrintToGang(int gangid, const char[] message, any ...)
{
    char buffer[MAX_MESSAGE_LENGTH];
    VFormat(buffer, sizeof(buffer), message, 3);

    LoopClients(client)
    {
        if (g_pPlayer[client].GangID == gangid)
        {
            CPrintToChat(client, buffer);
        }
    }
}

bool IsGangValid(int gangid)
{
    LoopArray(g_aGangs, i)
    {
        Gang gang;
        g_aGangs.GetArray(i, gang, sizeof(gang));

        if (gang.GangID == gangid)
        {
            return true;
        }
    }

    return false;
}

bool AreGangSettingsLoaded(int gangid)
{
    LoopArray(g_aGangSettings, i)
    {
        Settings setting;
        g_aGangSettings.GetArray(i, setting, sizeof(setting));

        if (setting.GangID == gangid)
        {
            return true;
        }
    }

    return false;
}

bool AreGangRangsLoaded(int gangid)
{
    LoopArray(g_aGangRangs, i)
    {
        Rangs rang;
        g_aGangRangs.GetArray(i, rang, sizeof(rang));

        if (rang.GangID == gangid)
        {
            return true;
        }
    }

    return false;
}

void RemoveInactiveGangFromArrays()
{
    bool bPlayers = false;
    bool bInvites = false;

    LoopArray(g_aGangs, i)
    {
        Gang gang;
        g_aGangs.GetArray(i, gang, sizeof(gang));

        LoopClients(client)
        {
            if (!g_pPlayer[client].Leaving && g_pPlayer[client].GangID == gang.GangID)
            {
                bPlayers = true;
                break;
            }
        }

        if (!bPlayers)
        {
            if (g_bDebug)
            {
                LogMessage("No players found... Removing rangs and settings for %s.", gang.Name);
            }

            RemoveRangsFromArray(gang.GangID);
            RemoveSettingsFromArray(gang.GangID);
        }

        LoopArray(g_aPlayerInvites, j)
        {
            Invite invite;
            g_aPlayerInvites.GetArray(j, invite, sizeof(invite));

            if (invite.GangID == gang.GangID)
            {
                bInvites = true;
                break;
            }
        }

        if (!bInvites && !bPlayers)
        {
            if (g_bDebug)
            {
                LogMessage("No players or invites found... Removing %s from gangs array.", gang.Name);
            }

            RemoveGangFromArray(gang.GangID);
        }
    }
}

void RemoveRangsFromArray(int gangid)
{
    LoopArray(g_aGangRangs, i)
    {
        Rangs rang;
        g_aGangRangs.GetArray(i, rang, sizeof(rang));

        if (rang.GangID == gangid)
        {
            g_aGangRangs.Erase(i);
        }
    }
}

void RemoveSettingsFromArray(int gangid)
{
    LoopArray(g_aGangSettings, i)
    {
        Settings setting;
        g_aGangSettings.GetArray(i, setting, sizeof(setting));

        if (setting.GangID == gangid)
        {
            g_aGangSettings.Erase(i);
        }
    }
}

void RemoveGangFromArray(int gangid)
{
    LoopArray(g_aGangs, i)
    {
        Gang gang;
        g_aGangs.GetArray(i, gang, sizeof(gang));

        if (gang.GangID == gangid)
        {
            g_aGangs.Erase(i);
        }
    }
}

bool IsClientOwner(int client)
{
    bool bOwner = false;
    LoopArray(g_aGangRangs, i)
    {
        Rangs rang;
        g_aGangRangs.GetArray(i, rang, sizeof(rang));

        if (g_pPlayer[client].GangID == rang.GangID)
        {
            if (StrEqual(rang.Name, "Owner", false))
            {
                bOwner = true;
                break;
            }
        }
    }

    return bOwner;
}
