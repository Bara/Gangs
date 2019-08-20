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
        UNIQUE KEY (`gangid`), \
        UNIQUE KEY (`key`) \
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
    /* char sQuery[1024];

    g_dDB.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `players` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `communityid` VARCHAR(18) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `name` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `firstseen` INT NOT NULL, \
        `lastseen` INT NOT NULL, \
        KEY (`communityid`, `name`), \
        KEY (`communityid`), \
        UNIQUE KEY (`communityid`), \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "players", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("players"));

    g_dDB.Format(sQuery, sizeof(sQuery), " \
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
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "gangs", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gangs"));
    
    g_dDB.Format(sQuery, sizeof(sQuery), " \
    CREATE TABLE IF NOT EXISTS `gang_settings` ( \
        `gangid` INT NOT NULL, \
        `key` VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `value` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `purchased` TINYINT NOT NULL, \
        UNIQUE KEY (`gangid`), \
        UNIQUE KEY (`key`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "gang_settings", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_settings"));
    
    g_dDB.Format(sQuery, sizeof(sQuery), " \
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
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "gang_ranks", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_ranks"));
    
    g_dDB.Format(sQuery, sizeof(sQuery), " \
    CREATE TABLE IF NOT EXISTS `gang_players` ( \
        `playerid` INT NOT NULL, \
        `gangid` INT NOT NULL, \
        `rank` TINYINT NOT NULL, \
        UNIQUE KEY (`playerid`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "gang_players", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_players"));
    
    g_dDB.Format(sQuery, sizeof(sQuery), " \
    CREATE TABLE IF NOT EXISTS `gang_logs_settings` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `gangid` INT NOT NULL, \
        `time` INT NOT NULL, \
        `playerid` INT NOT NULL, \
        `key` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `amount` INT NOT NULL, \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "gang_logs_settings", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_logs_settings"));
    
    g_dDB.Format(sQuery, sizeof(sQuery), " \
    CREATE TABLE IF NOT EXISTS `gang_logs_players` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `gangid` INT NOT NULL, \
        `time` INT NOT NULL, \
        `playerid` INT NOT NULL, \
        `join` TINYINT NOT NULL, \
        `reason` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "gang_logs_players", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_logs_players"));
    
    g_dDB.Format(sQuery, sizeof(sQuery), " \
    CREATE TABLE IF NOT EXISTS `gang_logs_points` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `gangid` INT NOT NULL, \
        `time` INT NOT NULL, \
        `playerid` INT NOT NULL, \
        `add` TINYINT NOT NULL, \
        `amount` INT NOT NULL, \
        `reason` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    LogMessage("Table %s: \"%s\", "gang_logs_points", sQuery);
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_logs_points")); */

    for(int i; i < sizeof(sTables); i++)
    {
        LogMessage("Table %d: \"%s\"", (i + 1), sQueries[i]);
        g_dDB.Query(Query_CreateTable, sQueries[i], StringToInt(sTables[i]));
    }
}

public void Query_CreateTable(Database db, DBResultSet results, const char[] error, int table)
{
    if (!IsValidDatabase(db, error))
    {
        char sTable[16];
        IntToString(table, sTable, sizeof(sTable));
        SetFailState("(Query_CreateTable) Table creation for the table \"%s\" failed. Error: %s", table, error);
        return;
    }

    iCount++;

    LogMessage("(Query_CreateTable) Table %d of %d created.", iCount, iTables);

    if (iCount == iTables)
    {
        LateLoadPlayers();
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

    if (!IsClientInGame(client))
    {
        return;
    }

    LogMessage("(Query_SelectPlayer) UserID: %d (Client: %d), Rows: %d", userid, client, results.RowCount);

    if (results.RowCount == 0)
    {
        char sQuery[512];
        g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `players` (`communityid`, `name`, `firstseen`, `lastseen`) VALUES (\"%s\", \"%N\", UNIX_TIMESTAMP(), UNIX_TIMESTAMP())", g_pPlayer[client].CommunityID, client);
        LogMessage("Insert \"%L\": \"%s\"", client, sQuery);
        g_dDB.Query(Query_InsertPlayer, sQuery);
    }
    else
    {
        if (results.RowCount == 1 && results.FetchRow())
        {
            char sQuery[512];
            g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE `players` SET `name` = \"%N\", `lastseen` = UNIX_TIMESTAMP() WHERE `communityid` = \"%s\"", client, g_pPlayer[client].CommunityID);
            LogMessage("Update \"%L\": \"%s\"", client, sQuery);
            g_dDB.Query(Query_UpdatePlayer, sQuery);
        }
        else
        {
            LogError("we have more rows for \"%N\". Query stopped!", client);
            return;
        }
    }
}

public void Query_InsertPlayer(Database db, DBResultSet results, const char[] error, any data)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_InsertPlayer) Error: %s", error);
        return;
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
