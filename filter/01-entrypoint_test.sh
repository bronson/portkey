#!/bin/bash

source ../run-tests.sh

# TODO: what happens if a test exports some variables?
# That messes up following tests right?

# tests should be self-contained, able to run in parallel with other
# tests, and not depend on what order they're run in.

# TODO: should automatically start_testing when including the test script
# and automatically end testing when the script exits?
start_testing

test:ports-envar-is-necessary()
{
    ensure "ports environment variable is necessary"
    bash ../../entrypoint.sh   # TODO TODO
    is_eq 1 $?
    stderr_is "Error: PORTS environment variable is not set."
}
test:ports-envar-is-necessary


export PORTS="80,443"

# ensure "it can do a simple run"
# mock iptables 'echo "Mock iptables called with: $*"'
# mock tail 'echo "Mock tail called"; sleep 0.1'
# bash ../entrypoint.sh
# is_eq $? 1

# TODO: make this run automatically at end of file
stop_testing
