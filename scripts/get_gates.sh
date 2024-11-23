
#!/bin/bash

BB_CMD=${1:-"bb"}

cd ../circuits

## Compile the circuit
nargo compile --force --silence-warnings


circuit_output=$("$BB_CMD" gates -b ./target/aadhaar_qr_verifier.json | grep "circuit_size")    
circuit_size=$(echo "$circuit_output" | awk -F': ' '{print $2}' | tr -d ',')

echo "circuit size: $circuit_size"