#!/bin/bash

# Get the blackbox command from argument or default to "bb"
BB_CMD=${1:-"bb"}

# Set time format to only show real time
TIMEFORMAT='%R'

echo "Starting circuit operations..."
echo "----------------------------------------"

# Compile
echo "Compiling the circuit..."
compile_time=$(time nargo compile --force --silence-warnings 2>&1)
echo "Compilation time: ${compile_time}s"


circuit_output=$("$BB_CMD" gates -b ./target/aadhaar_qr_verifier.json | grep "circuit_size")    
circuit_size=$(echo "$circuit_output" | awk -F': ' '{print $2}' | tr -d ',')
    
echo "$project circuit size: $circuit_size"

# echo "----------------------------------------"

# Prove
echo "Generating the proof..."
prove_time=$(time "$BB_CMD" prove_ultra_honk -b ./target/aadhaar_qr_verifier.json -w ./target/aadhaar_qr_verifier.gz -o ./target/proof 2>&1)
echo "Proving time: ${prove_time}s"

# echo "----------------------------------------"

# Generate verifier key
echo "Generating the verifier key..."
vk_time=$(time "$BB_CMD" write_vk -b ./target/aadhaar_qr_verifier.json -o ./target/vk 2>&1)
echo "VK Generation time: ${vk_time}s"

# echo "----------------------------------------"

# Verify
echo "Verifying the proof..."
verify_time=$(time "$BB_CMD" verify -k ./target/vk -p ./target/proof 2>&1)
echo "Verification time: ${verify_time}s"

if [ $? -eq 0 ]; then
    echo "✅ Proof verified successfully"
else
    echo "❌ Proof verification failed"
fi