#!/bin/bash

# Testing Shell Kit

# TODO: is the current scheme of littering tsk-test-nn directories
# the right way to go, or should I just blow away a single tsk-test
# directory on every run and the user can copy any dirs they want to keep?

# Guidance:
#  - Tests are meant to look and act like bash code. Totally familiar.
#  - Testing is self-contained, nothing to install on the host.
#  - Test output should contain enough information to see what went wrong.
#
# Tests are run with an empty writeable directory as the CWD. They
# are expected to leave this directory empty when they're finished,
# otherwise the test fails. TODO
#
# If your test produces output on stderr, make sure to check it,
# otherwise the test will fail. If you want to
# ignore stderr, you can do something like TODO: `stderr_matches .`
#

tsk_version="0.1"

# reserving the tsk_ prefix ensures that there will be no conflicts
# with variables in the tests themselves.
tsk_total_count=0     # current number of tests run
tsk_pass_count=0      # current number of tests passed
tsk_fail_count=0      # current number of tests failed
tsk_run_dir=""        # directory continaing everything when running tests

tsk_test_name=""      # the name of the test currently being run
tsk_test_errors=0     # the number of errors
tsk_test_messages=""  # string containing a message for each error
tsk_stderr_checked=false # whether stderr has been explicitly checked

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# save stdout and stderr so we can restore them after testing
exec 3>&1 4>&2

pluralize() {
    local count=$1
    local singular=$2
    local plural=${3:-${singular}s}

    if [ "$count" -eq 1 ]; then
        echo "$singular"
    else
        echo "$plural"
    fi
}

# returns the line number of the caller of the given frame
# defaults to the caller of the function calling _line_number
_line_number() {
    local frame=${1:-1}
    local info=$(caller $frame)
    echo "${info%% *}"
}

# used to quote large content in the test output, like stderr
_blockquote() {
    echo -n "$1" | sed 's/^/    | /'
}

_add_error() {
    local message="$1"

    tsk_test_errors=$((tsk_test_errors + 1))
    if [ -n "$tsk_test_messages" ]; then
        tsk_test_messages="$tsk_test_messages"$'\n'
    fi
    tsk_test_messages="$tsk_test_messages  - $message"
}

_add_error_with_stderr() {
    _add_error "$@"
    local snippet="$(head -n 20 "$tsk_run_dir/stderr")"
    tsk_test_messages="$tsk_test_messages"$'\n'"$(_blockquote "$snippet")"
}


_start_mocking() {
    local mock_dir="$tsk_run_dir/bin-mocks"
    mkdir "$mock_dir"
    export PATH="$mock_dir:$PATH"
}

mock() {
    local command="$1"
    local behavior="$2"
    local executable="$tsk_run_dir/bin-mocks/$command"
    cat > "$executable" << EOF
#!/bin/bash
$behavior
EOF
    chmod +x "$executable"
}

# at the end of the test, all mocks are removed
# TODO: one day we might want to set up mocks for multiple tests
_cleanup_mocks() {
    rm -rf "$tsk_run_dir"/bin-mocks/* "$tsk_run_dir"/bin-mocks/.*
}

_stop_mocking(){
    # no need to remove this dir from PATH because we're about to exit
    rmdir "$tsk_run_dir/bin-mocks"
    if [ $? -ne 0 ]; then
        echo "Internal error: mock dir wasn't empty?! This is a bug, I'M OUT" >&4
        exit 5
    fi
}


end_test() {
    _cleanup_mocks

    if [ -s "$tsk_run_dir/stderr" ] && [ "$tsk_stderr_checked" = false ]; then
        _add_error_with_stderr "test produced stderr:"
    fi

    local res
    if [ "$tsk_total_count" -gt 0 ]; then
        if [ "$tsk_test_errors" -eq 0 ]; then
            tsk_pass_count=$((tsk_pass_count + 1))
            res="${GREEN}pass${NC}"
        else
            tsk_fail_count=$((tsk_fail_count + 1))
            res="${RED}FAIL${NC}"
        fi

        local errmsg=''
        if [ $tsk_test_errors -gt 0 ]; then
            errmsg="($tsk_test_errors $(pluralize "$tsk_test_errors" "error"))"
        fi

        printf "\r %02d $res   $tsk_test_name $errmsg\n" "$tsk_total_count" >&3

        if [ -n "$tsk_test_messages" ]; then
            echo "$tsk_test_messages" >&3
        fi
    fi
}

ensure() {
    end_test  # if a test is already running, end it

    tsk_test_errors=0
    tsk_test_name="$1"
    tsk_stderr_checked=false
    tsk_total_count=$((tsk_total_count + 1))

    # TODO: do this in a dedicated directory?
    exec 1>"$tsk_run_dir/stdout" 2>"$tsk_run_dir/stderr"

    # no newline, end_test will back up and print the result
    printf " %02d ....   $tsk_test_name" "$tsk_total_count" >&3
}

is_eq() {
    local expected=$1
    local actual=$2

    if [ "$expected" != "$actual" ]; then
        _add_error "line $(_line_number): is_eq expected '$expected', got '$actual'"
    fi
}

stderr_contains() {
    local expected_text="$1"

    tsk_stderr_checked=true
    if ! grep -q "$expected_text" "$tsk_run_dir/stderr"; then
        _add_error_with_stderr "stderr_contains line $(_line_number): stderr doesn't contain: '$expected_text'"
    fi
}

# One trailing newline, if present, is trimmed from stdout before comparison.
# If you need to be pedantically correct about the presence of the final
# newline, you'll have to check for it outside of this function.
# TODO: this is not great.
stderr_is() {
    local expected_text="$1"
    local actual_text=$(cat "$tsk_run_dir/stderr")

    echo -n "$expected_text" > /tmp/et
    echo -n "$actual_text" > /tmp/at

    tsk_stderr_checked=true
    if [ "$expected_text" != "$actual_text" ]; then
        local msg="stderr should have been: "$'\n'"$(_blockquote "$expected_text")"$'\n'"    but was:"
        _add_error_with_stderr "stderr_is line $(_line_number): $msg"
    fi
}

start_testing() {
    tsk_total_count=0
    tsk_pass_count=0
    tsk_fail_count=0

    tsk_test_name=""

    # TODO: ensure local directory is writeable first, bounce to /tmp if not
    # TODO: option to create and mount a ramdisk to run tests

    # Find an available test directory
    local dir_num=1
    while [ -e "tsk-test-$(printf "%02d" $dir_num)" ]; do
        dir_num=$((dir_num + 1))
        if [ $dir_num -gt 99 ]; then
            echo "Too many test directories. `rm -r tsk-test-*`" >&4
            exit 1
        fi
    done
    tsk_run_dir="tsk-test-$(printf "%02d" $dir_num)"

    mkdir "$tsk_run_dir"
    [ $? -ne 0 ] && exit 1   # error should already be printed

    touch "$tsk_run_dir/stdout" "$tsk_run_dir/stderr"
    _start_mocking
}

stop_testing() {
    end_test
    _stop_mocking

    exec 1>&3 2>&4

    local color="$YELLOW"
    if [ $tsk_fail_count -eq 0 ]; then
        color="$GREEN"
    fi
    local count="${tsk_total_count} $(pluralize "$tsk_total_count" "test")"
    echo -e "${color}$count: ${tsk_pass_count} passed, ${tsk_fail_count} failed${NC}"
}

# TODO: should automatically start_testing when including the test script
# and automatically end testing when the script exits?
start_testing

# TODO: maybe one day we'll write our tests something like this?
# test:ports-envar-is-necessary() {
# }

ensure "ports environment variable is necessary"
bash ../entrypoint.sh
is_eq 1 $?
stderr_is "Error: PORTS environment variable is not set."

export PORTS="80,443"

# ensure "it can do a simple run"
# mock iptables 'echo "Mock iptables called with: $*"'
# mock tail 'echo "Mock tail called"; sleep 0.1'
# bash ../entrypoint.sh
# is_eq $? 1

# TODO: make this run automatically at end of file
stop_testing
