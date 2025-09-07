#!/bin/bash

# License Verification Edge Function Performance Testing Script
# Purpose: Measure P50/P90/P95/P99 latency for cold and hot paths
# Date: 2025-09-02
# Author: Backend Lead

# Configuration
FUNCTION_URL="https://dosbevgbkxrtixemfjfl.supabase.co/functions/v1/license-verification"
ANON_KEY="${SUPABASE_ANON_KEY}"  # Set this in environment
SAMPLES=50
OUTPUT_FILE="performance-results.csv"

# Test data
TCM_TEST_DATA='{
  "type": "tcm_practitioner",
  "license_number": "TCM-100001",
  "license_expiry": "2025-12-31T00:00:00Z"
}'

PHARMACY_TEST_DATA='{
  "type": "pharmacy",
  "license_number": "PHARM-200001",
  "license_expiry": "2025-12-31T00:00:00Z"
}'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== License Verification Edge Function Performance Test ===${NC}"
echo "Function URL: $FUNCTION_URL"
echo "Test Samples: $SAMPLES"
echo "Network Location: $(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)"
echo "Test Start Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

# Check if ANON_KEY is set
if [ -z "$ANON_KEY" ]; then
    echo -e "${RED}Error: SUPABASE_ANON_KEY not set${NC}"
    echo "Please set: export SUPABASE_ANON_KEY='your-key-here'"
    exit 1
fi

# Initialize CSV file
echo "test_type,sample_num,response_time_ms,http_code,timestamp" > $OUTPUT_FILE

# Function to run performance test
run_performance_test() {
    local test_name=$1
    local test_data=$2
    local test_type=$3
    
    echo -e "${YELLOW}Running $test_name ($test_type path)...${NC}"
    
    local times=()
    local errors=0
    
    for i in $(seq 1 $SAMPLES); do
        # Add delay for cold start simulation if needed
        if [ "$test_type" = "cold" ] && [ "$i" -eq 1 ]; then
            sleep 5  # Wait to ensure cold start
        fi
        
        # Execute request and capture metrics
        response=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" \
            -X POST "$FUNCTION_URL" \
            -H "Authorization: Bearer $ANON_KEY" \
            -H "Content-Type: application/json" \
            -d "$test_data")
        
        http_code=$(echo $response | cut -d',' -f1)
        time_total=$(echo $response | cut -d',' -f2)
        time_ms=$(echo "$time_total * 1000" | bc)
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Record to CSV
        echo "$test_name,$i,$time_ms,$http_code,$timestamp" >> $OUTPUT_FILE
        
        # Store time for statistics
        times+=($time_ms)
        
        # Check for errors
        if [ "$http_code" != "200" ]; then
            ((errors++))
        fi
        
        # Progress indicator
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo "" # New line after dots
    
    # Calculate statistics
    IFS=$'\n' sorted=($(sort -n <<<"${times[*]}"))
    unset IFS
    
    count=${#sorted[@]}
    p50_index=$((count * 50 / 100))
    p90_index=$((count * 90 / 100))
    p95_index=$((count * 95 / 100))
    p99_index=$((count * 99 / 100))
    
    p50=${sorted[$p50_index]}
    p90=${sorted[$p90_index]}
    p95=${sorted[$p95_index]}
    p99=${sorted[$p99_index]}
    
    # Calculate average
    sum=0
    for time in "${times[@]}"; do
        sum=$(echo "$sum + $time" | bc)
    done
    avg=$(echo "scale=2; $sum / $count" | bc)
    
    # Display results
    echo -e "${GREEN}Results for $test_name ($test_type):${NC}"
    echo "  Samples: $count"
    echo "  Errors: $errors"
    echo "  Average: ${avg}ms"
    echo "  P50: ${p50}ms"
    echo "  P90: ${p90}ms"
    echo "  P95: ${p95}ms"
    echo "  P99: ${p99}ms"
    echo ""
    
    # Check P95 target
    if (( $(echo "$p95 < 500" | bc -l) )); then
        echo -e "  ${GREEN}✓ P95 < 500ms target achieved${NC}"
    else
        echo -e "  ${RED}✗ P95 > 500ms target missed${NC}"
    fi
    echo ""
}

# Test 1: Cold Start Performance (TCM Practitioner)
echo -e "${GREEN}=== Test 1: Cold Start Performance ===${NC}"
run_performance_test "TCM_Cold" "$TCM_TEST_DATA" "cold"

# Test 2: Hot Path Performance (TCM Practitioner)
echo -e "${GREEN}=== Test 2: Hot Path Performance (TCM) ===${NC}"
run_performance_test "TCM_Hot" "$TCM_TEST_DATA" "hot"

# Test 3: Hot Path Performance (Pharmacy)
echo -e "${GREEN}=== Test 3: Hot Path Performance (Pharmacy) ===${NC}"
run_performance_test "Pharmacy_Hot" "$PHARMACY_TEST_DATA" "hot"

# Generate summary report
echo -e "${GREEN}=== Performance Test Summary ===${NC}"
echo "Test completed at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Results saved to: $OUTPUT_FILE"
echo ""
echo "Dashboard Performance Monitoring:"
echo "https://supabase.com/dashboard/project/dosbevgbkxrtixemfjfl/functions/license-verification/metrics"
echo ""

# Generate markdown report for documentation
cat > performance-report.md << EOF
# License Verification Edge Function Performance Report

## Test Configuration
- **Date**: $(date '+%Y-%m-%d %H:%M:%S %Z')
- **Function URL**: $FUNCTION_URL
- **Network Location**: $(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)
- **Sample Size**: $SAMPLES per test type
- **Test Types**: Cold Start, Hot Path (TCM), Hot Path (Pharmacy)

## Performance Metrics

### Cold Start Performance
- P50: Check CSV for actual values
- P90: Check CSV for actual values
- P95: Check CSV for actual values
- P99: Check CSV for actual values

### Hot Path Performance
- P50: Check CSV for actual values
- P90: Check CSV for actual values
- P95: Check CSV for actual values
- P99: Check CSV for actual values

## Methodology
- **Cold Start**: 5-second delay before first request to ensure function sleep
- **Hot Path**: Continuous requests without delay
- **Measurement**: curl time_total metric (includes network latency)
- **Network Position**: Tests run from local machine to Sydney region

## Compliance
- Target: P95 < 500ms
- Status: See test output for compliance status

## Raw Data
- CSV File: $OUTPUT_FILE
- Dashboard Logs: Check Supabase dashboard for server-side metrics
EOF

echo -e "${GREEN}Performance report generated: performance-report.md${NC}"