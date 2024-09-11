// Define a struct to hold the extracted QR data
struct QRData {
    ageAbove18: Field,
    gender: Field,
    pinCode: Field,
    state: Field,
}

fn main(
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

#[test]
fn test_valid_reveal_constraints() {
    // Define a valid QRData instance
    let qrDataExtractor = QRData { ageAbove18: 1, gender: 1, pinCode: 12345, state: 42 };

    // Test with reveal signals set to 1 (reveal the data)
    let revealAgeAbove18 = 1;
    let revealGender = 1;
    let revealPinCode = 1;
    let revealState = 1;

    // Expected values match qrDataExtractor values
    let ageAbove18 = 1;
    let gender = 1;
    let pinCode = 12345;
    let state = 42;

    // Call the circuit with valid inputs
    main(
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
}

#[test]
fn test_valid_reveal_constraints_with_data() {
    let msg = [
        86, 50, 255, 51, 255, 50, 54, 57, 55, 50, 48, 50, 52, 48, 55, 49, 56, 49, 50, 52, 53, 53, 55, 51, 56, 55, 255, 83, 117, 109, 105, 116, 32, 75, 117, 109, 97, 114, 255, 48, 49, 45, 48, 49, 45, 49, 57, 56, 52, 255, 77, 255, 67, 47, 79, 32, 73, 115, 104, 119, 97, 114, 32, 67, 104, 97, 110, 100, 255, 69, 97, 115, 116, 32, 68, 101, 108, 104, 105, 255, 255, 66, 45, 51, 49, 44, 32, 51, 114, 100, 32, 70, 108, 111, 111, 114, 255, 255, 49, 49, 48, 48, 53, 49, 255, 75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 68, 101, 108, 104, 105, 255, 82, 97, 100, 104, 101, 121, 32, 83, 104, 121, 97, 109, 32, 80, 97, 114, 107, 32, 69, 120, 116, 101, 110, 115, 105, 111, 110, 255, 71, 97, 110, 100, 104, 105, 32, 78, 97, 103, 97, 114, 255, 75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 49, 50, 51, 52, 255, 255, 79, 255, 81, 0, 47, 0, 0, 0, 0, 0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 7, 1, 1, 7, 1, 1, 7, 1, 1, 255, 82, 0, 12, 2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 92, 0, 35, 66, 111, 24, 110, 234, 110, 234, 110, 188, 103, 0, 103, 0, 102, 226, 95, 76, 95, 76, 95, 100, 72, 3, 72, 3, 72, 69, 79, 210, 79, 210, 79, 97, 255, 100, 0, 34, 0, 1, 67, 114, 101, 97, 116, 101, 100, 32, 98, 121, 58, 32, 74, 74, 50, 48, 48, 48, 32, 118, 101, 114, 115, 105, 111, 110, 32, 52, 46, 49, 255, 144, 0, 10, 0, 0, 0, 0, 2, 236, 0, 1, 255, 82, 0, 12, 2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 147, 255, 145, 0, 4, 0, 0, 195, 235, 5, 4, 11, 128, 38, 166, 255, 145, 0, 4, 0, 1, 192, 249, 65, 128, 16, 124, 55, 255, 145, 0, 4, 0, 2, 192, 249, 65, 0, 14, 175, 255, 145, 0, 4, 0, 3, 195, 238, 4, 131, 237, 4, 131, 232, 8, 15, 61, 227, 128, 14, 78, 244, 198, 10, 190, 128, 74, 255, 145, 0, 4, 0, 4, 192, 30, 10, 3, 229, 7, 0, 240, 64, 15, 157, 12, 56, 206, 16, 124, 255, 145, 0, 4, 0, 5, 192, 120, 40, 7, 196, 14, 1, 224, 128, 16, 128, 16, 144, 102, 15, 55, 255, 145, 0, 4, 0, 6, 195, 235, 15, 131, 232, 29, 7, 202, 36, 35, 123, 119, 32, 21, 133, 220, 173, 123, 29, 124, 190, 51, 158, 143, 0, 4, 234, 216, 145, 15, 189, 91, 82, 210, 45, 90, 170, 52, 34, 209, 158, 13, 108, 213, 78, 158, 137, 255, 145, 0, 4, 0, 7, 192, 56, 56, 15, 132, 112, 35, 164, 155, 1, 61, 240, 240, 232, 42, 148, 255, 145, 0, 4, 0, 8, 192, 49, 32, 29, 20, 7, 59, 113, 163, 24, 138, 108, 156, 26, 255, 145, 0, 4, 0, 9, 193, 241, 27, 135, 206, 122, 15, 144, 184, 25, 25, 211, 9, 237, 209, 173, 196, 150, 111, 25, 246, 238, 110, 167, 245, 97, 24, 144, 213, 187, 170, 6, 133, 23, 21, 199, 31, 204, 1, 35, 171, 39, 5, 127, 48, 209, 141, 130, 143, 72, 200, 150, 233, 85, 241, 55, 128, 173, 216, 49, 52, 216, 139, 110, 91, 225, 30, 109, 204, 188, 146, 157, 214, 18, 87, 32, 89, 157, 101, 246, 187, 223, 117, 50, 62, 81, 65, 205, 126, 255, 145, 0, 4, 0, 10, 160, 28, 48, 34, 126, 189, 171, 105, 217, 255, 145, 0, 4, 0, 11, 160, 58, 48, 35, 137, 175, 61, 198, 184, 255, 145, 0, 4, 0, 12, 199, 200, 222, 62, 71, 240, 248, 106, 128, 111, 222, 255, 137, 22, 12, 202, 78, 23, 233, 116, 114, 125, 113, 100, 226, 16, 241, 69, 36, 122, 23, 17, 120, 240, 5, 127, 168, 109, 250, 155, 59, 7, 206, 127, 108, 18, 105, 216, 235, 32, 159, 93, 175, 208, 238, 70, 166, 172, 160, 62, 58, 51, 254, 8, 55, 97, 246, 138, 129, 137, 16, 33, 165, 205, 22, 186, 92, 163, 108, 70, 25, 168, 130, 96, 162, 13, 106, 78, 71, 254, 89, 108, 233, 225, 39, 97, 63, 17, 13, 42, 95, 0, 30, 0, 130, 28, 154, 5, 162, 1, 51, 178, 125, 65, 235, 47, 162, 24, 112, 152, 119, 13, 83, 212, 102, 84, 248, 36, 193, 63, 193, 101, 254, 213, 80, 59, 106, 79, 74, 170, 227, 110, 2, 204, 201, 182, 60, 114, 60, 65, 195, 148, 232, 145, 30, 46, 232, 19, 28, 159, 29, 153, 101, 206, 162, 28, 108, 80, 229, 255, 145, 0, 4, 0, 13, 128, 255, 145, 0, 4, 0, 14, 128, 255, 145, 0, 4, 0, 15, 195, 224, 188, 135, 193, 127, 15, 134, 196, 158, 62, 204, 245, 173, 53, 224, 68, 102, 215, 173, 58, 244, 81, 11, 131, 110, 245, 166, 156, 166, 215, 76, 158, 156, 10, 170, 148, 182, 60, 115, 173, 176, 16, 1, 15, 169, 187, 111, 38, 226, 185, 241, 97, 88, 34, 140, 218, 123, 203, 88, 112, 88, 143, 74, 108, 17, 106, 37, 69, 149, 69, 151, 215, 37, 209, 201, 125, 81, 117, 124, 102, 108, 252, 251, 26, 14, 104, 229, 35, 22, 219, 199, 180, 110, 24, 47, 126, 104, 141, 232, 237, 115, 47, 31, 176, 190, 111, 243, 116, 185, 32, 185, 121, 57, 59, 197, 65, 61, 233, 98, 18, 172, 235, 82, 146, 150, 241, 30, 186, 172, 161, 155, 148, 171, 212, 237, 170, 123, 85, 177, 76, 132, 230, 38, 114, 51, 254, 36, 37, 236, 202, 21, 44, 48, 203, 191, 154, 22, 219, 13, 67, 28, 214, 71, 72, 63, 173, 24, 137, 62, 141, 14, 123, 11, 237, 106, 219, 68, 40, 62, 29, 255, 145, 0, 4, 0, 16, 128, 255, 145, 0, 4, 0, 17, 128, 255, 217, 235, 89, 152, 53, 59, 33, 186, 193, 56, 29, 117, 14, 31, 162, 102, 65, 224, 150, 175, 57, 29, 17, 95, 173, 173, 212, 123, 244, 250, 47, 255, 139, 96, 54, 34, 219, 243, 92, 100, 240, 182, 255, 21, 167, 91, 244, 127, 53, 165, 180, 223, 131, 221, 184, 74, 53, 233, 255, 238, 30, 166, 5, 157, 243
    ];
    let mut birth_year_vec: [Field; 4] = [0; 4];
    let mut birth_month_vec: [Field; 2] = [0; 2];
    let mut birth_date_vec: [Field; 2] = [0; 2];
    let year_data = 2024;
    let month_data = 8;
    let day_data = 7;
    let mut age = 0;

    // Calculate the full birthday consisting of the birth_day, birth_month, and birth_year
    for i in 39..49 {
        if i >= 39 & i <= 40 {
            birth_date_vec[i-39] = msg[i] - 48;
        } else if i >= 42 & i <= 43 {
            birth_month_vec[i-42] = msg[i] - 48;
        } else if i >= 45 & i <= 48 {
            birth_year_vec[i-45] = msg[i] - 48;
        }
    }

    let birth_date_data = birth_date_vec[0] * 10 + birth_date_vec[1];
    let birth_month_data = birth_month_vec[0] * 10 + birth_month_vec[1];
    let birth_year_data = birth_year_vec[0] * 1000 + birth_year_vec[1] * 100 + birth_year_vec[2] * 10 + birth_year_vec[3];

    // Calculate the Age
    let age_by_year = year_data - birth_year_data - 1;
    let mut age = age_by_year;
    if birth_month_data as u64 > month_data {
        age += 1;
    } else if birth_month_data as u64 == month_data {
        if birth_date_data as u64 > day_data {
            age += 1;
        }
    }

    // Calculate the Gender
    let gender_data = msg[50] - 65;

    // Calculate the Pincode of the address
    let mut pincode_vec: [Field; 6] = [0; 6];
    for i in 98..104 {
        pincode_vec[i-98] = msg[i] - 48;
    }

    let mut pincode_data = 0;
    for i in pincode_vec {
        pincode_data = pincode_data * 10 + i;
    }

    // Calculate the State of the address
    let mut state_vec: [Field; 5] = [0; 5];
    let mut state_data = 0;
    for i in 119..124 {
        state_vec[i-119] = msg[50] - 65;
        state_data = state_data * 10 + state_vec[i-119];
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
    main(
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
}
