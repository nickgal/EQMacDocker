# Optional fixes

SQL changes you can apply by hand if you want them. None of them run
automatically, on a new database or otherwise. Each one changes a Quarm
setting that comes with the database: Project Quarm's choices for its live
server, which may not suit a private one.

| File                            | What it does                                                   |
| ------------------------------- | -------------------------------------------------------------- |
| `disable_respawn_reduction.sql` | Spawns use their normal respawn times everywhere               |
| `disable_zone_kick_timers.sql`  | Players are no longer kicked after an hour in four zones       |
| `velious_group_xp_bonus.sql`    | Group experience bonus drops from Quarm's to the Velious era's |

[Other Quarm rules](#other-quarm-rules) below describes more settings you can
change the same way.

## Applying a fix

From the repository root, with the server running:

```bash
docker compose exec -T db sh -c 'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  < optional/disable_respawn_reduction.sql
```

The change is saved in the database, so it survives restarts. A database reset
(`docker compose down -v`) undoes it.

Zone processes read rules when they start, and the `zone` table when a zone
boots. To make running zones pick up a change, either:

  - for rule changes only: type `#reload rules` in game on a character whose
    account status is 200 or higher, or
  - restart the zone containers with `docker compose restart zone boats static`.
    This disconnects anyone in a zone.

To run a single statement instead of a file, open a database shell:

```bash
docker compose exec db sh -c 'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'
```

## disable_respawn_reduction.sql

The Quarm database turns on Quarm's respawn reduction system
(`Quarm:EnableRespawnReductionSystem`). In the 94 zones whose `zone` table row
has `reducedspawntimers = 1`, it replaces many respawn times with much shorter
ones:

| Zone type                     | Normal respawn | Becomes |
| ----------------------------- | -------------- | ------- |
| Outdoor, NPC below level 15   | 12-60 s        | 12 s    |
| Outdoor, NPC below level 15   | 60 s-15 min    | 60 s    |
| Dungeon, any level            | 6-15 min       | 6 min   |
| Dungeon, any level            | 15-40 min      | 8 min   |

Open-world raid targets are not affected. For example, the gnoll scouts in
Qeynos Hills (`qeytoqrg`) have a 6 minute respawn in `spawn2` but respawn
after 1 minute.

This fix sets the rule to `false`, so every spawn uses its `spawn2` respawn
time again. Spawns whose timer is already counting down keep their current
timer.

It also changes the pull limit (see `Quarm:EnablePullLimitSystem` below).
While the reduction system is on, the limit is 35 in every zone; with it off,
each zone uses the `pull_limit` in its `zone` table row (80 in `qeytoqrg`, for
example).

To undo it, set the rule back to `true`:

```sql
UPDATE rule_values SET rule_value = 'true'
WHERE rule_name = 'Quarm:EnableRespawnReductionSystem';
```

### Alternatives

To turn it off only in some zones, leave the rule on and clear those zones'
flag. Zones read this when they boot:

```sql
UPDATE zone SET reducedspawntimers = 0 WHERE short_name IN ('qeytoqrg');
```

To keep it but make it milder, change the reduced times (in milliseconds),
e.g. 3 minutes instead of 60 seconds for outdoor spawns:

```sql
UPDATE rule_values SET rule_value = '180000'
WHERE rule_name = 'Quarm:RespawnReductionHigherBound';
```

The related rules are `Quarm:RespawnReduction*`; the code is in
`Spawn2::resetTimer` in `Server/zone/spawn2.cpp`.

## disable_zone_kick_timers.sql

Four zones have `afk_kick_timer = 3600` in the `zone` table: `nexus`,
`shadowhaven`, `timorous` and `bazaar`. A player (account status 0) who enters
one of them gets a warning, and one hour later is kicked to server select. The
timer starts when they enter the zone and activity does not reset it.
Characters running an offline trader are exempt.

This fix sets the timer to 0 in every zone, which turns it off. It takes
effect when each zone next boots; `timorous` runs in the `boats` container and
the others as dynamic zones.

To undo it:

```sql
UPDATE zone SET afk_kick_timer = 3600
WHERE short_name IN ('nexus', 'shadowhaven', 'timorous', 'bazaar');
```

The code is in `Client::OnAFKTimerChanged` in `Server/zone/client.cpp`.

## velious_group_xp_bonus.sql

`Quarm:BonusGroupEXPOverride` is on, so group kills use Quarm's own experience
bonus, set by `Quarm:BonusGroupEXP2MemberOverride` through
`Quarm:BonusGroupEXP7MemberOverride`. Turning it off falls back to the
Velious-era bonus (`AlKabor:VeliousGroupEXPBonuses` is on):

| Group members in range | Quarm (current) | Velious era (with this fix) |
| ---------------------- | --------------- | --------------------------- |
| 2                      | 1.20x           | 1.02x                       |
| 3                      | 1.25x           | 1.06x                       |
| 4                      | 1.35x           | 1.10x                       |
| 5                      | 1.45x           | 1.14x                       |
| 6                      | 1.75x           | 1.20x                       |
| 7                      | 1.75x           | 1.24x                       |

To undo it, set the rule back to `true`. To keep Quarm's system but change the
numbers, edit the `Quarm:BonusGroupEXP*MemberOverride` rules instead.

The code is in `Group::SplitExp` in `Server/zone/exp.cpp`.

## Other Quarm rules

There are 164 `Quarm:` rules in the `rule_values` table. These are the ones
most likely to matter on a private server, with their value in the Quarm
database. Each was checked against the server code; several descriptions in
`Server/common/ruletypes.h` are wrong or copied from other rules, so trust
this list or the code over those. Change them with an `UPDATE rule_values`
statement like the ones above.

**Experience**

| Rule                       | Value   | Effect                                                                 |
| -------------------------- | ------- | ---------------------------------------------------------------------- |
| `EnableQuestExpMultiplier` | `true`  | Multiplies quest experience by `QuestExpMultiplier`                    |
| `QuestExpMultiplier`       | `1.0`   | The quest experience multiplier; at 1.0 it changes nothing             |
| `EnablePetExperienceSplit` | `false` | Pets that did most of the damage take a share of the experience        |
| `ThanksgivingExpBonus`     | `false` | Seasonal bonus for kills in outdoor zones and of flying-race NPCs      |
| `InstanceZEMOverride`      | `45`    | Zone experience modifier used in guild instances                       |

**Pulling and kiting**

| Rule                     | Value  | Effect                                                                  |
| ------------------------ | ------ | ----------------------------------------------------------------------- |
| `EnablePullLimitSystem`  | `true` | When a player has more NPCs on them than the zone's pull limit, those that have been chasing them for over 30 seconds stop following |
| `EnablePullLimitWarp`    | `true` | Those NPCs, if within 500 units, each have a small chance per check to teleport onto the player |
| `EnableBardInstagibLimit`| `true` | NPCs below 95% health summon a bard who has more than `BardInstagibPullLimit` (15) of them on them |

**Client version and cheating**

| Rule                                      | Value   | Effect                                                    |
| ----------------------------------------- | ------- | --------------------------------------------------------- |
| `WarnDllVersionBelow`                     | `7`     | Minimum version of Quarm's client patch. Players below it are removed from PvP instances and Veksar |
| `EnforceLatestDllToEnterSpecialInstances` | `true`  | Players below that version cannot use doors inside zones with IDs 1500-4999, or doors into PvP instances |
| `EnableChecksumEnforcement`               | `false` | Checks the client's checksum at login against the `CustomChecksum` variable |
| `EnableProjectSpeedie`                    | `true`  | Speed-hack detection. It only reports: it messages GMs (status 100+) and records the player in the `hackers` table |

**Connections**

| Rule                               | Value    | Effect                                                         |
| ---------------------------------- | -------- | -------------------------------------------------------------- |
| `EnableWorldClientInactiveTimeout` | `true`   | Disconnects a player who stays at character select for `WorldClientInactiveTimeoutMS` |
| `WorldClientInactiveTimeoutMS`     | `900000` | That timeout: 15 minutes                                       |
| `PlayerPopulationCap`              | `1200`   | Players with account status 0 cannot enter once this many are online |
| `AntiSpamMuteInSeconds`            | `900`    | How long the chat spam filter mutes a player                   |

**Rules with no practical effect here**

  - `EnableQuakes` and the `Quake*` rules only repop raid targets in Quarm's
    guild-1 PvP instances.
  - `BazaarAutoKickTimerS` is overridden by the zone kick timer described
    above.
  - `EnablePVPInstances` and `IncludeMulesInServerCount` are not used by the
    server code.

Most of the remaining rules set gameplay to match an era of the original game
(for example `MaxTradeskillCap`, `BeastlordMaxLevel`, `VeliousEraAggroCaps`)
or control Quarm's PvP and guild instance systems.
