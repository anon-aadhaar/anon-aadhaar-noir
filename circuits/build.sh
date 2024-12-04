# Extract version from Nargo.toml
VERSION=$(grep '^version = ' Nargo.toml | cut -d '"' -f 2)
echo "Circuit version: $VERSION"

echo "Compiling circuit..."
if ! nargo compile; then
    echo "Compilation failed. Exiting..."
    exit 1
fi

echo "Gate count:"
bb gates -b target/anon_aadhaar.json | jq  '.functions[0].circuit_size'


echo "Copying circuit.json to js/assets/..."
cp target/anon_aadhaar.json "../js/assets/circuit-$VERSION.json"

echo "Generating vkey..."
bb write_vk_ultra_honk -b ./target/anon_aadhaar.json -o ./target/vk

echo "Generating vkey.json to app/assets/..."
node -e "const fs = require('fs'); fs.writeFileSync('../js/assets/circuit-$VERSION-vkey.json', JSON.stringify(Array.from(Uint8Array.from(fs.readFileSync('./target/vk')))));"

echo "Done"
