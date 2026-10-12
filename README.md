# EQMacDocker

Runs a [Project Quarm](https://github.com/SecretsOTheP/EQMacEmu) (EQMacEmu)
EverQuest server with Docker Compose: login server, world, zones, chat (UCS),
query server and a MariaDB database preloaded with the Quarm content.

The server code, quests, maps and PEQ editor are git submodules:

| Submodule   | Source                                                                |
| ----------- | --------------------------------------------------------------------- |
| `Server`    | [SecretsOTheP/EQMacEmu](https://github.com/SecretsOTheP/EQMacEmu)      |
| `Quests`    | [SecretsOTheP/quests](https://github.com/SecretsOTheP/quests)          |
| `Maps`      | [EQMacEmu/Maps](https://github.com/EQMacEmu/Maps)                      |
| `PEQEditor` | [EQMacEmu/takpphpeditor](https://github.com/EQMacEmu/takpphpeditor)    |

## Requirements

  - [Docker Engine](https://docs.docker.com/engine/install/)
  - [Docker Compose](https://docs.docker.com/compose/install/linux) 2.17 or
    later

The first build compiles the server from source, which takes a while.

## Setup

```bash
# Clone this repo with submodules
git clone --recurse-submodules https://github.com/Czahrien/EQMacDocker
cd EQMacDocker

# Create .env from the example
cp .env.example .env
```

Edit `.env`:

  - `SERVER_ADDRESS`: the address clients use to reach this server. On a LAN,
    this is the Docker host's LAN IP, not a container IP. World hands this
    address to clients for zones and for chat, so it must be reachable from
    the client. World stops at startup if it is empty.
  - `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME`: credentials for the
    database container. They are only used inside Docker.
  - `LOGIN_PASSWORD_SALT` and `WORLD_SHARED_KEY`: required. Generate each with
    `openssl rand -hex 32`.

Then build and start everything:

```bash
docker compose up -d --build

# Watch world start and the zones connect
docker compose logs -f world
```

On the first start the database container imports the Quarm database. Once
the server is up, world's log shows the `boats` and `dynzone1` launchers
connecting, followed by a `New Zone Server connection` line for each zone
process: 22 with the default settings (12 boat zones and 10 dynamic zones). The `shared` container loads shared memory and exits;
that is expected.

### Connecting a client

Point your client's login server at `SERVER_ADDRESS` port 6000. Accounts are
created automatically: the first login with a new username creates that
account with the password used.

To give an account GM status, set its status in the `account` table once the
account has logged into world (`255` is the highest level, `0` a player):

```bash
docker compose exec db sh -c 'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" \
  -e "UPDATE account SET status = 255 WHERE name = \"yourname\""'
```

## Services

| Service     | Purpose                                                         |
| ----------- | --------------------------------------------------------------- |
| `db`        | MariaDB with the Quarm database                                 |
| `shared`    | Loads items, spells, etc. into shared memory, then exits        |
| `login`     | Login server                                                    |
| `world`     | World server                                                    |
| `zone`      | `dynzone1` launcher: `DYNAMIC_ZONES` idle zone processes        |
| `boats`     | `boats` launcher: the 12 zones boats travel between             |
| `static`    | `static` launcher: zones listed in `STATIC_ZONES` (optional)    |
| `ucs`       | Chat server                                                     |
| `queryserv` | Query server (logging)                                          |
| `phpmyadmin`| phpMyAdmin (optional)                                           |
| `peqeditor` | PEQ database editor (optional)                                  |

## Ports

| Port         | Protocol | Service      | Purpose                         |
| ------------ | -------- | ------------ | ------------------------------- |
| 6000         | TCP/UDP  | `login`      | Client login                    |
| 9000         | UDP      | `world`      | Client world connection         |
| 7000-7374    | TCP/UDP  | `zone`       | Dynamic zones                   |
| 7375-7400    | TCP/UDP  | `boats`      | Boat zones                      |
| 7401-7425    | TCP/UDP  | `static`     | Static zones (configurable)     |
| 7778         | TCP/UDP  | `ucs`        | Chat                            |
| 8080         | TCP      | `phpmyadmin` | phpMyAdmin (if enabled)         |
| 8081         | TCP      | `peqeditor`  | PEQ editor (if enabled)         |

Forward or open these on the Docker host's firewall for clients outside it.
The database and world's internal server port (9000/TCP) are not published;
the other server processes reach them over the Docker network.

## Zones

Zones run in three launcher containers:

  - **Dynamic zones** (`zone`): `DYNAMIC_ZONES` idle zone processes (default
    10). When a player enters a zone that is not running, world assigns it to
    one of them. When every process is busy, players cannot enter zones that
    are not already running, so set this to at least the number of zones you
    expect to be in use at once. The maximum is 254; each idle process uses
    about 14 MiB and each loaded zone a few times that.

    An empty dynamic zone shuts down and frees its process, but not as soon as
    the last player leaves. Its shutdown timer starts when the zone boots and
    repeats; each time it runs out, the zone shuts down if it is empty and
    otherwise starts another cycle. The Quarm database sets the timer to 12
    hours for every zone, so a zone can stay up for up to 12 hours after
    everyone leaves. Set `DYNAMIC_ZONE_SHUTDOWN_MINUTES` to shorten it, e.g.
    `15`. Zones already running keep their timer until they next boot.
  - **Boat zones** (`boats`): the zones boats travel between (Erudin, Qeynos,
    Freeport, Butcherblock, Timorous Deep, Firiona Vie and others) always run,
    so boats keep working. They are set up by
    `containers/database/launcher_boats.sql`.
  - **Static zones** (`static`): optional. To keep specific zones running at
    all times, list them in `STATIC_ZONES` in `.env`, e.g.
    `STATIC_ZONES=poknowledge,nexus`. They run on ports from
    `STATIC_ZONE_PORT_START` to `STATIC_ZONE_PORT_END` (default 7401-7425),
    one port per zone. When `STATIC_ZONES` is empty, the `static` container
    exits at startup.

World applies `DYNAMIC_ZONES`, `DYNAMIC_ZONE_SHUTDOWN_MINUTES` and
`STATIC_ZONES` when it starts. After changing any of them, run
`docker compose up -d`; this restarts world, which disconnects everyone
online. World refuses to start, and its log says why, if `DYNAMIC_ZONES` is
not a number from 0 to 254, `DYNAMIC_ZONE_SHUTDOWN_MINUTES` is not a number
from 1 to 35791, or `STATIC_ZONES` has an unknown zone, a boat zone, or more
zones than ports.

`DYNAMIC_ZONE_SHUTDOWN_MINUTES` sets the timer for every zone in the `zone`
table, overwriting any per-zone values. Leaving it empty changes nothing, so
to go back to the original behavior, set it to `720` (12 hours).

Each static zone is a process that runs whether or not anyone is in it, so
memory use grows with the list.

## Optional tools

Enable these by listing them in `COMPOSE_PROFILES` in `.env`, e.g.
`COMPOSE_PROFILES=phpmyadmin,peqeditor`, then run `docker compose up -d`.

  - `phpmyadmin`: [phpMyAdmin](https://www.phpmyadmin.net/) on
    `PHPMYADMIN_PORT` (default 8080). Log in with `DATABASE_USER` /
    `DATABASE_PASSWORD`.
  - `peqeditor`: the EQMacEmu fork of the
    [PEQ database editor](https://github.com/EQMacEmu/takpphpeditor) on
    `PEQ_EDITOR_PORT` (default 8081). Log in as `admin` with
    `PEQ_EDITOR_PASSWORD`, which is required when this is enabled. The
    password is reset from `.env` every time the container starts, so change
    it there rather than in the editor.

Both can edit the database directly, and are reachable from anywhere that can
reach the Docker host. Use strong passwords, and do not expose these ports to
the internet.

## Configuration reference

All settings live in `.env`. Changes take effect after `docker compose up -d`.

| Variable                        | Default        | Description                                             |
| ------------------------------- | -------------- | ------------------------------------------------------- |
| `SERVER_ADDRESS`                |                | Address clients use to reach the server                 |
| `SERVER_SHORT_NAME`             | `EQMac Docker` | Server short name                                       |
| `SERVER_LONG_NAME`              | `EQMac Docker` | Name shown in the server list                           |
| `DATABASE_USER`                 | `eq`           | Database user                                           |
| `DATABASE_PASSWORD`             | `eq`           | Database password                                       |
| `DATABASE_NAME`                 | `eq`           | Database name                                           |
| `LOGIN_PASSWORD_SALT`           | required       | Salt for login account passwords                        |
| `WORLD_SHARED_KEY`              | required       | Key the server processes use to authenticate with world |
| `DYNAMIC_ZONES`                 | `10`           | Idle zone processes for dynamic zones (0-254)           |
| `DYNAMIC_ZONE_SHUTDOWN_MINUTES` | empty          | Minutes before an empty dynamic zone shuts down         |
| `STATIC_ZONES`                  | empty          | Comma-separated zone short names to keep running        |
| `STATIC_ZONE_PORT_START`        | `7401`         | First static zone port                                  |
| `STATIC_ZONE_PORT_END`          | `7425`         | Last static zone port                                   |
| `COMPOSE_PROFILES`              | empty          | Optional tools: `phpmyadmin`, `peqeditor`               |
| `PHPMYADMIN_PORT`               | `8080`         | phpMyAdmin port                                         |
| `PEQ_EDITOR_PORT`               | `8081`         | PEQ editor port                                         |
| `PEQ_EDITOR_PASSWORD`           | required*      | PEQ editor admin password (*if `peqeditor` is enabled)  |

Changing `LOGIN_PASSWORD_SALT` invalidates the password of every existing
login account, because every password is hashed with it.

Changing `DATABASE_USER`, `DATABASE_PASSWORD` or `DATABASE_NAME` after the
first start has no effect on the existing database, which keeps the
credentials it was created with. Reset the database to apply them.

## Common tasks

```bash
# Follow the logs of one service
docker compose logs -f world

# Stop everything (the database is kept)
docker compose down

# Open a database shell
docker compose exec db sh -c 'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'

# Reset the database to a fresh import (deletes all accounts and characters)
docker compose down -v
docker compose up -d --build
```

The SQL files in `containers/database` only run when the database volume is
first created. To apply a change to them on an existing database, run the
file through the database shell or reset the database.

## Optional fixes

[`optional/`](optional/) has SQL changes you can apply by hand, such as
turning off Quarm's shortened respawn times. Its README describes each one,
how to apply and undo it, and other Quarm rules worth knowing about.

## Updating the server

To update to newer Quarm code and content:

```bash
git submodule update --remote Server Quests Maps
```

Then check `Server/utils/sql` for changes the database container needs:

  - `containers/database/Dockerfile` imports a dated database dump from
    `Server/utils/sql/database_full`. Point it at the newest one.
  - It also applies files from `Server/utils/sql/git/required` that the dump
    does not include. Check for new files there and add any the dump is
    missing.

Rebuild with `docker compose up -d --build`. A database change needs a reset
(`docker compose down -v`) or the new SQL applied by hand.

## Troubleshooting

  - **"Zone is not running" / can't enter the world**: check world's log for
    the `boats` and `dynzone1` launchers identifying themselves and zones
    connecting. If they are missing, check the `zone` and `boats` logs.
  - **Server list shows the server but zoning fails**: `SERVER_ADDRESS` is
    not reachable from the client, or the zone ports are blocked.
  - **Chat channels do not connect**: world tells clients to use
    `SERVER_ADDRESS` port 7778 for chat, so that port must be reachable. A
    player only gets the address when entering the world from character
    select, so after changing `SERVER_ADDRESS` they need to camp and log back
    in.
  - **World warns about Docker or a public address mismatch**: these startup
    checks compare `SERVER_ADDRESS` with the container and public IPs. They
    are only a problem if clients outside your network need to connect.
