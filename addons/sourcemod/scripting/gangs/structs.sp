enum struct Player {
    char CommunityID[18];

    int PlayerID;
    
    bool InGang;
    int GangID;
    int Rank;
}

enum struct Gang {
    int GangID;
    int Created;
    char Name[32];
    char Prefix[16];
    int Points;
    int Founder;
}

enum struct Settings {
    int GangID;
    char Key[32];
    char Value[128];
    bool Bought;
}

enum struct Rank {
    char Name[32];
    int Level;
    bool Invite;
    bool Kick;
    bool Promote;
    bool Demote;
    bool Upgrade;
    bool Manager;
}

enum struct Ranks {
    int GangID;
    int RankID;
    char Name[32];
    int Level;
    bool Invite;
    bool Kick;
    bool Promote;
    bool Demote;
    bool Upgrade;
    bool Manager;
}
