void menu_OnPluginStart()
{
    RegConsoleCmd("sm_gang", Command_Gang);
}

public Action Command_Gang(int client, int args)
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

    ShowGangMenu(client);

    return Plugin_Handled;
}

void ShowGangMenu(int client)
{
    char sName[MAX_GANGS_NAME_LENGTH], sPrefix[MAX_GANGS_PREFIX_LENGTH];

    GetGangName(g_pPlayer[client].GangID, sName, sizeof(sName));
    GetGangPrefix(g_pPlayer[client].GangID, sPrefix, sizeof(sPrefix));

    if (g_bDebug)
    {
        PrintToChat(client, "(ShowGangMenu) Name: %s, Prefix: %s", sName, sPrefix);
    }

    Menu menu = new Menu(Menu_GangMain);
    menu.SetTitle("%s | %s", sPrefix, sName);
    menu.AddItem("", "Nothing yet...", ITEMDRAW_DISABLED);
    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_GangMain(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
}
