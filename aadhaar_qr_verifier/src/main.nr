use dep::poseidon::bn254;
use dep::bignum::BigNum;
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::runtime_bignum::BigNumTrait;
use dep::bignum::runtime_bignum::BigNumInstanceTrait;
use dep::bignum::runtime_bignum::BigNumParamsTrait;
use dep::bignum::utils::u60_representation::U60Repr;
use dep::bignum::utils::arrayX::ArrayX;
use dep::bignum::fields::Params2048;
use dep::bignum::fields::Params1024;

type BN1024 = BigNum<9, Params1024>;
type BN2048 = BigNum<18, Params2048>;
type BNInst1024 = BigNumInstance<9, Params1024>;
type BNInst2048 = BigNumInstance<18, Params2048>;

type RSA1024 = RSA<BN1024, BNInst1024, 128>;
type RSA2048 = RSA<BN2048, BNInst2048, 256>;

// Define a struct to hold the extracted QR data
struct QRData {
    ageAbove18: Field,
    gender: Field,
    pinCode: Field,
    state: Field,
}

struct RSA<BN, BNInstance, let NumBytes: u32>{}

// Position/order (not index) of fields in the data
fn reference_id_position() -> u64 {
    2
}

fn name_position() -> u64 {
    3
}

fn dob_position() -> u64 {
    4
}

fn gender_position() -> u64 {
    5
}

fn pincode_position() -> u64 {
    11
}

fn state_position() -> u64 {
    13
}

fn photo_position() -> u64 {
    18
}

// Maximum byte size for each field
fn max_field_byte_size() -> u64 {
    31
}

// Number of int chunks to pack the photo
// Photo can only be of max 32 * 31 bytes (pack_size * max_field_byte_size)
fn photo_pack_size() -> u64 {
    32
}

/**
 * @brief Compare a recovered byte hash from an RSA signature to the original message hash
 * @details Taken from https://github.com/richardliang/noir-rsa
 **/
fn compare_signature_sha256<let N: u32>(padded_sha256_hash: [u8; N], msg_hash: [u8; 32]) -> bool {
    // Get length of sig (e.g. 1048 = 128 bytes, 2048 = 256 bytes)
    // NOTE: Assume MAX_BYTES < 2^32 bit number. MAX_BYTES of 259 > 2^8 bits so need to cast it to u32

    for i in 0..32 {
        // Padded hash is reversed
        assert(padded_sha256_hash[31 - i] == msg_hash[i]);
    }

    let hash_prefix: [u8; 19] = [32, 4, 0, 5, 1, 2, 4, 3, 101, 1, 72, 134, 96, 9, 6, 13, 48, 49, 48];

    for i in 32..51 {
        assert(hash_prefix[i - 32] == padded_sha256_hash[i]);
    }

    assert(padded_sha256_hash[51] == 0);

    // Sub 32 bytes for hash, 19 bytes for prefix, 1 byte for 0, 1 byte for 1, 1 byte for 0
    let ps_len = N - 54;
    for i in 52..N {
        if i as u32 < 52 + ps_len as u32 {
            // PS padding which depends on RSA modulus / sig length. 1024 bits = 128 bytes = 128 - 54 = 74 bytes of 0xFF padding
            assert(padded_sha256_hash[i] == 255);
        } else if i as u32 == 52 + ps_len as u32 {
            // Pad 0x01
            assert(padded_sha256_hash[i] == 1);
        } else if i as u32 == 53 + ps_len as u32 {
            // 0x00
            assert(padded_sha256_hash[i] == 0);
        } else {
            // Padded with 0 until MAX_BYTES
            assert(padded_sha256_hash[i] == 0);
        }
    }

    true
}
impl<BN, BNInstance, let NumBytes: u32> RSA<BN, BNInstance, NumBytes>  where BN: BigNumTrait, BNInstance: BigNumInstanceTrait<BN> {
    /**
 * @brief Verify an RSA signature generated via the pkcs1v15 signature scheme.
 * @details The fourth function parameter is required to define the value of `NBytes`
 *          when converting a BigNum into a byte array, the number of bytes is required and currently cannot be inferred.
 *          Once numeric generics can be derived by applying operations to other numeric generics the need for this will go away.
 *
 * @note We assume the public key exponent `e` is 65537 
 * Rough cost: 2,048 bit RSA: 26,888 gates per verification
 *             1,024 bit RSA: 11,983 gates per verification
 * A circuit that verifies 1 signature (and does nothing else) will cost ~32k due to initialization costs of lookup tables
 **/
    pub fn verify_sha256_pkcs1v15(_: Self, public_key: BNInstance, msg_hash: [u8; 32], sig: BN) -> bool {
        // e = 65537 = 1 0000 0000 0000 0001
        let mut exponentiated = public_key.mul(sig, sig);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, sig);

        let mut padded_sha256_hash_bytes: [u8; NumBytes] = exponentiated.to_le_bytes();
        compare_signature_sha256(padded_sha256_hash_bytes, msg_hash)
    }
}

fn cds_circuit(
    revealAgeAbove18: Field,
    revealGender: Field,
    revealPinCode: Field,
    revealState: Field,
    qrDataExtractor: QRData,
    ageAbove18: Field,
    gender: Field,
    pinCode: Field,
    state: Field
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
    includeSeconds: bool
) -> Field {
    // Ensure the input values are within valid ranges by casting to integers
    //assert(year as i32 >= 1970);
    assert(year as i32 <= maxYears as i32);
    //assert(month as i32 >= 1);
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
    let first16Hash = bn254::hash_16(first16);

    // Hash the last 16 elements of the photo
    let last16Hash = bn254::hash_16(last16);

    // Compute the final nullifier
    let out = bn254::hash_3([nullifierSeed, first16Hash, last16Hash]);

    out as Field
}

fn signal_circuit(signalHash: Field, signalHashSquare: Field) {
    // Enforce the constraint that signalHashSquare is the square of signalHash
    assert(signalHashSquare == signalHash * signalHash);
}

fn extractor_circuit(
    msg: [Field; 1137],
    msg_str: str<2663>,
    public_key: BNInst2048,
    signature: BigNum<18, Params2048>,
    delimiterIndices: [u64; 18]
) {
    let sha256_hash: [u8; 32] = dep::std::hash::sha256(msg_str.as_bytes());
    let rsa: RSA2048 = RSA {};
    assert(rsa.verify_sha256_pkcs1v15(public_key, sha256_hash, signature));

    // timestamp extraction
    let mut year: [Field; 4] = [0; 4];
    let mut month: [Field; 2] = [0; 2];
    let mut day: [Field; 2] = [0; 2];
    let mut hour: [Field; 2] = [0; 2];

    let year_start_index = delimiterIndices[reference_id_position() - 1] + 5;
    let year_end_index = year_start_index + 3;
    let month_start_index = year_end_index + 1;
    let month_end_index = month_start_index + 1;
    let day_start_index = month_end_index + 1;
    let day_end_index = day_start_index + 1;
    let hour_start_index = day_end_index + 1;
    let hour_end_index = hour_start_index + 1;

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
            birth_date_vec[i-birth_date_start_index] = msg[i] - 48;
        } else if i >= birth_month_start_index & i <= birth_month_end_index {
            birth_month_vec[i-birth_month_start_index] = msg[i] - 48;
        } else if i >= birth_year_start_index & i <= birth_year_end_index {
            birth_year_vec[i-birth_date_start_index] = msg[i] - 48;
        }
    }

    let birth_date_data = birth_date_vec[0] * 10 + birth_date_vec[1];
    let birth_month_data = birth_month_vec[0] * 10 + birth_month_vec[1];
    let birth_year_data = birth_year_vec[0] * 1000 + birth_year_vec[1] * 100 + birth_year_vec[2] * 10 + birth_year_vec[3];

    let age_by_year = year_val - birth_year_data - 1;
    let mut age = age_by_year;
    if birth_month_data as u64 > month_val as u64 {
        age += 1;
    } else if birth_month_data as u64 == month_val as u64 {
        if birth_date_data as u64 > day_val as u64 {
            age += 1;
        }
    }

    let gender_index = delimiterIndices[gender_position() - 1] + 1;
    let gender_data = msg[gender_index] - 65;

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

    let state_start_index = delimiterIndices[state_position() - 1] + 1;
    let state_end_index = delimiterIndices[state_position()];

    let mut state_vec: [Field; 5] = [0; 5];
    let mut state_data = 0;

    for i in state_start_index..state_end_index {
        state_vec[i - state_start_index] = msg[i] - 65;
        state_data = state_data * 10 + state_vec[i - state_start_index];
    }

    // Define a valid QRData instance
    let qrDataExtractor = QRData { ageAbove18: age, gender: gender_data, pinCode: pincode_data, state: state_data };

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
        state
    );

    let nullifierSeed: Field = 12345678; // Example seed
    let mut photo_vec: [Field; 952] = [0; 952];
    let photo_start_index = delimiterIndices[photo_position() - 1] + 1;
    let photo_end_index = 1137;
    for i in photo_start_index..photo_end_index {
        photo_vec[i - photo_start_index] = msg[i] - 48;
    }
    let mut photo: [Field; 32] = [0; 32];
    for i in 0..32 {
        photo[i] = photo_vec[i];
    }
    let expectedNullifier = nullifier_circuit(nullifierSeed, photo);
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
        includeSeconds
    );

    assert(timestamp != 0, "Non-zero timestamp computed: {timestamp}");
    std::print("Timestamp computed: ");
    std::println(timestamp);

    // Define a valid signalHash and its square
    let signalHash = 5;
    let signalHashSquare = 25;
    // Call the circuit with valid inputs
    signal_circuit(signalHash, signalHashSquare);
}

#[test]
fn main() {
    let msg = [
        86, 50, 255, 51, 255, 50, 54, 57, 55, 50, 48, 50, 52, 48, 55, 49, 56, 49, 50, 52, 53, 53, 55, 51, 56, 55, 255, 83, 117, 109, 105, 116, 32, 75, 117, 109, 97, 114, 255, 48, 49, 45, 48, 49, 45, 49, 57, 56, 52, 255, 77, 255, 67, 47, 79, 32, 73, 115, 104, 119, 97, 114, 32, 67, 104, 97, 110, 100, 255, 69, 97, 115, 116, 32, 68, 101, 108, 104, 105, 255, 255, 66, 45, 51, 49, 44, 32, 51, 114, 100, 32, 70, 108, 111, 111, 114, 255, 255, 49, 49, 48, 48, 53, 49, 255, 75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 68, 101, 108, 104, 105, 255, 82, 97, 100, 104, 101, 121, 32, 83, 104, 121, 97, 109, 32, 80, 97, 114, 107, 32, 69, 120, 116, 101, 110, 115, 105, 111, 110, 255, 71, 97, 110, 100, 104, 105, 32, 78, 97, 103, 97, 114, 255, 75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 49, 50, 51, 52, 255, 255, 79, 255, 81, 0, 47, 0, 0, 0, 0, 0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 7, 1, 1, 7, 1, 1, 7, 1, 1, 255, 82, 0, 12, 2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 92, 0, 35, 66, 111, 24, 110, 234, 110, 234, 110, 188, 103, 0, 103, 0, 102, 226, 95, 76, 95, 76, 95, 100, 72, 3, 72, 3, 72, 69, 79, 210, 79, 210, 79, 97, 255, 100, 0, 34, 0, 1, 67, 114, 101, 97, 116, 101, 100, 32, 98, 121, 58, 32, 74, 74, 50, 48, 48, 48, 32, 118, 101, 114, 115, 105, 111, 110, 32, 52, 46, 49, 255, 144, 0, 10, 0, 0, 0, 0, 2, 236, 0, 1, 255, 82, 0, 12, 2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 147, 255, 145, 0, 4, 0, 0, 195, 235, 5, 4, 11, 128, 38, 166, 255, 145, 0, 4, 0, 1, 192, 249, 65, 128, 16, 124, 55, 255, 145, 0, 4, 0, 2, 192, 249, 65, 0, 14, 175, 255, 145, 0, 4, 0, 3, 195, 238, 4, 131, 237, 4, 131, 232, 8, 15, 61, 227, 128, 14, 78, 244, 198, 10, 190, 128, 74, 255, 145, 0, 4, 0, 4, 192, 30, 10, 3, 229, 7, 0, 240, 64, 15, 157, 12, 56, 206, 16, 124, 255, 145, 0, 4, 0, 5, 192, 120, 40, 7, 196, 14, 1, 224, 128, 16, 128, 16, 144, 102, 15, 55, 255, 145, 0, 4, 0, 6, 195, 235, 15, 131, 232, 29, 7, 202, 36, 35, 123, 119, 32, 21, 133, 220, 173, 123, 29, 124, 190, 51, 158, 143, 0, 4, 234, 216, 145, 15, 189, 91, 82, 210, 45, 90, 170, 52, 34, 209, 158, 13, 108, 213, 78, 158, 137, 255, 145, 0, 4, 0, 7, 192, 56, 56, 15, 132, 112, 35, 164, 155, 1, 61, 240, 240, 232, 42, 148, 255, 145, 0, 4, 0, 8, 192, 49, 32, 29, 20, 7, 59, 113, 163, 24, 138, 108, 156, 26, 255, 145, 0, 4, 0, 9, 193, 241, 27, 135, 206, 122, 15, 144, 184, 25, 25, 211, 9, 237, 209, 173, 196, 150, 111, 25, 246, 238, 110, 167, 245, 97, 24, 144, 213, 187, 170, 6, 133, 23, 21, 199, 31, 204, 1, 35, 171, 39, 5, 127, 48, 209, 141, 130, 143, 72, 200, 150, 233, 85, 241, 55, 128, 173, 216, 49, 52, 216, 139, 110, 91, 225, 30, 109, 204, 188, 146, 157, 214, 18, 87, 32, 89, 157, 101, 246, 187, 223, 117, 50, 62, 81, 65, 205, 126, 255, 145, 0, 4, 0, 10, 160, 28, 48, 34, 126, 189, 171, 105, 217, 255, 145, 0, 4, 0, 11, 160, 58, 48, 35, 137, 175, 61, 198, 184, 255, 145, 0, 4, 0, 12, 199, 200, 222, 62, 71, 240, 248, 106, 128, 111, 222, 255, 137, 22, 12, 202, 78, 23, 233, 116, 114, 125, 113, 100, 226, 16, 241, 69, 36, 122, 23, 17, 120, 240, 5, 127, 168, 109, 250, 155, 59, 7, 206, 127, 108, 18, 105, 216, 235, 32, 159, 93, 175, 208, 238, 70, 166, 172, 160, 62, 58, 51, 254, 8, 55, 97, 246, 138, 129, 137, 16, 33, 165, 205, 22, 186, 92, 163, 108, 70, 25, 168, 130, 96, 162, 13, 106, 78, 71, 254, 89, 108, 233, 225, 39, 97, 63, 17, 13, 42, 95, 0, 30, 0, 130, 28, 154, 5, 162, 1, 51, 178, 125, 65, 235, 47, 162, 24, 112, 152, 119, 13, 83, 212, 102, 84, 248, 36, 193, 63, 193, 101, 254, 213, 80, 59, 106, 79, 74, 170, 227, 110, 2, 204, 201, 182, 60, 114, 60, 65, 195, 148, 232, 145, 30, 46, 232, 19, 28, 159, 29, 153, 101, 206, 162, 28, 108, 80, 229, 255, 145, 0, 4, 0, 13, 128, 255, 145, 0, 4, 0, 14, 128, 255, 145, 0, 4, 0, 15, 195, 224, 188, 135, 193, 127, 15, 134, 196, 158, 62, 204, 245, 173, 53, 224, 68, 102, 215, 173, 58, 244, 81, 11, 131, 110, 245, 166, 156, 166, 215, 76, 158, 156, 10, 170, 148, 182, 60, 115, 173, 176, 16, 1, 15, 169, 187, 111, 38, 226, 185, 241, 97, 88, 34, 140, 218, 123, 203, 88, 112, 88, 143, 74, 108, 17, 106, 37, 69, 149, 69, 151, 215, 37, 209, 201, 125, 81, 117, 124, 102, 108, 252, 251, 26, 14, 104, 229, 35, 22, 219, 199, 180, 110, 24, 47, 126, 104, 141, 232, 237, 115, 47, 31, 176, 190, 111, 243, 116, 185, 32, 185, 121, 57, 59, 197, 65, 61, 233, 98, 18, 172, 235, 82, 146, 150, 241, 30, 186, 172, 161, 155, 148, 171, 212, 237, 170, 123, 85, 177, 76, 132, 230, 38, 114, 51, 254, 36, 37, 236, 202, 21, 44, 48, 203, 191, 154, 22, 219, 13, 67, 28, 214, 71, 72, 63, 173, 24, 137, 62, 141, 14, 123, 11, 237, 106, 219, 68, 40, 62, 29, 255, 145, 0, 4, 0, 16, 128, 255, 145, 0, 4, 0, 17, 128, 255, 217, 235, 89, 152, 53, 59, 33, 186, 193, 56, 29, 117, 14, 31, 162, 102, 65, 224, 150, 175, 57, 29, 17, 95, 173, 173, 212, 123, 244, 250, 47, 255, 139, 96, 54, 34, 219, 243, 92, 100, 240, 182, 255, 21, 167, 91, 244, 127, 53, 165, 180, 223, 131, 221, 184, 74, 53, 233, 255, 238, 30, 166, 5, 157, 243
    ];
    let msg_str = "86502555125550545755504850524855495649505253535551565525583117109105116327511710997114255484945484945495756522557725567477932731151041199711432671049711010025569971151163268101108104105255255664551494432511141003270108111111114255255494948485349255751141051151041109732789710397114255681011081041052558297100104101121328310412197109328097114107326912011610111011510511111025571971101001041053278971039711425575114105115104110973278971039711425549505152255255792558104700000600006000000000000600006000000000037117117112558201220011544002559203566111241102341102341101881030103010222695769576951007237237269792107921079972551000340167114101971161011003298121583274745048484832118101114115105111110325246492551440100000223601255820122001154400255147255145040019523554111283816625514504011922496512816124552551450402192249650141752551450403195238413123741312328156122712814782441981019012874255145040419230103229702406415157125620616124255145040519212040719614122412816128161441021555255145040619523515131232297202363512311932211332201731232912419051158143042342161451518991822104590170523420915813108213781581372551450407192565615132112351641551612402402324214825514504081924932292075911316324138108156262551450409193241271352061221514418425252119237209173196150111252462381101672459724144213187170613323211993120413517139512748209141130143722001502338524155128173216495221613911091225301092041881461572141887328915710124618722311750628165205126255145040101602848341261891711052172551450401116058483513717561198184255145040121992002226271240248106128111222255137221220278232331161141251131002261624169361222317120240512716810925015559720612710818105216235321599317520823870166172160625851254855972461381291371633165205221869216310870251681309616213106787125489108233225399763171342950300130281545162151178125652354716224112152119138321210284248361936319310125421380591067974170227110220420118260114606519514823214530462321928159291531012061622810880229255145040131282551450401412825514504015195224188135193127151341961586220424517353224681022151735824481111311102451661561662157615815610170148182601151731761611516918711138226185241978834140218123203881128814374108171063769149691512153720920112581117124102108252251261410422935222191991801102447126104141232237115473117619011124311618532185121575919765612339818172235821461502413018617216115514817121223717012385177761322303811451254363723620221444820319115422219136728214717263173241376214114123112371062196840622925514504016128255145040171282552172358915253593318619356291171431162102652241501755729179517317321212324425047255139965434219243921002401822552116791244127531651802231312211847453233255238301665157243";
    let public_key: BNInst2048 = BigNumInstance::new(
        [
        0x2b465b3fb690242e1235c670dcfb25, 0x640a8933d7daca84a4acef904154b4, 0x62edbfe63e266a5bd8b709e161c8ad, 0x67e5fca1ee7abce8c55e2af10e3c88, 0x47e169541fbcad1db03cdb3bb6ddb4, 0xb2010527709bcd13954404f47e63cb, 0xa2da280f98291de2db2eea3b1198db, 0x5379b351c475a2661b5e51073e019c, 0x204877f0a93bb50a5ae94d2e9cd04a, 0xf23d4f80b1b93f53797ccfa2121e84, 0x5ad9d98cb0522f897f860a3394fec4, 0x9d88eb75090dbe760e4113ef7c3a4e, 0xaf43185f371a0a183ab9bdfc89f17a, 0x06f9b343e7418c83f7f2adafa38505, 0xbb8c5f0c296bcf5ba749849934cb20, 0x0ecf5c0b916c7a8cc5f7b3ff3e6802, 0xe32855596c16ad483cfd9b3aba4ca9, 0xc8
    ],
        [
        0xad8f34cd345f30e43b259e4158a38e, 0xa9c21f74a74d8ab1f31e4ed62d77c2, 0x04a05a51292d7851b2e36ebf922f6c, 0xc265cfa84ce216bf0285d1a89de99c, 0xd1b75109da5df9816fd8de2dfbccf0, 0xf97a0cfb88274326c09889d02cf16e, 0x9c4e239737d77db8987c3b61d835b4, 0xcd1b11e167a6f227a434d62ed67287, 0x0155d9e93e23c5a91615d3d6eae3a8, 0xc89834a0ba80e9cb7d2786ea17aebb, 0xfaaafdb930a62b8d148b94ac6c5979, 0xc31dc3dd65743e58a8ba68277e259b, 0x83fb6ef8085ad3111835fd7ff0662d, 0xe7a5d6ea604882d638bc750fbb3a51, 0xd3ede61d4490ec2e19ffe560a1c0ee, 0xd8e7de313b7c321381b0cead3bfe57, 0x3b8c8aa30c5a7108f1d689de8eb837, 0x0146
    ]
    );
    let signature: BigNum<18, Params2048> = BigNum::from_array(
        [
        0x05c6e0981bbc3b57a3a1fced4d17da, 0xc91eb859d2829b53dc4e498135fff1, 0xcfaaf3614931fbd153dd4178298723, 0xeba33602ef3c36f2ac342a07998b04, 0x0b8f5b19985490400aaf8f203906dd, 0x34ec83e9af254e6bd9024b1275e44b, 0xcb0710065948ca3e4fc5ca85676716, 0xbc2d33b6c7a4f9cf6c46d5e63b6a40, 0x3a543d690a16366a4a46b88720c944, 0x42479ca91ed769178b4a5a17c139b7, 0x71f39517ba6eaa91d035d690265e8d, 0x235ff0a16468b337f77a9b75d1bb9a, 0x03b4a44f63c446c9d945b8f7febf52, 0xc24de09a1a355f94fe46346b7830bb, 0xcc49c7bbe646f78197054169e0787e, 0xad7871ecf1ab2d0956aa7cdfd7dd1b, 0x46b8fd8d0c49f1ce2eef7e4f817ff3, 0xbd
    ]
    );
    let delimiterIndices: [u64; 18] = [2, 4, 26, 38, 49, 51, 68, 79, 80, 96, 97, 104, 118, 124, 152, 165, 179, 184];
    extractor_circuit(msg, msg_str, public_key, signature, delimiterIndices);
}
