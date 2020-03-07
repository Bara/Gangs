enum struct Player {
    int PlayerID;
    int GangID;
    int Rank;
    bool InGang;
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

enum struct Rank {
    int Level;
    bool Invite;
    bool Kick;
    bool Promote;
    bool Demote;
    bool Upgrade;
    bool Manager;
    char Name[32];
}

enum struct Ranks {
    int GangID;
    int RankID;
    int Level;
    bool Invite;
    bool Kick;
    bool Promote;
    bool Demote;
    bool Upgrade;
    bool Manager;
    char Name[32];
}

enum struct Configs {
    ConVar NameLength;
    ConVar PrefixLength;
    ConVar NameRegex;
    ConVar PrefixRegex;
    ConVar StartSlots;
    ConVar MaxLevel;
}
