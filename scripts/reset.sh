#!/bin/bash

# Kill OpenTEE
kill -9 `pidof tee_launcher`
kill -9 `pidof tee_manager`

set -e

# Rebuild xtest and TAs and reinstall them
make && sudo make install

# Start OpenTEE to reloads the new TAs
/opt/OpenTee/bin/opentee-engine
