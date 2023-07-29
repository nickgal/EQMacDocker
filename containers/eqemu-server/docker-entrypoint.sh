#!/bin/bash
set -e

envsubst < login.template.ini > login.ini
envsubst < eqemu_config.template.json > eqemu_config.json

/wait && exec "$@"
