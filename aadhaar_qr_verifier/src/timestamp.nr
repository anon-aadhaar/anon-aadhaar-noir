use crate::position::{
    reference_id_position, gender_position, dob_position, pincode_position, state_position,
};

pub fn time_stamp_extractor(
    delimiterIndices: [u64; 18],
    msg: [Field; 1152],
) -> (Field, Field, Field, Field, Field, Field, Field, Field, Field, Field) {
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

    (
        year_val, month_val, day_val, hour_val, minute_val, second_val, age, gender_data,
        pincode_data, state_data,
    )
}

// Define the main function for converting date and time to a Unix timestamp
pub fn timestamp_circuit(
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
