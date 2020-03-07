void configs_OnPluginStart()
{
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("gangs");
    Config.PluginPrefix = AutoExecConfig_CreateConVar("gangs_plugin_prefx", "{green}[Gangs]{default}", "Set the plugin tag for every chat message");
    Config.NameLength = AutoExecConfig_CreateConVar("gangs_max_name_length", "32", "Maximal length of a gang name.", _, true, 2.0, true, 32.0);
    Config.PrefixLength = AutoExecConfig_CreateConVar("gangs_max_prefix_length", "16", "Maximal length of a gang prefix.", _, true, 2.0, true, 16.0);
    Config.NameRegex = AutoExecConfig_CreateConVar("gangs_name_regex", "^[a-zA-Z0-9 _,.!#+*]+$", "Allowed characters in gang name. (Default: \"^[a-zA-Z0-9 _,.!#+*]+$\"");
    Config.PrefixRegex = AutoExecConfig_CreateConVar("gangs_prefix_regex", "^[a-zA-Z0-9 _,.!#+*]+$", "Allowed characters in gang prefix. (Default: \"^[a-zA-Z0-9 _,.!#+*]+$\"");
    Config.StartSlots = AutoExecConfig_CreateConVar("gangs_start_slots", "4", "With how many slots should start a gang after creation?", _, true, 1.0);
    Config.MaxLevel = AutoExecConfig_CreateConVar("gangs_max_rank_level", "10", "What should be the highest level for ranks? This could be used for max gang ranks.", _, true, 10.0);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}
