pub mod nullifier;
pub mod signal;
pub mod extractor;

pub fn pack_bytes<let N: u32>(bytes: [u8; N]) -> [Field; N / 31 + 1] {
    let max_bytes_in_field = 31;
    let num_chunks = N / 31 + 1;
    let mut ints = [0 as Field; N / 31 + 1];

    // Precompute powers to ensure consistency
    let mut powers = [1 as Field; 31];
    for j in 1..31 {
        powers[j] = powers[j - 1] * 256;
    }

    for i in 0..num_chunks {
        let mut int_sum: Field = 0;
        for j in 0..max_bytes_in_field {
            let idx = max_bytes_in_field * i + j;
            if idx < N {
                // Use precomputed powers instead of direct power calculation
                int_sum += (bytes[idx] as Field) * powers[j];
            }
        }
        ints[i] = int_sum;
    }

    ints
}

// Position/order (not index) of fields in the data
pub fn reference_id_position() -> u64 {
    2
}

pub fn name_position() -> u64 {
    3
}

pub fn dob_position() -> u64 {
    4
}

pub fn gender_position() -> u64 {
    5
}

pub fn pincode_position() -> u64 {
    11
}

pub fn state_position() -> u64 {
    13
}

pub fn photo_position() -> u64 {
    18
}

// Maximum byte size for each field
pub fn max_field_byte_size() -> u64 {
    31
}

// Number of int chunks to pack the photo
// Photo can only be of max 32 * 31 bytes (pack_size * max_field_byte_size)
pub fn photo_pack_size() -> u64 {
    32
}

pub fn bytes_array_to_int<let N: u32>(input_bytes: [u8; N], n: u32) -> u32 {
    let mut sums: [u32; N + 1] = [0; N + 1];

    sums[0] = 0;

    for i in 0..n {
        assert(
            input_bytes[i] >= 48 & input_bytes[i] <= 57,
            "Input byte must be ASCII digit (48-57)",
        );

        sums[i + 1] = 10 * sums[i] + (input_bytes[i] - 48) as u32;
    }

    sums[n]
}
