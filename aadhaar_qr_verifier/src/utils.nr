pub struct QRData {
    ageAbove18: Field,
    gender: Field,
    pinCode: Field,
    state: Field,
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
