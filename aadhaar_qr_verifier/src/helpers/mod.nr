pub mod nullifier;
pub mod signal;
pub mod cds;
pub mod timestamp;

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
