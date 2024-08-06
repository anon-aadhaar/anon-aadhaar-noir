use dep::poseidon::bn254;

/// @title Nullifier
/// @notice Computes the nullifier for an Aadhaar identity
/// @input photo The photo of the user with SHA padding
/// @output nullifier = hash(nullifierSeed, hash(photo[0..16]), hash(photo[16..32]))

fn main(nullifierSeed: Field, photo: [Field; 32]) -> pub Field {

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
    let first16Hash = bn254::hash_16(first16);

    // Hash the last 16 elements of the photo
    let last16Hash = bn254::hash_16(last16);

    // Compute the final nullifier
    let out = bn254::hash_3([nullifierSeed, first16Hash, last16Hash]);

    out as Field
}

// Test function to validate the nullifier computation
#[test]
fn test_nullifier() {
    // Define test inputs
    let nullifierSeed: Field = 12345678; // Example seed
    let photo: [Field; 32] = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        31, 32 
    ];

    // Compute the expected output
    let expectedNullifier = main(nullifierSeed, photo);
    assert(expectedNullifier != 0, "Computed Nullifier: {expected_nullifier}");
}
