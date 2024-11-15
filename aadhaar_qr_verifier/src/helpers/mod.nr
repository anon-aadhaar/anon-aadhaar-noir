pub mod nullifier;
pub mod signal;
pub mod cds;
pub mod extractor;
use super::MAX_BYTES_IN_FIELD;

pub struct QRData {
    pub ageAbove18: Field,
    pub gender: Field,
    pub pinCode: Field,
    pub state: Field,
}

pub fn bytes_to_int_chunks(bytes: [Field; 967]) -> [Field; 32] {
    let max_bytes_in_field = 31;
    // Math.ceil(bytes.length / maxBytesInField)
    // Math.cell(967/32)
    let num_chunks = 32;
    let mut ints = [0; 32];

    for i in 0..num_chunks {
        let mut int_sum: Field = 0;
        for j in 0..max_bytes_in_field {
            let idx = max_bytes_in_field * i + j;
            if idx < bytes.len() {
                int_sum += (bytes[idx] * 256.pow_32(j as Field));
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

/// Compute the number of chunks needed to pack bytes
/// @param byte_length: Length of input byte array
/// @return Number of chunks needed
fn compute_int_chunk_length(byte_length: u32) -> u32 {
    let pack_size = MAX_BYTES_IN_FIELD;
    let remain = byte_length % pack_size;
    let mut num_chunks = (byte_length - remain) / pack_size;

    if remain > 0 {
        num_chunks += 1;
    }

    num_chunks
}

/// Pack bytes into array of field-sized integers
/// @param input_bytes: Array of bytes to pack
/// @param max_bytes: Maximum number of bytes in input
/// @return Array of packed integers
// TODO NOT IMPLEMENTED: LEFT SHIFTING OVERFLOW AND WORKS ON U8;
pub fn pack_bytes<let N: u32>(input_bytes: [u8; N], max_bytes: u32) -> Vec<Field> {
    let pack_size = MAX_BYTES_IN_FIELD;
    let max_ints = compute_int_chunk_length(max_bytes);
    // Create array to store packed integers
    let mut out = Vec::new();

    // Process each chunk
    for i in 0..max_ints {
        let mut int_sums: [Field; MAX_BYTES_IN_FIELD] = [0; MAX_BYTES_IN_FIELD];

        // Process bytes within each chunk
        for j in 0..pack_size {
            let idx = (pack_size * i + j);
            if idx >= max_bytes {
                // Out of bounds - use previous value
                if j > 0 {
                    int_sums[j] = int_sums[(j - 1)];
                }
            } else if j == 0 {
                // First byte in chunk
                int_sums[0] = input_bytes[idx] as Field;
            } else {
                // let shift_amount: u8 = 1 << (8 * j) as u8;
                // int_sums[j] = (int_sums[(j - 1)] as Field) + shift_amount;
            }
        }
        // Add final sum for this chunk
        out.push(int_sums[(pack_size - 1)]);
    }
    out
}
