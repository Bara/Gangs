void configs_OnPluginStart()
{
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("gangs");
    Config.PluginPrefix = AutoExecConfig_CreateConVar("gangs_plugin_prefx", "{green}[Gangs]{default}", "Set the plugin tag for every chat message");
    Config.NameMaxLength = AutoExecConfig_CreateConVar("gangs_max_name_length", "32", "Maximal length of a gang name.", _, false, _, true, 32.0);
    Config.NameMinLength = AutoExecConfig_CreateConVar("gangs_min_name_length", "2", "Minimal length of a gang name.", _, true, 2.0, false, _);
    Config.PrefixMaxLength = AutoExecConfig_CreateConVar("gangs_max_prefix_length", "16", "Maximal length of a gang prefix.", _, false, _, true, 16.0);
    Config.PrefixMinLength = AutoExecConfig_CreateConVar("gangs_min_prefix_length", "2", "Minimal length of a gang prefix.", _, true, 2.0, false, _);
    Config.NameRegex = AutoExecConfig_CreateConVar("gangs_name_regex", "^[a-zA-Z0-9 _,.!#+*]+$", "Allowed characters in gang name. (Default: \"^[a-zA-Z0-9 _,.!#+*]+$\"");
    Config.PrefixRegex = AutoExecConfig_CreateConVar("gangs_prefix_regex", "^[a-zA-Z0-9 _,.!#+*]+$", "Allowed characters in gang prefix. (Default: \"^[a-zA-Z0-9 _,.!#+*]+$\"");
    Config.StartSlots = AutoExecConfig_CreateConVar("gangs_start_slots", "4", "With how many slots should start a gang after creation?", _, true, 1.0);
    Config.MaxLevel = AutoExecConfig_CreateConVar("gangs_max_rang_level", "10", "What should be the highest level for rangs? This could be used for max gang rangs.", _, true, 10.0);
    Config.InviteReactionTime = AutoExecConfig_CreateConVar("gangs_invite_reaction_time", "10", "Time in seconds to react for an invite.", _, true, 10.0, false);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}
