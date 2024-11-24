#!/bin/bash

cd ../circuits

BB_CMD=${1:-"bb"}
TIMEFORMAT='%R'

echo "Starting Benchmark Tests"
echo "Compiling Circuit & Executing"

# Compile circuit
nargo execute  --force --silence-warnings

# Get circuit size
circuit_output=$("$BB_CMD" gates -b ./target/aadhaar_qr_verifier.json | grep "circuit_size")    
circuit_size=$(echo "$circuit_output" | awk -F': ' '{print $2}' | tr -d ',')
echo "Circuit size: $circuit_size"
echo ""

echo "Testing Ultra Honk System"
echo ""

echo -n "1. Generating Ultra Honk proof                    "

output=$({ time $BB_CMD prove_ultra_honk -b ./target/aadhaar_qr_verifier.json -w ./target/aadhaar_qr_verifier.gz -o ./target/proof_ultra; } 2>&1)
ultra_prove_time=$(echo "$output" | tail -n1)
if [ $? -eq 0 ]; then
    echo "Time: $ultra_prove_time seconds"
else
    echo "Failed"
    echo "$output"
fi

echo -n "2. Generating Ultra Honk verifier key             "
output=$({ time $BB_CMD write_vk_ultra_honk -b ./target/aadhaar_qr_verifier.json -o ./target/vk_ultra; } 2>&1)
ultra_vk_time=$(echo "$output" | tail -n1)
if [ $? -eq 0 ]; then
    echo "Time: $ultra_vk_time seconds"
else
    echo "Failed"
    echo "$output"
fi

echo -n "3. Verifying Ultra Honk proof                     "
output=$({ time $BB_CMD verify_ultra_honk -k ./target/vk_ultra -p ./target/proof_ultra; } 2>&1)
ultra_verify_time=$(echo "$output" | tail -n1)
verify_status=$?
if [ $verify_status -eq 0 ] && [ -z "$(echo "$output" | grep -i 'failed')" ]; then
    echo "Time: $ultra_verify_time seconds ✅"
else
    echo "Time: $ultra_verify_time seconds ❌"
    echo "$output"
fi

echo "Testing Default BB System"

echo -n "1. Generating Default proof                       "
output=$({ time "$BB_CMD" prove -b ./target/aadhaar_qr_verifier.json -w ./target/aadhaar_qr_verifier.gz -o ./target/proof_default; } 2>&1)
default_prove_time=$(echo "$output" | tail -n1)
if [ $? -eq 0 ]; then
    echo "Time: $default_prove_time seconds"
else
    echo "Failed"
    echo "$output"
fi

echo -n "2. Generating Default verifier key                "
output=$({ time "$BB_CMD" write_vk -b ./target/aadhaar_qr_verifier.json -o ./target/vk_default; } 2>&1)
default_vk_time=$(echo "$output" | tail -n1)
if [ $? -eq 0 ]; then
    echo "Time: $default_vk_time seconds"
else
    echo "Failed"
    echo "$output"
fi

echo -n "3. Verifying Default proof                        "
output=$({ time "$BB_CMD" verify -k ./target/vk_default -p ./target/proof_default; } 2>&1)
default_verify_time=$(echo "$output" | tail -n1)
verify_status=$?
if [ $verify_status -eq 0 ] && [ -z "$(echo "$output" | grep -i 'failed')" ]; then
    echo "Time: $default_verify_time seconds ✅"
else
    echo "Time: $default_verify_time seconds (✗)"
    echo "$output"
fi
echo ""

echo "Benchmark Summary"
echo "Circuit size: $circuit_size"
printf "\nOperation       Ultra Honk    Default BB\n"
printf "Proving         %-12s  %-12s\n" "${ultra_prove_time}s" "${default_prove_time}s"
printf "VK Generation   %-12s  %-12s\n" "${ultra_vk_time}s" "${default_vk_time}s" 
printf "Verification    %-12s  %-12s\n" "${ultra_verify_time}s" "${default_verify_time}s"

rm -f ./target/proof_ultra ./target/vk_ultra ./target/proof_default ./target/vk_default 
