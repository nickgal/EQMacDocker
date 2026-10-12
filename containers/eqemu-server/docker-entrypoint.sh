#!/bin/bash
set -e

envsubst < login.template.json > login.json
envsubst < eqemu_config.template.json > eqemu_config.json

/wait && exec "$@"
