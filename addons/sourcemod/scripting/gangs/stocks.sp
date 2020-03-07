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

ArrayList AddRanksToTransaction(int gangid, Transaction action)
{
    char sFile[PLATFORM_MAX_PATH + 1];
    BuildPath(Path_SM, sFile, sizeof(sFile), "configs/gangs/default_ranks.cfg");

    if (!FileExists(sFile))
    {
        SetFailState("(AddRanksToTransaction) The config file \"%s\" doesn't exist!", sFile);
        return null;
    }

    KeyValues kvConfig = new KeyValues("Gangs");

    if (!kvConfig.ImportFromFile(sFile))
    {
        SetFailState("(AddRanksToTransaction) Can't read \"%s\"! (ImportFromFile)", sFile);
        delete kvConfig;
        return null;
    }

    if (!kvConfig.JumpToKey("Ranks"))
    {
        SetFailState("(AddRanksToTransaction) Can't read \"%s\"! (JumpToKey.Ranks)", sFile);
        delete kvConfig;
        return null;
    }

    ArrayList aRanks = new ArrayList(sizeof(Rank));

    Rank rank;
    Format(rank.Name, sizeof(Rank::Name), "Owner");
    rank.Level = Config.MaxLevel.IntValue;
    rank.Invite = true;
    rank.Kick = true;
    rank.Promote = true;
    rank.Demote = true;
    rank.Upgrade = true;
    rank.Manager = true;
    aRanks.PushArray(rank, sizeof(rank));

    if (kvConfig.GotoFirstSubKey(false))
    {
        do
        {
            kvConfig.GetSectionName(rank.Name, sizeof(Rank::Name));
            rank.Level = kvConfig.GetNum("Level", -1);
            rank.Invite = view_as<bool>(kvConfig.GetNum("Invite", -1));
            rank.Kick = view_as<bool>(kvConfig.GetNum("Kick", -1));
            rank.Promote = view_as<bool>(kvConfig.GetNum("Promote", -1));
            rank.Demote = view_as<bool>(kvConfig.GetNum("Demote", -1));
            rank.Upgrade = view_as<bool>(kvConfig.GetNum("Upgrade", -1));
            rank.Manager = view_as<bool>(kvConfig.GetNum("Manager", -1));

            if (rank.Level < Config.MaxLevel.IntValue)
            {
                aRanks.PushArray(rank, sizeof(rank));
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
    for (int i = 0; i < aRanks.Length; i++)
    {
        aRanks.GetArray(i, rank, sizeof(rank));
        
        if (g_bDebug)
        {
            LogMessage("(AddRanksToTransaction) Rank: %s, iLevel: %d, iInvite: %d, iKick: %d, iPromote: %d, iDemote: %d, iUpgrade: %d, iManager: %d", rank.Name, rank.Level, rank.Invite, rank.Kick, rank.Promote, rank.Demote, rank.Upgrade, rank.Manager);
        }

        g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_ranks` (`gangid`, `rank`, `level`, `perm_invite`, `perm_kick`, `perm_promote`, `perm_demote`, `perm_upgrade`, `perm_manager`) VALUES ('%d', \"%s\", '%d', '%d', '%d', '%d', '%d', '%d', '%d')", gangid, rank.Name, rank.Level, rank.Invite, rank.Kick, rank.Promote, rank.Demote, rank.Upgrade, rank.Manager);

        if (g_bDebug)
        {
            LogMessage("(AddRanksToTransaction) Query: \"%s\"", sQuery);
        }

        action.AddQuery(sQuery, rank.Level);
    }

    delete kvConfig;
    return aRanks;
}
