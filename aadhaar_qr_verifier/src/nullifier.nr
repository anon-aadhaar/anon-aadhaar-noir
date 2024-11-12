use crate::position::photo_position;
use crate::utils::bytes_to_int_chunks;
use crate::PHOTO_END_INDEX;

/// @title Nullifier
/// @notice Computes the nullifier for an Aadhaar identity
/// @input photo The photo of the user with SHA padding
/// @output nullifier = hash(nullifierSeed, hash(photo[0..16]), hash(photo[16..32]))

pub fn nullifier_circuit(
    nullifierSeed: Field,
    delimiterIndices: [u64; 18],
    msg: [Field; 1152],
) -> Field {
    let mut photo_vec: [Field; 967] = [0; 967];

    let photo_start_index = delimiterIndices[photo_position() - 1] + 1;
    for i in photo_start_index..PHOTO_END_INDEX {
        photo_vec[i - photo_start_index] = msg[i];
    }

    let photo = bytes_to_int_chunks(photo_vec);

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
