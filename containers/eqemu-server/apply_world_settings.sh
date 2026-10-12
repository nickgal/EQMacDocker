#!/bin/bash
# Apply settings from .env to the database, then run the given command:
#   - DYNAMIC_ZONES and STATIC_ZONES to the launcher tables
#   - DYNAMIC_ZONE_SHUTDOWN_MINUTES to the zone table
#   - SERVER_ADDRESS to the chat server address world gives clients
# World reads these only when it starts, so this runs in the world container
# just before world.
set -euo pipefail

DYNAMIC_LAUNCHER=dynzone1
DYNAMIC_ZONES=${DYNAMIC_ZONES:-10}
LAUNCHER=static
PORT_START=${STATIC_ZONE_PORT_START:-7401}
PORT_END=${STATIC_ZONE_PORT_END:-7425}

export MYSQL_PWD="$DATABASE_PASSWORD"
sql() {
    mariadb -h db -u "$DATABASE_USER" -N -B "$DATABASE_NAME" -e "$1"
}

# World sends clients Quarm:ChatHostname and Quarm:ChatPort as the chat server
# address. The Quarm database points them at Project Quarm's live server.
SERVER_ADDRESS=${SERVER_ADDRESS:-}
if [[ ! "$SERVER_ADDRESS" =~ ^[A-Za-z0-9.-]+$ ]]; then
    echo "SERVER_ADDRESS: must be set to a hostname or IP address, got [$SERVER_ADDRESS]" >&2
    exit 1
fi

# World names dynamic zones dynamic_01 through dynamic_254.
if [[ ! "$DYNAMIC_ZONES" =~ ^[0-9]+$ ]] || (( 10#$DYNAMIC_ZONES > 254 )); then
    echo "DYNAMIC_ZONES: must be a number from 0 to 254, got [$DYNAMIC_ZONES]" >&2
    exit 1
fi

# Zones read shutdowndelay (milliseconds, a signed 32-bit int) when they boot.
SHUTDOWN_MINUTES=${DYNAMIC_ZONE_SHUTDOWN_MINUTES:-}
if [ -n "$SHUTDOWN_MINUTES" ]; then
    if [[ ! "$SHUTDOWN_MINUTES" =~ ^[0-9]+$ ]] || (( 10#$SHUTDOWN_MINUTES < 1 || 10#$SHUTDOWN_MINUTES > 35791 )); then
        echo "DYNAMIC_ZONE_SHUTDOWN_MINUTES: must be a number from 1 to 35791, got [$SHUTDOWN_MINUTES]" >&2
        exit 1
    fi
fi

zones=()
IFS=', ' read -ra items <<< "${STATIC_ZONES:-}"
for zone in "${items[@]}"; do
    zone=${zone,,}
    if [[ ! "$zone" =~ ^[a-z0-9_]+$ ]]; then
        echo "STATIC_ZONES: invalid zone name [$zone]" >&2
        exit 1
    fi
    if [[ " ${zones[*]} " != *" $zone "* ]]; then
        zones+=("$zone")
    fi
done

if (( ${#zones[@]} > 0 )); then
    in_list="'$(IFS=,; echo "${zones[*]}" | sed "s/,/','/g")'"

    known=$(sql "SELECT short_name FROM zone WHERE short_name IN ($in_list)")
    for zone in "${zones[@]}"; do
        if ! grep -qx "$zone" <<< "$known"; then
            echo "STATIC_ZONES: unknown zone [$zone]" >&2
            exit 1
        fi
    done

    boats=$(sql "SELECT zone FROM launcher_zones WHERE launcher = 'boats' AND zone IN ($in_list)")
    if [ -n "$boats" ]; then
        echo "STATIC_ZONES: already run by the boats launcher: $(echo $boats)" >&2
        exit 1
    fi

    if (( PORT_START + ${#zones[@]} - 1 > PORT_END )); then
        echo "STATIC_ZONES: ${#zones[@]} zones do not fit in ports $PORT_START-$PORT_END" >&2
        exit 1
    fi
fi

echo "Dynamic zones: [$DYNAMIC_ZONES]"
DYNAMIC_ZONES=$((10#$DYNAMIC_ZONES))
statements="INSERT INTO launcher (name, dynamics) VALUES ('$DYNAMIC_LAUNCHER', $DYNAMIC_ZONES)
    ON DUPLICATE KEY UPDATE dynamics = $DYNAMIC_ZONES;
INSERT INTO launcher (name, dynamics) VALUES ('$LAUNCHER', 0)
    ON DUPLICATE KEY UPDATE dynamics = 0;
DELETE FROM launcher_zones WHERE launcher = '$LAUNCHER';"
port=$PORT_START
for zone in "${zones[@]}"; do
    statements+="
INSERT INTO launcher_zones (launcher, zone, port, enabled) VALUES ('$LAUNCHER', '$zone', $port, 1);"
    echo "Static zone [$zone] on port [$port]"
    port=$((port + 1))
done
echo "Chat server: [$SERVER_ADDRESS:7778]"
statements+="
UPDATE rule_values SET rule_value = '$SERVER_ADDRESS' WHERE rule_name = 'Quarm:ChatHostname';
UPDATE rule_values SET rule_value = '7778' WHERE rule_name = 'Quarm:ChatPort';"
if [ -n "$SHUTDOWN_MINUTES" ]; then
    echo "Dynamic zone shutdown delay: [$SHUTDOWN_MINUTES] minutes"
    statements+="
UPDATE zone SET shutdowndelay = $((10#$SHUTDOWN_MINUTES * 60000));"
fi
sql "$statements"

exec "$@"
