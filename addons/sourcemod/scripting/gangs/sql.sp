static int iTables = 8;
static int iCount = 0;

void sql_OnPluginStart()
{
    Database.Connect(OnSQLConnect,  "gangs");
}

public void OnSQLConnect(Database db, const char[] error, any data)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("Connection to database has been failed! Error: %s", error);
        return;
    }

    char sDriver[8];
    db.Driver.GetIdentifier(sDriver, sizeof(sDriver));

    if (!StrEqual(sDriver, "mysql", false))
    {
        SetFailState("We found an invalid driver (%s). This plugins supports only mysql!", sDriver);
        return;
    }

    g_dDB = db;

    if (!g_dDB.SetCharset("utf8mb4"))
    {
        g_dDB.SetCharset("utf9");
    }

    iCount = 0;

    CreateTables();
}

void CreateTables()
{
    char sQuery[1024];

    g_dDB.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `players` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `communityid` VARCHAR(18) COLLATE utf8mb4_unicode_ci NOT NULL, \
        `name` VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL, \
        KEY (`communityid`, `name`), \
        KEY (`communityid`), \
        UNIQUE KEY (`communityid`), \
        PRIMARY KEY (`id`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
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
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_ranks"));
    
    g_dDB.Format(sQuery, sizeof(sQuery), " \
    CREATE TABLE IF NOT EXISTS `gang_players` ( \
        `playerid` INT NOT NULL, \
        `gangid` INT NOT NULL, \
        `rank` TINYINT NOT NULL, \
        UNIQUE KEY (`playerid`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
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
    g_dDB.Query(Query_CreateTable, sQuery, StringToInt("gang_logs_points"));
}

public void Query_CreateTable(Database db, DBResultSet results, const char[] error, int table)
{
    if (!IsValidDatabase(db, error))
    {
        char sTable[16];
        IntToString(table, sTable, sizeof(sTable));
        SetFailState("Table creation for the table \"%s\" failed. Error: %s", table, error);
        return;
    }

    iCount++;

    if (iCount == iTables)
    {
        LogMessage("All %d tables created.", iCount);
    }
    else
    {
        LogMessage("Table %d of %d created.", iCount, iTables);
    }
}
