pub mod nullifier;
pub mod signal;
pub mod extractor;

// Constants for field positions
pub global REFERENCE_ID_POS = 2;
pub global NAME_POS = 3;
pub global DOB_POS: u32 = 4;
pub global GENDER_POS: u32 = 5;
pub global PINCODE_POS = 11;
pub global STATE_POS = 13;
pub global PHOTO_POS = 18;

struct AadharData {
    age: u32,
    gender: u32,
    pincode: u32,
    state: Field,
    timestamp: Field,
    photo: [Field; 33],
}

struct Date {
    year: u32,
    month: u32,
    day: u32,
    hour: u32,
}

pub fn bytes_array_to_int<let N: u32>(input_bytes: [u32; N], n: u32) -> u32 {
    let mut sums: [u32; N + 1] = [0; N + 1];

    for i in 0..n {
        let byte = input_bytes[i];
        assert(byte >= 48 & byte <= 57, "Invalid digit");
        sums[i + 1] = 10 * sums[i] + (byte - 48) as u32;
    }
    sums[n]
}
