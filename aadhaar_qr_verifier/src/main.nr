mod utils;
mod position;

use dep::bignum::{params::BigNumParams, RuntimeBigNum};

use utils::QRData;
use position::{
    gender_position, reference_id_position, dob_position, pincode_position, state_position,
    photo_position,
};

use dep::rsa::{rsa::verify_sha256_pkcs1v15, types::RBN2048};

fn cds_circuit(
    revealAgeAbove18: Field,
    revealGender: Field,
    revealPinCode: Field,
    revealState: Field,
    qrDataExtractor: QRData,
    ageAbove18: Field,
    gender: Field,
    pinCode: Field,
    state: Field,
) {
    // Enforce binary constraints on reveal signals
    assert(revealAgeAbove18 * (revealAgeAbove18 - 1) == 0);
    assert(revealGender * (revealGender - 1) == 0);
    assert(revealPinCode * (revealPinCode - 1) == 0);
    assert(revealState * (revealState - 1) == 0);

    // Assign extracted values conditionally based on the reveal signals
    assert(ageAbove18 == revealAgeAbove18 * qrDataExtractor.ageAbove18);
    assert(gender == revealGender * qrDataExtractor.gender);
    assert(pinCode == revealPinCode * qrDataExtractor.pinCode);
    assert(state == revealState * qrDataExtractor.state);
}

// Define the main function for converting date and time to a Unix timestamp
fn timestamp_circuit(
    year: Field,
    month: Field,
    day: Field,
    hour: Field,
    minute: Field,
    second: Field,
    maxYears: Field,
    includeHours: bool,
    includeMinutes: bool,
    includeSeconds: bool,
) -> Field {
    // Ensure the input values are within valid ranges by casting to integers
    assert(year as i32 <= maxYears as i32);
    assert(month as i32 <= 12);
    assert(day as i32 >= 1);
    assert(day as i32 <= 31);
    assert(hour as i32 >= 0);
    assert(hour as i32 <= 23);
    assert(minute as i32 >= 0);
    assert(minute as i32 <= 59);
    assert(second as i32 >= 0);
    assert(second as i32 <= 59);

    // Days till the start of each month in a non-leap year
    let daysTillPreviousMonth: [i64; 12] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

    // Calculate the number of years and leap years since 1970
    let yearsSinceEpoch: i64 = (year as i64) - 1970;
    let leapYears: i64 = (yearsSinceEpoch + 1) / 4;

    // Calculate days passed in the current year
    let mut daysPassedInCurrentYear: i64 = (day as i64) - 1;
    for i in 0..12 {
        if (month as i32) - 1 > i as i32 {
            daysPassedInCurrentYear += daysTillPreviousMonth[i];
        }
    }

    // Add an extra day if it's a leap year and the date is after February
    if (month as i32) > 2 & ((year as i32 - 1972) % 4 == 0) {
        daysPassedInCurrentYear += 1;
    }

    // Calculate total days passed since Unix epoch
    let totalDaysPassed: i64 = yearsSinceEpoch * 365 + leapYears + daysPassedInCurrentYear;

    // Calculate the Unix timestamp
    let mut timestamp: i64 = totalDaysPassed * 86400;

    // Add hours, minutes, and seconds if included
    if includeHours {
        timestamp += (hour as i64) * 3600;
    }
    if includeMinutes {
        timestamp += (minute as i64) * 60;
    }
    if includeSeconds {
        timestamp += (second as i64);
    }

    // Output the final timestamp
    timestamp as Field
}

/// @title Nullifier
/// @notice Computes the nullifier for an Aadhaar identity
/// @input photo The photo of the user with SHA padding
/// @output nullifier = hash(nullifierSeed, hash(photo[0..16]), hash(photo[16..32]))

fn nullifier_circuit(nullifierSeed: Field, photo: [Field; 32]) -> Field {
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

fn bytes_to_int_chunks(bytes: [Field; 967]) -> [Field; 32] {
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

fn signal_circuit(signalHash: Field, signalHashSquare: Field) {
    // Dummy square to prevent signal tampering (in rare cases where non-constrained inputs are ignored)
    // Enforce the constraint that signalHashSquare is the square of signalHash
    assert(signalHashSquare == signalHash * signalHash);
}

fn extractor_circuit(
    msg: [Field; 1152], // we need to have only one circuit for these
    msg_str: str<2663>,
    // public_key: BNInst2048,
    // signature: BigNum<18, Params2048>,
    signature_limbs: [Field; 18],
    modulus_limbs: [Field; 18],
    redc_limbs: [Field; 18],
    delimiterIndices: [u64; 18],
) {
    let sha256_hash: [u8; 32] = dep::std::hash::sha256(msg_str.as_bytes());

    let has_multiplicative_inverse = false;
    let params: BigNumParams<18, 2048> =
        BigNumParams::new(has_multiplicative_inverse, modulus_limbs, redc_limbs);

    let signature: RBN2048 = RuntimeBigNum::from_array(params, signature_limbs);

    // Verify the RSA signature
    assert(verify_sha256_pkcs1v15(sha256_hash, signature, 65537));

    // Timestamp extraction
    let mut year: [Field; 4] = [0; 4];
    let mut month: [Field; 2] = [0; 2];
    let mut day: [Field; 2] = [0; 2];
    let mut hour: [Field; 2] = [0; 2];
    let year_start_index = delimiterIndices[reference_id_position() - 1] + 5;
    let year_end_index = year_start_index + year.len() as u64;
    let month_start_index = year_end_index;
    let month_end_index = month_start_index + month.len() as u64;
    let day_start_index = month_end_index;
    let day_end_index = day_start_index + day.len() as u64;
    let hour_start_index = day_end_index;
    let hour_end_index = hour_start_index + hour.len() as u64;
    let mut year_val = 0;
    for i in year_start_index..year_end_index {
        year[i - year_start_index] = msg[i] - 48;
        year_val = 10 * year_val + (year[i - year_start_index]);
    }
    let mut month_val = 0;
    for i in month_start_index..month_end_index {
        month[i - month_start_index] = msg[i] - 48;
        month_val = month_val * 10 + month[i - month_start_index];
    }
    let mut day_val = 0;
    for i in day_start_index..day_end_index {
        day[i - day_start_index] = msg[i] - 48;
        day_val = day_val * 10 + day[i - day_start_index];
    }
    let mut hour_val = 0;
    for i in hour_start_index..hour_end_index {
        hour[i - hour_start_index] = msg[i] - 48;
        hour_val = 10 * hour_val + hour[i - hour_start_index];
    }
    let mut minute_val = 0;
    let mut second_val = 0;
    // Date of birth extraction
    let mut birth_year_vec: [Field; 4] = [0; 4];
    let mut birth_month_vec: [Field; 2] = [0; 2];
    let mut birth_date_vec: [Field; 2] = [0; 2];
    let mut age = 0;
    let birthday_start_index = delimiterIndices[dob_position() - 1] + 1;
    let birthday_end_index = delimiterIndices[dob_position()];
    let birth_date_start_index = birthday_start_index;
    let birth_date_end_index = birth_date_start_index + 1;
    let birth_month_start_index = birth_date_end_index + 2;
    let birth_month_end_index = birth_month_start_index + 1;
    let birth_year_start_index = birth_month_end_index + 2;
    let birth_year_end_index = birth_year_start_index + 3;
    for i in birthday_start_index..birthday_end_index {
        if i >= birth_date_start_index & i <= birth_date_end_index {
            birth_date_vec[i - birth_date_start_index] = msg[i] - 48;
        } else if i >= birth_month_start_index & i <= birth_month_end_index {
            birth_month_vec[i - birth_month_start_index] = msg[i] - 48;
        } else if i >= birth_year_start_index & i <= birth_year_end_index {
            birth_year_vec[i - birth_year_start_index] = msg[i] - 48;
        }
    }
    let birth_date_data = birth_date_vec[0] * 10 + birth_date_vec[1];
    let birth_month_data = birth_month_vec[0] * 10 + birth_month_vec[1];
    let birth_year_data = birth_year_vec[0] * 1000
        + birth_year_vec[1] * 100
        + birth_year_vec[2] * 10
        + birth_year_vec[3];
    // Calculate the Age
    let age_by_year = year_val - birth_year_data - 1;
    let mut age = age_by_year;
    if birth_month_data as u64 > month_val as u64 {
        age += 1;
    } else if birth_month_data as u64 == month_val as u64 {
        if birth_date_data as u64 > day_val as u64 {
            age += 1;
        }
    }
    // Calculate the Gender
    let gender_index = delimiterIndices[gender_position() - 1] + 1;
    let gender_data = msg[gender_index] - 65;
    // Calculate the Pincode of the Address
    let pincode_start_index = delimiterIndices[pincode_position() - 1] + 1;
    let pincode_end_index = delimiterIndices[pincode_position()];
    let mut pincode_vec: [Field; 6] = [0; 6];
    for i in pincode_start_index..pincode_end_index {
        pincode_vec[i - pincode_start_index] = msg[i] - 48;
    }
    let mut pincode_data = 0;
    for i in pincode_vec {
        pincode_data = pincode_data * 10 + i;
    }
    // Calculate the State of the Address
    let state_start_index = delimiterIndices[state_position() - 1] + 1;
    let state_end_index = delimiterIndices[state_position()];
    let mut state_vec: [Field; 5] = [0; 5];
    let mut state_data = 0;
    for i in state_start_index..state_end_index {
        state_vec[i - state_start_index] = msg[i] - 65;
        state_data = state_data * 10 + state_vec[i - state_start_index];
    }
    // Define a valid QRData instance
    let qrDataExtractor =
        QRData { ageAbove18: age, gender: gender_data, pinCode: pincode_data, state: state_data };
    // Test with reveal signals set to 1 (reveal the data)
    let revealAgeAbove18 = 1;
    let revealGender = 1;
    let revealPinCode = 1;
    let revealState = 1;
    // Expected values match qrDataExtractor values
    let ageAbove18 = age;
    let gender = gender_data;
    let pinCode = pincode_data;
    let state = state_data;
    // Call the circuit with valid inputs
    cds_circuit(
        revealAgeAbove18,
        revealGender,
        revealPinCode,
        revealState,
        qrDataExtractor,
        ageAbove18,
        gender,
        pinCode,
        state,
    );
    // Calculate nullifier
    let nullifierSeed: Field = 12345678; // Example seed
    let mut photo_vec: [Field; 967] = [0; 967];
    let photo_start_index = delimiterIndices[photo_position() - 1] + 1;
    let photo_end_index = 1152;
    for i in photo_start_index..photo_end_index {
        photo_vec[i - photo_start_index] = msg[i];
    }
    let photo_bytes_packed = bytes_to_int_chunks(photo_vec);
    let expectedNullifier = nullifier_circuit(nullifierSeed, photo_bytes_packed);
    assert(expectedNullifier != 0, "Computed Nullifier: {expected_nullifier}");
    std::print("Computed Nullifier: ");
    std::println(expectedNullifier);
    // Set maximum year and inclusion flags
    let maxYears = 2050;
    let includeHours = true;
    let includeMinutes = true;
    let includeSeconds = true;
    // Calculate the Unix timestamp using the circuit
    let timestamp = timestamp_circuit(
        year_val,
        month_val,
        day_val,
        hour_val,
        minute_val,
        second_val,
        maxYears,
        includeHours,
        includeMinutes,
        includeSeconds,
    );
    assert(timestamp != 0, "Non-zero timestamp computed: {timestamp}");
    std::print("Timestamp computed: ");
    std::println(timestamp);
    // Define a valid signalHash and its square
    let signalHash = 5;
    let signalHashSquare = 25;
    signal_circuit(signalHash, signalHashSquare);
}

#[test]
fn main() {
    let modulus_limbs = [
        0xcb9a7732071a1ec896e58500e6964b,
        0x591f624c2c8e8f46225415de4deb70,
        0xd0466b38cd631c4b767ae5b674d72,
        0xfad251739852ebfc515bb87cabc88,
        0x995d31bd29afd33ced28cb89652c03,
        0x9f2d673c75b6e081c2b39755f244bf,
        0xa8df137ad3c54e72e3d83fc9f68279,
        0xcc15c0a82416cb28c91549e2504814,
        0x1b0e4dacb94f050792d858c8513883,
        0x4d9fc8fe863ee5913e277659f21522,
        0x5b35e0b7d42d2dd9c3367762207e9e,
        0xca525419be4855a3bbc9b7732bc7fb,
        0x48adda99a4a45c675813f826418784,
        0x4d410ac97f9d2dd5a15660d617f727,
        0xee2ee57ff1250214758a4906f9a716,
        0x3d60cf4842c5a1d92aeffb3b5a4264,
        0xd4612ecea5b7cb8b829ac530994988,
        0xe7,
    ];

    let redc_limbs = [
        0xb1a54200541578edb31c3c25608db4,
        0xc144d6e3baa59b0a87d82f1388d4c8,
        0x76d8214546063a48c6133b5cad317e,
        0x64a5cec0df260e37df430faef764a7,
        0x1ad7f407e3daab66e17261f29bb1b8,
        0x9abc4bc1de236cdeb688b94800dc28,
        0x2603eec9b75a924c72a74d364308b0,
        0x854bff61a07eeeb5aa6a3b5674626d,
        0x3ca24ef9cb78bfc69674ae2d2d2d98,
        0xfd2b6914fd1de2ed9b8337b9b05e5e,
        0xe9dd65a87513f4b448abe18e1b320b,
        0x69d31874ad95df6af9b3d1a25e1dec,
        0xb3d44f8f9dfbcca3ce6ac8eceb4482,
        0x5848954d0780a09b1e0d6fcd09a92a,
        0x739c514ebce7b6a9ea8d5cafef6904,
        0x2859c86fd4c643436d3401fa42f586,
        0xbcc1f93bd0cde3199b3545075bfe9,
        0x11ab,
    ];

    let signature_limbs = [
        0x05f6a0461dfc18f100d3103e345b85,
        0x2922d1d0b1765b55cc23933e3a1bf5,
        0xe789de1b0b7acaba8a3542e1de1003,
        0x59660512223d15dbed650f5df355,
        0xa8bd9d75dfa75c4cfdd944af0fbf22,
        0xacb553a3bd5ca155899e4c9d71cfa5,
        0x145908c475c24e65aa48268e50a8c2,
        0x98a8d35194714c12121ff4967dc52c,
        0x0323b34a118a7a65b530583462f0bc,
        0x19dbe87de95a694d7399d218121ac1,
        0x96d071ee188805c1a7456b597382d6,
        0x71333c9f89fd9239f9f1c5126549ea,
        0xb58964da1d67735e6805d1de28c292,
        0x31e736dd30d5788ec84a9ffa652069,
        0x24745ec38c325f20f40a4bf47bab25,
        0x9fba29ed1c022abe03569d08be154d,
        0x0a8cb349d538e2f90f7d5b3a64b08f,
        0x64,
    ];
    let msg = [
        86, 50, 255, 51, 255, 50, 54, 57, 55, 50, 48, 50, 52, 48, 55, 49, 56, 49, 50, 52, 53, 53,
        55, 51, 56, 55, 255, 83, 117, 109, 105, 116, 32, 75, 117, 109, 97, 114, 255, 48, 49, 45, 48,
        49, 45, 49, 57, 56, 52, 255, 77, 255, 67, 47, 79, 32, 73, 115, 104, 119, 97, 114, 32, 67,
        104, 97, 110, 100, 255, 69, 97, 115, 116, 32, 68, 101, 108, 104, 105, 255, 255, 66, 45, 51,
        49, 44, 32, 51, 114, 100, 32, 70, 108, 111, 111, 114, 255, 255, 49, 49, 48, 48, 53, 49, 255,
        75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 68, 101, 108, 104, 105, 255,
        82, 97, 100, 104, 101, 121, 32, 83, 104, 121, 97, 109, 32, 80, 97, 114, 107, 32, 69, 120,
        116, 101, 110, 115, 105, 111, 110, 255, 71, 97, 110, 100, 104, 105, 32, 78, 97, 103, 97,
        114, 255, 75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 49, 50, 51, 52,
        255, 255, 79, 255, 81, 0, 47, 0, 0, 0, 0, 0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 7, 1, 1, 7, 1, 1, 7, 1, 1, 255, 82, 0, 12,
        2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 92, 0, 35, 66, 111, 24, 110, 234, 110, 234, 110, 188,
        103, 0, 103, 0, 102, 226, 95, 76, 95, 76, 95, 100, 72, 3, 72, 3, 72, 69, 79, 210, 79, 210,
        79, 97, 255, 100, 0, 34, 0, 1, 67, 114, 101, 97, 116, 101, 100, 32, 98, 121, 58, 32, 74, 74,
        50, 48, 48, 48, 32, 118, 101, 114, 115, 105, 111, 110, 32, 52, 46, 49, 255, 144, 0, 10, 0,
        0, 0, 0, 2, 236, 0, 1, 255, 82, 0, 12, 2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 147, 255, 145, 0,
        4, 0, 0, 195, 235, 5, 4, 11, 128, 38, 166, 255, 145, 0, 4, 0, 1, 192, 249, 65, 128, 16, 124,
        55, 255, 145, 0, 4, 0, 2, 192, 249, 65, 0, 14, 175, 255, 145, 0, 4, 0, 3, 195, 238, 4, 131,
        237, 4, 131, 232, 8, 15, 61, 227, 128, 14, 78, 244, 198, 10, 190, 128, 74, 255, 145, 0, 4,
        0, 4, 192, 30, 10, 3, 229, 7, 0, 240, 64, 15, 157, 12, 56, 206, 16, 124, 255, 145, 0, 4, 0,
        5, 192, 120, 40, 7, 196, 14, 1, 224, 128, 16, 128, 16, 144, 102, 15, 55, 255, 145, 0, 4, 0,
        6, 195, 235, 15, 131, 232, 29, 7, 202, 36, 35, 123, 119, 32, 21, 133, 220, 173, 123, 29,
        124, 190, 51, 158, 143, 0, 4, 234, 216, 145, 15, 189, 91, 82, 210, 45, 90, 170, 52, 34, 209,
        158, 13, 108, 213, 78, 158, 137, 255, 145, 0, 4, 0, 7, 192, 56, 56, 15, 132, 112, 35, 164,
        155, 1, 61, 240, 240, 232, 42, 148, 255, 145, 0, 4, 0, 8, 192, 49, 32, 29, 20, 7, 59, 113,
        163, 24, 138, 108, 156, 26, 255, 145, 0, 4, 0, 9, 193, 241, 27, 135, 206, 122, 15, 144, 184,
        25, 25, 211, 9, 237, 209, 173, 196, 150, 111, 25, 246, 238, 110, 167, 245, 97, 24, 144, 213,
        187, 170, 6, 133, 23, 21, 199, 31, 204, 1, 35, 171, 39, 5, 127, 48, 209, 141, 130, 143, 72,
        200, 150, 233, 85, 241, 55, 128, 173, 216, 49, 52, 216, 139, 110, 91, 225, 30, 109, 204,
        188, 146, 157, 214, 18, 87, 32, 89, 157, 101, 246, 187, 223, 117, 50, 62, 81, 65, 205, 126,
        255, 145, 0, 4, 0, 10, 160, 28, 48, 34, 126, 189, 171, 105, 217, 255, 145, 0, 4, 0, 11, 160,
        58, 48, 35, 137, 175, 61, 198, 184, 255, 145, 0, 4, 0, 12, 199, 200, 222, 62, 71, 240, 248,
        106, 128, 111, 222, 255, 137, 22, 12, 202, 78, 23, 233, 116, 114, 125, 113, 100, 226, 16,
        241, 69, 36, 122, 23, 17, 120, 240, 5, 127, 168, 109, 250, 155, 59, 7, 206, 127, 108, 18,
        105, 216, 235, 32, 159, 93, 175, 208, 238, 70, 166, 172, 160, 62, 58, 51, 254, 8, 55, 97,
        246, 138, 129, 137, 16, 33, 165, 205, 22, 186, 92, 163, 108, 70, 25, 168, 130, 96, 162, 13,
        106, 78, 71, 254, 89, 108, 233, 225, 39, 97, 63, 17, 13, 42, 95, 0, 30, 0, 130, 28, 154, 5,
        162, 1, 51, 178, 125, 65, 235, 47, 162, 24, 112, 152, 119, 13, 83, 212, 102, 84, 248, 36,
        193, 63, 193, 101, 254, 213, 80, 59, 106, 79, 74, 170, 227, 110, 2, 204, 201, 182, 60, 114,
        60, 65, 195, 148, 232, 145, 30, 46, 232, 19, 28, 159, 29, 153, 101, 206, 162, 28, 108, 80,
        229, 255, 145, 0, 4, 0, 13, 128, 255, 145, 0, 4, 0, 14, 128, 255, 145, 0, 4, 0, 15, 195,
        224, 188, 135, 193, 127, 15, 134, 196, 158, 62, 204, 245, 173, 53, 224, 68, 102, 215, 173,
        58, 244, 81, 11, 131, 110, 245, 166, 156, 166, 215, 76, 158, 156, 10, 170, 148, 182, 60,
        115, 173, 176, 16, 1, 15, 169, 187, 111, 38, 226, 185, 241, 97, 88, 34, 140, 218, 123, 203,
        88, 112, 88, 143, 74, 108, 17, 106, 37, 69, 149, 69, 151, 215, 37, 209, 201, 125, 81, 117,
        124, 102, 108, 252, 251, 26, 14, 104, 229, 35, 22, 219, 199, 180, 110, 24, 47, 126, 104,
        141, 232, 237, 115, 47, 31, 176, 190, 111, 243, 116, 185, 32, 185, 121, 57, 59, 197, 65, 61,
        233, 98, 18, 172, 235, 82, 146, 150, 241, 30, 186, 172, 161, 155, 148, 171, 212, 237, 170,
        123, 85, 177, 76, 132, 230, 38, 114, 51, 254, 36, 37, 236, 202, 21, 44, 48, 203, 191, 154,
        22, 219, 13, 67, 28, 214, 71, 72, 63, 173, 24, 137, 62, 141, 14, 123, 11, 237, 106, 219, 68,
        40, 62, 29, 255, 145, 0, 4, 0, 16, 128, 255, 145, 0, 4, 0, 17, 128, 255, 217, 235, 89, 152,
        53, 59, 33, 186, 193, 56, 29, 117, 14, 31, 162, 102, 65, 224, 150, 175, 57, 29, 17, 95, 173,
        173, 212, 123, 244, 250, 47, 255, 139, 96, 54, 34, 219, 243, 92, 100, 240, 182, 255, 21,
        167, 91, 244, 127, 53, 165, 180, 223, 131, 221, 184, 74, 53, 233, 255, 238, 30, 166, 5, 157,
        243, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 35, 136,
    ];
    let msg_str = "86502555125550545755504850524855495649505253535551565525583117109105116327511710997114255484945484945495756522557725567477932731151041199711432671049711010025569971151163268101108104105255255664551494432511141003270108111111114255255494948485349255751141051151041109732789710397114255681011081041052558297100104101121328310412197109328097114107326912011610111011510511111025571971101001041053278971039711425575114105115104110973278971039711425549505152255255792558104700000600006000000000000600006000000000037117117112558201220011544002559203566111241102341102341101881030103010222695769576951007237237269792107921079972551000340167114101971161011003298121583274745048484832118101114115105111110325246492551440100000223601255820122001154400255147255145040019523554111283816625514504011922496512816124552551450402192249650141752551450403195238413123741312328156122712814782441981019012874255145040419230103229702406415157125620616124255145040519212040719614122412816128161441021555255145040619523515131232297202363512311932211332201731232912419051158143042342161451518991822104590170523420915813108213781581372551450407192565615132112351641551612402402324214825514504081924932292075911316324138108156262551450409193241271352061221514418425252119237209173196150111252462381101672459724144213187170613323211993120413517139512748209141130143722001502338524155128173216495221613911091225301092041881461572141887328915710124618722311750628165205126255145040101602848341261891711052172551450401116058483513717561198184255145040121992002226271240248106128111222255137221220278232331161141251131002261624169361222317120240512716810925015559720612710818105216235321599317520823870166172160625851254855972461381291371633165205221869216310870251681309616213106787125489108233225399763171342950300130281545162151178125652354716224112152119138321210284248361936319310125421380591067974170227110220420118260114606519514823214530462321928159291531012061622810880229255145040131282551450401412825514504015195224188135193127151341961586220424517353224681022151735824481111311102451661561662157615815610170148182601151731761611516918711138226185241978834140218123203881128814374108171063769149691512153720920112581117124102108252251261410422935222191991801102447126104141232237115473117619011124311618532185121575919765612339818172235821461502413018617216115514817121223717012385177761322303811451254363723620221444820319115422219136728214717263173241376214114123112371062196840622925514504016128255145040171282552172358915253593318619356291171431162102652241501755729179517317321212324425047255139965434219243921002401822552116791244127531651802231312211847453233255238301665157243";

    let delimiterIndices: [u64; 18] =
        [2, 4, 26, 38, 49, 51, 68, 79, 80, 96, 97, 104, 118, 124, 152, 165, 179, 184];
    extractor_circuit(
        msg,
        msg_str,
        signature_limbs,
        modulus_limbs,
        redc_limbs,
        delimiterIndices,
    );
}
