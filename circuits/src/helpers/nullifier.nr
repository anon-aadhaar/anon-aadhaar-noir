/// @title Nullifier
/// @notice Computes the nullifier for an Aadhaar identity
/// @input photo The photo of the user with SHA padding
/// @output nullifier = hash(nullifierSeed, hash(photo[0..16]), hash(photo[16..32]))

pub fn nullifier_circuit(nullifierSeed: Field, photo: [Field; 33]) -> Field {
    assert(photo[32] == 0x00, "Photo last byte should be 0x00");

    // Initialize arrays to store slices
    let mut first16: [Field; 16] = [0; 16];
    let mut last16: [Field; 16] = [0; 16];
    // Populate first16 array using a for loop
    for i in 0..16 {
        first16[i] = photo[i];
    }

    // Populate last16 array using a for loop
    for i in 0..16 {
        last16[i] = photo[i + 16];
    }

    // Hash the first 16 elements of the photo
    let first16Hash = std::hash::poseidon::bn254::hash_16(first16);

    // Hash the last 16 elements of the photo
    let last16Hash = std::hash::poseidon::bn254::hash_16(last16);

    // Compute the final nullifier
    let out = std::hash::poseidon::bn254::hash_3([nullifierSeed, first16Hash, last16Hash]);

    out as Field
}
