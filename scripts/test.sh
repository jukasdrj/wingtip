#!/bin/bash

# Wingtip Test Runner Script
# Usage: ./scripts/test.sh [quick|full|all]

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Test execution functions
run_integration_tests() {
    print_header "Running Integration Tests (Quick Smoke)"
    if flutter test test/integration/critical_flows_test.dart; then
        print_success "Integration tests passed"
        return 0
    else
        print_error "Integration tests failed"
        return 1
    fi
}

run_widget_tests() {
    print_header "Running Widget Tests"
    if flutter test test/features/; then
        print_success "Widget tests passed"
        return 0
    else
        print_error "Widget tests failed"
        return 1
    fi
}

run_unit_tests() {
    print_header "Running Unit Tests"
    if flutter test test/core/ test/data/ test/services/; then
        print_success "Unit tests passed"
        return 0
    else
        print_error "Unit tests failed"
        return 1
    fi
}

run_all_tests() {
    print_header "Running All Tests"
    if flutter test; then
        print_success "All tests passed"
        return 0
    else
        print_error "Some tests failed"
        return 1
    fi
}

run_analyze() {
    print_header "Running Static Analysis"
    if flutter analyze; then
        print_success "Static analysis passed"
        return 0
    else
        print_error "Static analysis found issues"
        return 1
    fi
}

# Main script logic
MODE=${1:-full}

case "$MODE" in
    quick)
        print_header "Quick Smoke Test (~30 seconds)"
        echo "Running integration tests only..."
        run_integration_tests
        EXIT_CODE=$?
        ;;

    full)
        print_header "Full Safety Net (~2-3 minutes)"
        echo "Running integration + widget tests..."
        run_integration_tests
        INT_CODE=$?
        run_widget_tests
        WIDGET_CODE=$?
        EXIT_CODE=$((INT_CODE + WIDGET_CODE))
        ;;

    all)
        print_header "Everything: Analyze + All Tests (~3-5 minutes)"
        echo "Running static analysis and complete test suite..."
        run_analyze
        ANALYZE_CODE=$?
        run_all_tests
        TEST_CODE=$?
        EXIT_CODE=$((ANALYZE_CODE + TEST_CODE))
        ;;

    unit)
        print_header "Unit Tests Only"
        echo "Running core, data, and service tests..."
        run_unit_tests
        EXIT_CODE=$?
        ;;

    widget)
        print_header "Widget Tests Only"
        echo "Running feature widget tests..."
        run_widget_tests
        EXIT_CODE=$?
        ;;

    *)
        echo -e "${RED}Error: Unknown mode '$MODE'${NC}"
        echo ""
        echo "Usage: $0 [quick|full|all|unit|widget]"
        echo ""
        echo "Modes:"
        echo "  quick   - Integration tests only (~30 sec)"
        echo "  full    - Integration + widget tests (~2-3 min) [DEFAULT]"
        echo "  all     - Analyze + all tests (~3-5 min)"
        echo "  unit    - Unit tests only (core/data/services)"
        echo "  widget  - Widget tests only (features)"
        echo ""
        echo "Examples:"
        echo "  ./scripts/test.sh quick        # Quick pre-commit check"
        echo "  ./scripts/test.sh              # Full safety net (default)"
        echo "  ./scripts/test.sh all          # Complete validation"
        exit 1
        ;;
esac

# Print summary
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    print_success "All checks passed! ✨"
    echo ""
else
    print_error "Some checks failed. Please fix issues before committing."
    echo ""
fi

exit $EXIT_CODE
