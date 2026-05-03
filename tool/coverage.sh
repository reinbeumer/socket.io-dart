#!/bin/bash
# Run tests with coverage

set -e

echo "🧪 Running tests with coverage..."
echo ""

# Run tests with coverage
dart test --coverage=coverage

# Install coverage tool if not already installed
if ! dart pub global list | grep -q coverage ; then
    echo "Installing coverage tool..."
    dart pub global activate coverage
fi

# Format coverage
echo ""
echo "📊 Formatting coverage report..."
dart pub global run coverage:format_coverage \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info \
    --report-on=lib

echo ""
echo "✅ Coverage report generated: coverage/lcov.info"
echo ""
echo "To view coverage in browser:"
echo "  genhtml coverage/lcov.info -o coverage/html"
echo "  open coverage/html/index.html"
