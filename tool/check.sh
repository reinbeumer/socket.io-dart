#!/bin/bash
# Development check script - runs all quality checks

set -e  # Exit on error

WITH_POLLING_SMOKE=false
for arg in "$@"; do
  case "$arg" in
    --with-polling-smoke)
      WITH_POLLING_SMOKE=true
      ;;
    -h|--help)
      echo "Usage: tool/check.sh [--with-polling-smoke]"
      echo ""
      echo "Options:"
      echo "  --with-polling-smoke   Also run example/polling_smoke.dart against example server"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Run: tool/check.sh --help"
      exit 1
      ;;
  esac
done

echo "Running Dart quality checks..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Format check
echo "Checking code formatting..."
if dart format --output=none --set-exit-if-changed . ; then
    echo -e "${GREEN}OK Code is properly formatted${NC}"
else
    echo -e "${RED}FAIL Code formatting issues found${NC}"
    echo "  Run: dart format ."
    exit 1
fi
echo ""

# Analysis
echo "Running static analysis..."
if dart analyze ; then
    echo -e "${GREEN}OK No analysis issues found${NC}"
else
    echo -e "${RED}FAIL Analysis issues found${NC}"
    exit 1
fi
echo ""

# Tests
echo "Running tests..."
if dart test ; then
    echo -e "${GREEN}OK All tests passed${NC}"
else
    echo -e "${RED}FAIL Some tests failed${NC}"
    exit 1
fi
echo ""

# Optional polling smoke check
if [ "$WITH_POLLING_SMOKE" = true ]; then
    echo "Running optional polling smoke check..."

    # Start example server in background
    dart run example/example_server.dart >/tmp/tp_socket_io_example_server.log 2>&1 &
    SERVER_PID=$!

    cleanup_server() {
      if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
        kill "$SERVER_PID" >/dev/null 2>&1 || true
      fi
    }
    trap cleanup_server EXIT

    # Give server a moment to start
    sleep 2

    if dart run example/polling_smoke.dart ; then
        echo -e "${GREEN}OK Polling smoke check passed${NC}"
    else
        echo -e "${RED}FAIL Polling smoke check failed${NC}"
        echo "  Server log: /tmp/tp_socket_io_example_server.log"
        exit 1
    fi
    echo ""
fi

echo -e "${GREEN}SUCCESS All checks passed!${NC}"
echo ""
echo "Ready to commit!"
