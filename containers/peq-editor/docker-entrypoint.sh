#!/bin/bash
set -e

if [ -z "$PEQ_EDITOR_PASSWORD" ]; then
    echo "PEQ_EDITOR_PASSWORD must be set in .env to run the PEQ editor" >&2
    exit 1
fi

/wait
php /init_admin.php

exec "$@"
