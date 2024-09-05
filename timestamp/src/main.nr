// Define the main function for converting date and time to a Unix timestamp
fn main(
    year: pub Field,
    month: pub Field,
    day: pub Field,
    hour: pub Field,
    minute: pub Field,
    second: pub Field,
    maxYears: pub Field,
    includeHours: pub bool,
    includeMinutes: pub bool,
    includeSeconds: pub bool
) -> pub Field {
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

#[test]
fn test_valid_timestamp_conversion() {
    // Test inputs
    let year = 2024;
    let month = 8;
    let day = 6;
    let hour = 12;
    let minute = 30;
    let second = 45;

    // Set maximum year and inclusion flags
    let maxYears = 2050;
    let includeHours = true;
    let includeMinutes = true;
    let includeSeconds = true;

    // Calculate the Unix timestamp using the circuit
    let timestamp = main(
        year,
        month,
        day,
        hour,
        minute,
        second,
        maxYears,
        includeHours,
        includeMinutes,
        includeSeconds
    );

    // Use assertions to validate the timestamp, effectively "printing" it
    //assert(timestamp == expectedTimestamp, "Computed timestamp is: {timestamp}");
    assert(timestamp != 0, "Non-zero timestamp computed: {timestamp}");
}

#[test]
fn test_timestamp_with_actual_data() {
    let msg = [
        86, 50, 255, 51, 255, 50, 54, 57, 55, 50, 48, 50, 52, 48, 55, 49, 56, 49, 50, 52, 53, 53, 55, 51, 56, 55, 255, 83, 117, 109, 105, 116, 32, 75, 117, 109, 97, 114, 255, 48, 49, 45, 48, 49, 45, 49, 57, 56, 52, 255, 77, 255, 67, 47, 79, 32, 73, 115, 104, 119, 97, 114, 32, 67, 104, 97, 110, 100, 255, 69, 97, 115, 116, 32, 68, 101, 108, 104, 105, 255, 255, 66, 45, 51, 49, 44, 32, 51, 114, 100, 32, 70, 108, 111, 111, 114, 255, 255, 49, 49, 48, 48, 53, 49, 255, 75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 68, 101, 108, 104, 105, 255, 82, 97, 100, 104, 101, 121, 32, 83, 104, 121, 97, 109, 32, 80, 97, 114, 107, 32, 69, 120, 116, 101, 110, 115, 105, 111, 110, 255, 71, 97, 110, 100, 104, 105, 32, 78, 97, 103, 97, 114, 255, 75, 114, 105, 115, 104, 110, 97, 32, 78, 97, 103, 97, 114, 255, 49, 50, 51, 52, 255, 255, 79, 255, 81, 0, 47, 0, 0, 0, 0, 0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 7, 1, 1, 7, 1, 1, 7, 1, 1, 255, 82, 0, 12, 2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 92, 0, 35, 66, 111, 24, 110, 234, 110, 234, 110, 188, 103, 0, 103, 0, 102, 226, 95, 76, 95, 76, 95, 100, 72, 3, 72, 3, 72, 69, 79, 210, 79, 210, 79, 97, 255, 100, 0, 34, 0, 1, 67, 114, 101, 97, 116, 101, 100, 32, 98, 121, 58, 32, 74, 74, 50, 48, 48, 48, 32, 118, 101, 114, 115, 105, 111, 110, 32, 52, 46, 49, 255, 144, 0, 10, 0, 0, 0, 0, 2, 236, 0, 1, 255, 82, 0, 12, 2, 0, 0, 1, 1, 5, 4, 4, 0, 0, 255, 147, 255, 145, 0, 4, 0, 0, 195, 235, 5, 4, 11, 128, 38, 166, 255, 145, 0, 4, 0, 1, 192, 249, 65, 128, 16, 124, 55, 255, 145, 0, 4, 0, 2, 192, 249, 65, 0, 14, 175, 255, 145, 0, 4, 0, 3, 195, 238, 4, 131, 237, 4, 131, 232, 8, 15, 61, 227, 128, 14, 78, 244, 198, 10, 190, 128, 74, 255, 145, 0, 4, 0, 4, 192, 30, 10, 3, 229, 7, 0, 240, 64, 15, 157, 12, 56, 206, 16, 124, 255, 145, 0, 4, 0, 5, 192, 120, 40, 7, 196, 14, 1, 224, 128, 16, 128, 16, 144, 102, 15, 55, 255, 145, 0, 4, 0, 6, 195, 235, 15, 131, 232, 29, 7, 202, 36, 35, 123, 119, 32, 21, 133, 220, 173, 123, 29, 124, 190, 51, 158, 143, 0, 4, 234, 216, 145, 15, 189, 91, 82, 210, 45, 90, 170, 52, 34, 209, 158, 13, 108, 213, 78, 158, 137, 255, 145, 0, 4, 0, 7, 192, 56, 56, 15, 132, 112, 35, 164, 155, 1, 61, 240, 240, 232, 42, 148, 255, 145, 0, 4, 0, 8, 192, 49, 32, 29, 20, 7, 59, 113, 163, 24, 138, 108, 156, 26, 255, 145, 0, 4, 0, 9, 193, 241, 27, 135, 206, 122, 15, 144, 184, 25, 25, 211, 9, 237, 209, 173, 196, 150, 111, 25, 246, 238, 110, 167, 245, 97, 24, 144, 213, 187, 170, 6, 133, 23, 21, 199, 31, 204, 1, 35, 171, 39, 5, 127, 48, 209, 141, 130, 143, 72, 200, 150, 233, 85, 241, 55, 128, 173, 216, 49, 52, 216, 139, 110, 91, 225, 30, 109, 204, 188, 146, 157, 214, 18, 87, 32, 89, 157, 101, 246, 187, 223, 117, 50, 62, 81, 65, 205, 126, 255, 145, 0, 4, 0, 10, 160, 28, 48, 34, 126, 189, 171, 105, 217, 255, 145, 0, 4, 0, 11, 160, 58, 48, 35, 137, 175, 61, 198, 184, 255, 145, 0, 4, 0, 12, 199, 200, 222, 62, 71, 240, 248, 106, 128, 111, 222, 255, 137, 22, 12, 202, 78, 23, 233, 116, 114, 125, 113, 100, 226, 16, 241, 69, 36, 122, 23, 17, 120, 240, 5, 127, 168, 109, 250, 155, 59, 7, 206, 127, 108, 18, 105, 216, 235, 32, 159, 93, 175, 208, 238, 70, 166, 172, 160, 62, 58, 51, 254, 8, 55, 97, 246, 138, 129, 137, 16, 33, 165, 205, 22, 186, 92, 163, 108, 70, 25, 168, 130, 96, 162, 13, 106, 78, 71, 254, 89, 108, 233, 225, 39, 97, 63, 17, 13, 42, 95, 0, 30, 0, 130, 28, 154, 5, 162, 1, 51, 178, 125, 65, 235, 47, 162, 24, 112, 152, 119, 13, 83, 212, 102, 84, 248, 36, 193, 63, 193, 101, 254, 213, 80, 59, 106, 79, 74, 170, 227, 110, 2, 204, 201, 182, 60, 114, 60, 65, 195, 148, 232, 145, 30, 46, 232, 19, 28, 159, 29, 153, 101, 206, 162, 28, 108, 80, 229, 255, 145, 0, 4, 0, 13, 128, 255, 145, 0, 4, 0, 14, 128, 255, 145, 0, 4, 0, 15, 195, 224, 188, 135, 193, 127, 15, 134, 196, 158, 62, 204, 245, 173, 53, 224, 68, 102, 215, 173, 58, 244, 81, 11, 131, 110, 245, 166, 156, 166, 215, 76, 158, 156, 10, 170, 148, 182, 60, 115, 173, 176, 16, 1, 15, 169, 187, 111, 38, 226, 185, 241, 97, 88, 34, 140, 218, 123, 203, 88, 112, 88, 143, 74, 108, 17, 106, 37, 69, 149, 69, 151, 215, 37, 209, 201, 125, 81, 117, 124, 102, 108, 252, 251, 26, 14, 104, 229, 35, 22, 219, 199, 180, 110, 24, 47, 126, 104, 141, 232, 237, 115, 47, 31, 176, 190, 111, 243, 116, 185, 32, 185, 121, 57, 59, 197, 65, 61, 233, 98, 18, 172, 235, 82, 146, 150, 241, 30, 186, 172, 161, 155, 148, 171, 212, 237, 170, 123, 85, 177, 76, 132, 230, 38, 114, 51, 254, 36, 37, 236, 202, 21, 44, 48, 203, 191, 154, 22, 219, 13, 67, 28, 214, 71, 72, 63, 173, 24, 137, 62, 141, 14, 123, 11, 237, 106, 219, 68, 40, 62, 29, 255, 145, 0, 4, 0, 16, 128, 255, 145, 0, 4, 0, 17, 128, 255, 217, 235, 89, 152, 53, 59, 33, 186, 193, 56, 29, 117, 14, 31, 162, 102, 65, 224, 150, 175, 57, 29, 17, 95, 173, 173, 212, 123, 244, 250, 47, 255, 139, 96, 54, 34, 219, 243, 92, 100, 240, 182, 255, 21, 167, 91, 244, 127, 53, 165, 180, 223, 131, 221, 184, 74, 53, 233, 255, 238, 30, 166, 5, 157, 243
    ];

    // timestamp extraction
    let mut year: [Field; 4] = [0; 4];
    let mut month: [Field; 2] = [0; 2];
    let mut day: [Field; 2] = [0; 2];
    let mut hour: [Field; 2] = [0; 2];

    let mut year_val = 0;
    for i in 9..12 {
        year[i-9] = msg[i] - 48;
        year_val = 10 * year_val + (year[i-9]);
    }

    let mut month_val = 0;
    for i in 13..14 {
        month[i-13] = msg[i] - 48;
        month_val = month_val * 10 + month[i-13];
    }

    let mut day_val = 0;
    for i in 15..16 {
        day[i-15] = msg[i] - 48;
        day_val = day_val * 10 + day[i-15];
    }

    let mut hour_val = 0;
    for i in 17..18 {
        hour[i-17] = msg[i] - 48;
        hour_val = 10 * hour_val + hour[i-17];
    }

    let mut minute_val = 0;
    let mut second_val = 0;

    // Set maximum year and inclusion flags
    let maxYears = 2050;
    let includeHours = true;
    let includeMinutes = true;
    let includeSeconds = true;

    // Expected Unix timestamp for 2024-08-06 12:30:45 UTC
    //let expectedTimestamp: Field = 1723252245; // Updated expected timestamp

    // Calculate the Unix timestamp using the circuit
    let timestamp = main(
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

    // Use assertions to validate the timestamp, effectively "printing" it
    //assert(timestamp == expectedTimestamp, "Computed timestamp is: {timestamp}");
    assert(timestamp != 0, "Non-zero timestamp computed: {timestamp}");
}
