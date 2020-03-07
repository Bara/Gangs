static int iTables = 8;
static int iCount = 0;

static char sQueries[][] = {
    "CREATE TABLE IF NOT EXISTS `players` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `communityid` VARCHAR(18) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `name` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `firstseen` INT NOT NULL, \
        `lastseen` INT NOT NULL, \
        KEY (`communityid`, `name`), \
        KEY (`communityid`), \
        UNIQUE KEY (`communityid`), \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
    
    " \
    CREATE TABLE IF NOT EXISTS `gangs` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `name` VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `prefix` VARCHAR(16) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `created` INT NOT NULL, \
        `points` INT NOT NULL, \
        `founder` VARCHAR(18) COLLATE utf8mb4_unicode_ci NOT NULL, \
        UNIQUE KEY (`name`), \
        UNIQUE KEY (`prefix`), \
        UNIQUE KEY (`founder`), \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    " \
    CREATE TABLE IF NOT EXISTS `gang_settings` ( \
        `gangid` INT NOT NULL, \
        `key` VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `value` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `purchased` TINYINT NOT NULL, \
        UNIQUE KEY (`gangid`, `key`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    " \
    CREATE TABLE IF NOT EXISTS `gang_ranks` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `gangid` INT NOT NULL, \
        `rank` VARCHAR(24) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `level` TINYINT NOT NULL, \
        `perm_invite` TINYINT NOT NULL, \
        `perm_kick` TINYINT NOT NULL, \
        `perm_promote` TINYINT NOT NULL, \
        `perm_demote` TINYINT NOT NULL, \
        `perm_upgrade` TINYINT NOT NULL, \
        `perm_manager` TINYINT NOT NULL, \
        UNIQUE KEY (`gangid`, `rank`), \
        UNIQUE KEY (`gangid`, `level`), \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
    
    " \
    CREATE TABLE IF NOT EXISTS `gang_players` ( \
        `playerid` INT NOT NULL, \
        `gangid` INT NOT NULL, \
        `rank` TINYINT NOT NULL, \
        UNIQUE KEY (`playerid`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    " \
    CREATE TABLE IF NOT EXISTS `gang_logs_settings` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `gangid` INT NOT NULL, \
        `time` INT NOT NULL, \
        `playerid` INT NOT NULL, \
        `key` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `amount` INT NOT NULL, \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    " \
    CREATE TABLE IF NOT EXISTS `gang_logs_players` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `gangid` INT NOT NULL, \
        `time` INT NOT NULL, \
        `playerid` INT NOT NULL, \
        `join` TINYINT NOT NULL, \
        `reason` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    " \
    CREATE TABLE IF NOT EXISTS `gang_logs_points` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `gangid` INT NOT NULL, \
        `time` INT NOT NULL, \
        `playerid` INT NOT NULL, \
        `add` TINYINT NOT NULL, \
        `amount` INT NOT NULL, \
        `reason` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
};

static char sTables[][] = {
    "players", "gangs", "gang_settings", "gang_ranks", "gang_players",
    "gang_logs_settings", "gang_logs_players", "gang_logs_points"
};

void sql_OnPluginStart()
{
    if (!SQL_CheckConfig("gangs"))
    {
        SetFailState("Cannot find \"%s\" in your databases.cfg file", "gangs");
        return;
    }

    Database.Connect(OnSQLConnect, "gangs");
}

public void OnSQLConnect(Database db, const char[] error, any data)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(OnSQLConnect) Connection to database has been failed! Error: %s", error);
        return;
    }

    char sDriver[8];
    db.Driver.GetIdentifier(sDriver, sizeof(sDriver));

    if (!StrEqual(sDriver, "mysql", false))
    {
        SetFailState("(OnSQLConnect) We found an invalid driver (%s). This plugins supports only mysql!", sDriver);
        return;
    }

    g_dDB = db;

    if (!g_dDB.SetCharset("utf8mb4"))
    {
        g_dDB.SetCharset("utf8");
    }

    iCount = 0;

    CreateTables();
}

void CreateTables()
{
    for(int i; i < sizeof(sTables); i++)
    {
        LogMessage("Table %d: \"%s\"", (i + 1), sQueries[i]);
        g_dDB.Query(Query_CreateTable, sQueries[i], i);
    }
}

public void Query_CreateTable(Database db, DBResultSet results, const char[] error, int table)
{
    if (!IsValidDatabase(db, error))
    {
        char sTable[16];
        IntToString(table, sTable, sizeof(sTable));
        SetFailState("(Query_CreateTable) Table creation for the table \"%s\" failed. Error: %s", sTables[table], error);
        return;
    }

    iCount++;

    LogMessage("(Query_CreateTable) Table %d of %d created.", iCount, iTables);

    if (iCount == iTables)
    {
        delete g_aGangs;
        delete g_aGangSettings;
        delete g_aGangRanks;

        g_aGangs = new ArrayList(sizeof(Gang));
        g_aGangSettings = new ArrayList(sizeof(Settings));
        g_aGangRanks = new ArrayList(sizeof(Ranks));

        LateLoadPlayers(); // TODO: Move this when gang stuff is completely loaded
    }
}

public void Query_SelectPlayer(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_SelectPlayer) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!IsClientValid(client))
    {
        return;
    }

    LogMessage("(Query_SelectPlayer) UserID: %d (Client: %d), Rows: %d", userid, client, results.RowCount);

    if (results.RowCount == 0)
    {
        char sQuery[512];
        g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `players` (`communityid`, `name`, `firstseen`, `lastseen`) VALUES (\"%s\", \"%N\", UNIX_TIMESTAMP(), UNIX_TIMESTAMP())", g_pPlayer[client].CommunityID, client);
        LogMessage("Insert \"%L\": \"%s\"", client, sQuery);
        g_dDB.Query(Query_InsertPlayer, sQuery, userid);
    }
    else
    {
        if (results.RowCount == 1 && results.FetchRow())
        {
            g_pPlayer[client].PlayerID = results.FetchInt(0);

            char sQuery[512];
            g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `players` SET `name` = \"%N\", `lastseen` = UNIX_TIMESTAMP() WHERE `communityid` = \"%s\"", client, g_pPlayer[client].CommunityID);
            LogMessage("Update \"%L\"<%d>: \"%s\"", client, g_pPlayer[client].PlayerID, sQuery);
            g_dDB.Query(Query_UpdatePlayer, sQuery);
        }
        else
        {
            LogError("we have more rows for \"%N\". Query stopped!", client);
            return;
        }
    }
}

public void Query_InsertPlayer(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_InsertPlayer) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        g_pPlayer[client].PlayerID = results.InsertId;
    }
}

public void Query_UpdatePlayer(Database db, DBResultSet results, const char[] error, any data)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_UpdatePlayer) Error: %s", error);
        return;
    }
}

public void Query_CheckNames(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_CheckNames) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!IsClientValid(client))
    {
        return;
    }

    if (results.RowCount == 0)
    {
        CreateGang(client);
    }
    else
    {
        CPrintToChat(client, "Your name and/or prefix are already taken!");
        ResetCreateSettings(client);
    }
}

public void Query_InsertGangs(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_InsertGangs) Error: %s", error);
        return;
    }

    pack.Reset();
    int userid = pack.ReadCell();

    char sName[32];
    pack.ReadString(sName, sizeof(sName));

    char sPrefix[16];
    pack.ReadString(sPrefix, sizeof(sPrefix));

    delete pack;

    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        int iGang = results.InsertId;
        if (g_bDebug)
        {
            CPrintToChat(client, "Your gang %s (%d) has been added to \"gangs\"-table!", sName, iGang);
        }

        Gang gang;
        gang.GangID = iGang;
        gang.Created = GetTime();
        strcopy(gang.Name, sizeof(Gang::Name), sName);
        strcopy(gang.Prefix, sizeof(Gang::Prefix), sPrefix);
        gang.Points = 0;
        gang.Founder = g_pPlayer[client].PlayerID;
        g_aGangs.PushArray(gang, sizeof(gang));

        Transaction action = new Transaction();

        char sQuery[1024];
        g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_settings` (`gangid`, `key`, `value`, `purchased`) VALUES ('%d', \"slots\", \"%d\", '1')", iGang, Config.StartSlots.IntValue);
        action.AddQuery(sQuery, -1);

        Settings setting;
        setting.GangID = iGang;
        Format(setting.Key, sizeof(Settings::Key), "slots");
        Config.StartSlots.GetString(setting.Value, sizeof(Settings::Value));
        setting.Bought = true;
        g_aGangSettings.PushArray(setting, sizeof(setting));

        ArrayList aRanks = AddRanksToTransaction(iGang, action);

        pack = new DataPack();
        pack.WriteCell(userid);
        pack.WriteCell(iGang);
        pack.WriteCell(aRanks);
        pack.WriteString(gang.Name);
        pack.WriteString(gang.Prefix);
        g_dDB.Execute(action, TXN_OnSuccess, TXN_OnError, pack);
    }
}

public void TXN_OnSuccess(Database db, DataPack pack, int numQueries, DBResultSet[] results, any[] queryData)
{
    if (g_bDebug)
    {
        LogMessage("(TXN_OnSuccess) numQueries: %d", numQueries);
    }

    for (int i = 0; i <= numQueries; i++)
    {
        if (g_bDebug)
        {
            LogMessage("(TXN_OnSuccess) queryData[%d] - Process: %d", i, queryData[i]);
        }

        pack.Reset();
        int userid = pack.ReadCell();
        int gangid = pack.ReadCell();
        ArrayList aRanks = view_as<ArrayList>(pack.ReadCell());
        char sName[32];
        pack.ReadString(sName, sizeof(sName));
        char sPrefix[16];
        pack.ReadString(sPrefix, sizeof(sPrefix));
        delete pack;

        if (queryData[i] >= 1 && queryData[i] <= Config.MaxLevel.IntValue)
        {
            int iRank = results[i].InsertId;

            Ranks rRank;
            for (int j = 0; j < aRanks.Length; j++)
            {
                Rank rank;
                aRanks.GetArray(j, rank, sizeof(rank));

                if (queryData[i] == rank.Level)
                {
                    rRank.GangID = gangid;
                    rRank.RankID = iRank;
                    strcopy(rRank.Name, sizeof(Ranks::Name), rank.Name);
                    rRank.Level = rank.Level;
                    rRank.Invite = rank.Invite;
                    rRank.Kick = rank.Kick;
                    rRank.Promote = rank.Promote;
                    rRank.Demote = rank.Demote;
                    rRank.Upgrade = rank.Upgrade;
                    rRank.Manager = rank.Manager;
                    g_aGangRanks.PushArray(rRank, sizeof(rRank));
                }
            }

            int client = GetClientOfUserId(userid);

            if (IsClientValid(client) && queryData[i] == Config.MaxLevel.IntValue)
            {
                if (g_bDebug)
                {
                    LogMessage("ID for Rank Owner should be %d.", iRank);
                }

                pack = new DataPack();
                pack.WriteCell(userid);
                pack.WriteCell(gangid);
                pack.WriteCell(iRank);
                pack.WriteString(sName);
                pack.WriteString(sPrefix);

                char sQuery[512];
                g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `gang_players` (`playerid`, `gangid`, `rank`) VALUES ('%d', '%d', '%d')", g_pPlayer[client].PlayerID, gangid, iRank);
                g_dDB.Query(Query_InsertPlayerOwner, sQuery, pack);
            }
        }
    }

    // TODO: Reset
}

public void TXN_OnError(Database db, DataPack pack, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    LogError("(TXN_OnError) Error executing query (rank level: %d) %d of %d queries: %s", queryData[failIndex], failIndex, numQueries, error);
    delete pack;
}

public void Query_InsertPlayerOwner(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_InsertPlayerOwner) Error: %s", error);
        return;
    }

    pack.Reset();

    int userid = pack.ReadCell();
    int gangid = pack.ReadCell();
    int rankid = pack.ReadCell();

    char sName[32];
    pack.ReadString(sName, sizeof(sName));

    char sPrefix[16];
    pack.ReadString(sPrefix, sizeof(sPrefix));

    delete pack;

    int client = GetClientOfUserId(userid);

    if (!IsClientValid(client))
    {
        return;
    }

    if (IsClientValid(client))
    {
        CPrintToChatAll("%N has been created a new Gang! Name: %s, Prefix: %s", client, sName, sPrefix);

        g_pPlayer[client].InGang = true;
        g_pPlayer[client].GangID = gangid;
        g_pPlayer[client].Rank = rankid;
    }
}
