#!/bin/bash
# Run the static zone launcher only when STATIC_ZONES lists at least one zone.
set -e

if [ -z "${STATIC_ZONES//[ ,]/}" ]; then
    echo "STATIC_ZONES is empty; static zone launcher not needed"
    exit 0
fi

exec /app/eqlaunch static
