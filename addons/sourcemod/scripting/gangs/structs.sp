enum struct Player {
    int PlayerID;
    int GangID;
    int RangID;
    bool Leaving;
    char CommunityID[18];
}

enum struct Gang {
    int GangID;
    int Created;
    int Points;
    int Founder;
    char Name[32];
    char Prefix[16];
}

enum struct Settings {
    int GangID;
    bool Bought;
    char Key[32];
    char Value[128];
}

enum struct Rang {
    int Level;
    bool Invite;
    bool Kick;
    bool Promote;
    bool Demote;
    bool Upgrade;
    bool Manager;
    char Name[32];
}

enum struct Rangs {
    int GangID;
    int RangID;
    int Level;
    bool Invite;
    bool Kick;
    bool Promote;
    bool Demote;
    bool Upgrade;
    bool Manager;
    char Name[32];
}

enum struct Invite {
    int GangID;
    int InviterID;
    int PlayerID;
}

enum struct Configs {
    ConVar PluginPrefix;
    ConVar NameMaxLength;
    ConVar NameMinLength;
    ConVar PrefixMaxLength;
    ConVar PrefixMinLength;
    ConVar NameRegex;
    ConVar PrefixRegex;
    ConVar StartSlots;
    ConVar MaxLevel;
    ConVar InviteReactionTime;
}
