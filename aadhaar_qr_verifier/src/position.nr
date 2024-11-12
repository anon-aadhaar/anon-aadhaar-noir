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
