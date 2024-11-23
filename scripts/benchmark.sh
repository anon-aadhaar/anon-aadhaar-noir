#!/bin/bash

cd ../circuits

# Get the blackbox command from argument or default to "bb"
BB_CMD=${1:-"bb"}

# Set time format to only show real time
TIMEFORMAT='%R'

echo "----------------------------------------"

# Compile
echo "Compiling the circuit..."
nargo compile --force --silence-warnings

circuit_output=$("$BB_CMD" gates -b ./target/aadhaar_qr_verifier.json | grep "circuit_size")    
circuit_size=$(echo "$circuit_output" | awk -F': ' '{print $2}' | tr -d ',')
    
echo "Circuit size: $circuit_size"
echo "----------------------------------------"

# Prove
echo "Generating the proof..."
prove_time=$({ time "$BB_CMD" prove_ultra_honk -b ./target/aadhaar_qr_verifier.json -w ./target/aadhaar_qr_verifier.gz -o ./target/proof; } 2>&1 | tail -n1)
echo "Proving time: $prove_time seconds"
echo "----------------------------------------"

# Generate verifier key
echo "Generating the verifier key..."
vk_time=$({ time "$BB_CMD" write_vk -b ./target/aadhaar_qr_verifier.json -o ./target/vk; } 2>&1 | tail -n1)
echo "VK Generation time: $vk_time seconds"
echo "----------------------------------------"

# Verify
echo "Verifying the proof..."
verify_time=$({ time "$BB_CMD" verify -k ./target/vk -p ./target/proof; } 2>&1 | tail -n1)
echo "Verification time: $verify_time seconds"

# # Check verification status without the warning messages
# if "$BB_CMD" verify -k ./target/vk -p ./target/proof; then
#     echo "✅ Proof verified successfully"
# else
#     echo "❌ Proof verification failed"
# fi