#!/bin/bash

BB_CMD=${1:-"bb"}

echo "Generating the proof... ✅"
"$BB_CMD" prove -b ./target/aadhaar_qr_verifier.json -w ./target/aadhaar_qr_verifier.gz -o ./target/proof

echo "Generating the verifier Key... ✅"
"$BB_CMD" write_vk -b ./target/aadhaar_qr_verifier.json -o ./target/vk

echo "Verifying the proof... "
out = "$BB_CMD" verify -k ./target/vk -p ./target/proof

if [ -z "$out" ]; then
    echo "Proof verified successfully ✅ "
else
    echo "Proof verification failed ❌"
fi
