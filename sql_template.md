players
- id - auto increment, int
- communityid - varchar(18), key 1, key 2, unique key 1
- name - varchar(128), key 1

gangs
- id - auto increment, int
- name - varchar(32), unique key 1
- prefix - varchar(16), unique key 2
- created - timestamp
- points - int
- founder - int, unique key 3

gang_settings
- gangid - int, unique key 1
- feature - varchar(32), unique key 1
- value - varchar(128)
- purchased - tinyint

gang_ranks
- gangid - int, unique key 1, unique key 2
- rank - varchar(24), unique key 1
- level - tinyint, unique key 2
- perm_invite - tinyint
- perm_promote - tinyint
- perm_demote - tinyint
- perm_kick - tinyint
- perm_upgrade - tinyint

gang_players
- playerid - int, unique key 1
- gangid - int
- status - tinyint

gang_logs_settings
- gangid - int
- time - timestamp
- playerid - int
- action - varchar(128)
- amount - int

gang_logs_players
- gangid - int
- time - timestamp
- playerid - int
- join - tinyint
- reason - varchar(128)

gang_logs_points
- gangid - int
- time - timestamp
- playerid - int
- add - tinyint
- amount - int
- reason - varchar(128)
