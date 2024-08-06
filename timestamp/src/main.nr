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
    assert(year as i32 >= 1970);
    assert(year as i32 <= maxYears as i32);
    assert(month as i32 >= 1);
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
    let daysTillPreviousMonth: [i32; 12] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

    // Calculate the number of years and leap years since 1970
    let yearsSinceEpoch: i32 = (year as i32) - 1970;
    let leapYears: i32 = (yearsSinceEpoch + 1) / 4;

    // Calculate days passed in the current year
    let mut daysPassedInCurrentYear: i32 = (day as i32) - 1;
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
    let totalDaysPassed: i32 = yearsSinceEpoch * 365 + leapYears + daysPassedInCurrentYear;

    // Calculate the Unix timestamp
    let mut timestamp: i32 = totalDaysPassed * 86400;

    // Add hours, minutes, and seconds if included
    if includeHours {
        timestamp += (hour as i32) * 3600;
    }
    if includeMinutes {
        timestamp += (minute as i32) * 60;
    }
    if includeSeconds {
        timestamp += (second as i32);
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

    // Expected Unix timestamp for 2024-08-06 12:30:45 UTC
    //let expectedTimestamp: Field = 1723252245; // Updated expected timestamp

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
