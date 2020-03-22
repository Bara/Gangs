static int iTables = 10;
static int iCount = 0;

static char sQueries[][1024] = {
    "CREATE TABLE IF NOT EXISTS `players` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`communityid` VARCHAR(18) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`name` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`firstseen` INT NOT NULL," ...
        "`lastseen` INT NOT NULL," ...
        "KEY (`communityid`, `name`)," ...
        "KEY (`communityid`)," ...
        "UNIQUE KEY (`communityid`)," ...
        "PRIMARY KEY (`id`)" ...
        ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
    
    "CREATE TABLE IF NOT EXISTS `gangs` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`name` VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`prefix` VARCHAR(16) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`created` INT NOT NULL," ...
        "`points` INT NOT NULL," ...
        "`founder` VARCHAR(18) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "UNIQUE KEY (`name`)," ...
        "UNIQUE KEY (`prefix`)," ...
        "UNIQUE KEY (`founder`)," ...
        "PRIMARY KEY (`id`)" ...
        ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    "CREATE TABLE IF NOT EXISTS `gang_settings` (" ...
        "`gangid` INT NOT NULL," ...
        "`key` VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`value` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`purchased` TINYINT NOT NULL," ...
        "UNIQUE KEY (`gangid`, `key`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    "CREATE TABLE IF NOT EXISTS `gang_ranks` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`gangid` INT NOT NULL," ...
        "`rank` VARCHAR(24) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`level` TINYINT NOT NULL," ...
        "`perm_invite` TINYINT NOT NULL," ...
        "`perm_kick` TINYINT NOT NULL," ...
        "`perm_promote` TINYINT NOT NULL," ...
        "`perm_demote` TINYINT NOT NULL," ...
        "`perm_upgrade` TINYINT NOT NULL," ...
        "`perm_manager` TINYINT NOT NULL," ...
        "UNIQUE KEY (`gangid`, `rank`)," ...
        "UNIQUE KEY (`gangid`, `level`)," ...
        "PRIMARY KEY (`id`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
    
    "CREATE TABLE IF NOT EXISTS `gang_players` (" ...
        "`playerid` INT NOT NULL," ...
        "`gangid` INT NOT NULL," ...
        "`rank` TINYINT NOT NULL," ...
        "UNIQUE KEY (`playerid`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
    
    "CREATE TABLE IF NOT EXISTS `gang_invites` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`invitetime` INT NOT NULL," ...
        "`gangid` INT NOT NULL," ...
        "`playerid` INT NOT NULL," ...
        "`inviterid` INT NOT NULL," ...
        "`accepted` TINYINT NULL," ...
        "`updatetime` INT NULL," ...
        "PRIMARY KEY (`id`)," ...
        "UNIQUE KEY (`gangid`, `playerid`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    "CREATE TABLE IF NOT EXISTS `gang_logs` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`gangid` INT NOT NULL," ...
        "`time` INT NOT NULL," ...
        "`playerid` INT NOT NULL," ...
        "`type` VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "PRIMARY KEY (`id`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    "CREATE TABLE IF NOT EXISTS `gang_logs_settings` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`gangid` INT NOT NULL," ...
        "`time` INT NOT NULL," ...
        "`playerid` INT NOT NULL," ...
        "`key` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "`amount` INT NOT NULL," ...
        "PRIMARY KEY (`id`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    "CREATE TABLE IF NOT EXISTS `gang_logs_players` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`gangid` INT NOT NULL," ...
        "`time` INT NOT NULL," ...
        "`playerid` INT NOT NULL," ...
        "`join` TINYINT NOT NULL," ...
        "`reason` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "PRIMARY KEY (`id`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",

    "CREATE TABLE IF NOT EXISTS `gang_logs_points` (" ...
        "`id` INT NOT NULL AUTO_INCREMENT," ...
        "`gangid` INT NOT NULL," ...
        "`time` INT NOT NULL," ...
        "`playerid` INT NOT NULL," ...
        "`add` TINYINT NOT NULL," ...
        "`amount` INT NOT NULL," ...
        "`reason` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL," ...
        "PRIMARY KEY (`id`)" ...
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
};

static char sTables[][] = {
    "players", "gangs", "gang_settings", "gang_ranks", "gang_players", "gang_invites",
    "gang_logs", "gang_logs_settings", "gang_logs_players", "gang_logs_points"
};

void connect_OnPluginStart()
{
    if (!SQL_CheckConfig("gangs"))
    {
        SetFailState("(connect_OnPluginStart) Cannot find \"%s\" in your databases.cfg file", "gangs");
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
        SetFailState("(OnSQLConnect) We found an invalid database driver (%s). Gangs requires MySQL!", sDriver);
        return;
    }

    g_dDB = db;

    if (!g_dDB.SetCharset("utf8mb4"))
    {
        if (g_bDebug)
        {
            LogMessage("(OnSQLConnect) Can not set charset \"utf8mb4\". We try to set it to \"utf8\".");
        }

        g_dDB.SetCharset("utf8");

        for(int i; i < sizeof(sTables); i++)
        {
            ReplaceString(sQueries[i], sizeof(sQueries[]), "utf8mb4", "utf8");
        }
    }

    iCount = 0;

    CreateTables();
}

void CreateTables()
{
    for(int i; i < sizeof(sTables); i++)
    {
        if (g_bDebug)
        {
            LogMessage("(CreateTables) Table %d: \"%s\"", (i + 1), sQueries[i]);
        }

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

    if (g_bDebug)
    {
        LogMessage("(Query_CreateTable) Table %d of %d created.", iCount, iTables);
    }

    if (iCount == iTables)
    {
        delete g_aGangs;
        delete g_aGangSettings;
        delete g_aGangRanks;

        g_aGangs = new ArrayList(sizeof(Gang));
        g_aGangSettings = new ArrayList(sizeof(Settings));
        g_aGangRanks = new ArrayList(sizeof(Ranks));
        g_aPlayerInvites = new ArrayList(sizeof(Invite));

        LateLoadPlayers(); // TODO: Move this when gang stuff is completely loaded
    }
}

public void Query_Select_Player(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Select_Player) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!IsClientValid(client))
    {
        return;
    }

    if (g_bDebug)
    {
        LogMessage("(Query_Select_Player) UserID: %d (Client: %d), Rows: %d", userid, client, results.RowCount);
    }

    if (results.RowCount == 0)
    {
        char sQuery[512];
        g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `players` (`communityid`, `name`, `firstseen`, `lastseen`) VALUES (\"%s\", \"%N\", UNIX_TIMESTAMP(), UNIX_TIMESTAMP());", g_pPlayer[client].CommunityID, client);

        if (g_bDebug)
        {
            LogMessage("(Query_Select_Player) \"%L\": \"%s\"", client, sQuery);
        }

        g_dDB.Query(Query_Insert_Player, sQuery, userid);
    }
    else
    {
        if (results.RowCount == 1 && results.FetchRow())
        {
            g_pPlayer[client].PlayerID = results.FetchInt(0);

            invite_LoadPlayerInvites(client);

            char sQuery[512];
            g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `players` SET `name` = \"%N\", `lastseen` = UNIX_TIMESTAMP() WHERE `communityid` = \"%s\";", client, g_pPlayer[client].CommunityID);

            if (g_bDebug)
            {
                LogMessage("(Query_Select_Player) Update \"%L\"<%d>: \"%s\"", client, g_pPlayer[client].PlayerID, sQuery);
            }

            g_dDB.Query(Query_Update_Player, sQuery, userid);
        }
        else
        {
            LogError("(Query_Select_Player) We have more rows for \"%N\". Query stopped!", client);
            return;
        }
    }
}

public void Query_Insert_Player(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Insert_Player) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        g_pPlayer[client].PlayerID = results.InsertId;

        invite_LoadPlayerInvites(client);
    }
}

public void Query_Update_Player(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Update_Player) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        char sQuery[128];
        g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `gangid`, `rank` FROM `gang_players` WHERE `playerid` = '%d';", g_pPlayer[client].PlayerID);

        if (g_bDebug)
        {
            LogMessage("(Query_Update_Player) \"%L\": \"%s\"", client, sQuery);
        }

        g_dDB.Query(Query_Select_GangPlayers, sQuery, userid);
    }
}

public void Query_Select_GangPlayers(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Select_GangPlayers) Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        if (results.FetchRow())
        {
            g_pPlayer[client].GangID = results.FetchInt(0);
            g_pPlayer[client].RankID = results.FetchInt(1);

            if (!IsGangValid(g_pPlayer[client].GangID))
            {
                LoadGang(g_pPlayer[client].GangID);
            }

            if (!AreGangSettingsLoaded(g_pPlayer[client].GangID))
            {
                LoadSettings(g_pPlayer[client].GangID);
            }

            if (!AreGangRanksLoaded(g_pPlayer[client].GangID))
            {
                LoadRanks(g_pPlayer[client].GangID);
            }
        }
    }
}

void LoadGang(int gangid)
{
    char sQuery[128];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `id`, `name`, `prefix`, `created`, `points`, `founder` FROM `gangs` WHERE `id` = '%d';", gangid);

    if (g_bDebug)
    {
        LogMessage("(LoadGang) Query: \"%s\"", sQuery);
    }

    Gang gang;
    gang.GangID = gangid;

    int iIndex = g_aGangs.PushArray(gang, sizeof(gang));

    g_dDB.Query(Query_Select_Gangs, sQuery, iIndex);
}

public void Query_Select_Gangs(Database db, DBResultSet results, const char[] error, int index)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Select_Gangs) Error: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        Gang gang;
        gang.GangID = results.FetchInt(0);
        results.FetchString(1, gang.Name, sizeof(Gang::Name));
        results.FetchString(2, gang.Prefix, sizeof(Gang::Prefix));
        gang.Created = results.FetchInt(3);
        gang.Points = results.FetchInt(4);
        gang.Founder = results.FetchInt(5);

        if (g_bDebug)
        {
            LogMessage("(Query_Select_Gangs) Added \"%s\" to gangs cache (GangID: %d, Prefix: %s, Created: %d, Points: %d, Founder: %d).", gang.Name, gang.GangID, gang.Prefix, gang.Created, gang.Points, gang.Founder);
        }

        g_aGangs.SetArray(index, gang, sizeof(gang));
    }
}

void LoadSettings(int gangid)
{
    char sQuery[128];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `key`, `value`, `purchased` FROM `gang_settings` WHERE `gangid` = '%d';", gangid);

    if (g_bDebug)
    {
        LogMessage("(LoadSettings) Query: \"%s\"", sQuery);
    }

    g_dDB.Query(Query_Select_GangSettings, sQuery, gangid);
}

public void Query_Select_GangSettings(Database db, DBResultSet results, const char[] error, int gangid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Select_GangSettings) Error: %s", error);
        return;
    }

    while (results.FetchRow())
    {
        Settings setting;
        setting.GangID = gangid;
        results.FetchString(0, setting.Key, sizeof(Settings::Key));
        results.FetchString(1, setting.Value, sizeof(Settings::Value));
        setting.Bought = view_as<bool>(results.FetchInt(2));

        if (g_bDebug)
        {
            LogMessage("(Query_Select_GangSettings) Added \"%s\" to gang settings cache (GangID: %d, Value: %s, Bought: %d).", setting.Key, setting.GangID, setting.Value, setting.Bought);
        }

        g_aGangSettings.PushArray(setting, sizeof(setting));
    }
}

void LoadRanks(int gangid)
{
    char sQuery[256];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT `id`, `level`, `perm_invite`, `perm_kick`, `perm_promote`, `perm_demote`, `perm_upgrade`, `perm_manager`, `rank` FROM `gang_ranks` WHERE `gangid` = '%d';", gangid);

    if (g_bDebug)
    {
        LogMessage("(LoadRanks) Query: \"%s\"", sQuery);
    }

    g_dDB.Query(Query_Select_GangRanks, sQuery, gangid);
}

public void Query_Select_GangRanks(Database db, DBResultSet results, const char[] error, int gangid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_Select_GangRanks) Error: %s", error);
        return;
    }

    while (results.FetchRow())
    {
        Ranks rank;
        rank.GangID = gangid;
        rank.RankID = results.FetchInt(0);
        rank.Level = results.FetchInt(1);
        rank.Invite = view_as<bool>(results.FetchInt(2));
        rank.Kick = view_as<bool>(results.FetchInt(3));
        rank.Promote = view_as<bool>(results.FetchInt(4));
        rank.Demote = view_as<bool>(results.FetchInt(5));
        rank.Upgrade = view_as<bool>(results.FetchInt(6));
        rank.Manager = view_as<bool>(results.FetchInt(7));
        results.FetchString(8, rank.Name, sizeof(Ranks::Name));

        if (g_bDebug)
        {
            LogMessage("(Query_Select_GangRanks) Added \"%s\" to gang ranks cache (GangID: %d, RankID: %d, Level: %d, Invite: %d, Kick: %d, Promote: %d, Demote: %d, Upgrade: %d, Manager: %d).", rank.Name, rank.GangID, rank.RankID, rank.Level, rank.Invite, rank.Kick, rank.Promote, rank.Demote, rank.Upgrade, rank.Manager);
        }

        g_aGangRanks.PushArray(rank, sizeof(rank));
    }
}
