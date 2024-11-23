mod test_inputs;

mod tests {
    use crate::main;
    use crate::MAX_DATA_LENGTH;
    use crate::tests::test_inputs::TestCase1::{
        SIGNED_DATA, NULLIFIER_SEED, SIGNED_DATA_LENGTH, DELIMITER, SIGNATURE_LIMBS, MODULUS_LIMBS,
        REDC_LIMBS, SIGNAL_HASH,
    };

    #[test]
    fn test_aadhar_qr_verifier() {
        let mut qr_data_padded: BoundedVec<u8, MAX_DATA_LENGTH> = BoundedVec::new();
        qr_data_padded.extend_from_array(SIGNED_DATA);

        let revealed_data = main(
            qr_data_padded,
            SIGNED_DATA_LENGTH,
            DELIMITER,
            SIGNATURE_LIMBS,
            MODULUS_LIMBS,
            REDC_LIMBS,
            true,
            true,
            true,
            true,
            NULLIFIER_SEED,
            SIGNAL_HASH,
        );

        // all of these result values are extracted from circom codebase.
        assert(revealed_data.age == true, "Age should be above 18");
        assert(revealed_data.gender == 77, "M as Ascii");
        assert(revealed_data.pincode == 110051, "Pincode should be 110051");
        assert(revealed_data.state == 452723500356, "State should be 452723500356");
        assert(revealed_data.timestamp == 1713555000, "Timestamp should be 1713555000");

        println(revealed_data.nullifier);
        println(revealed_data.pubkey_hash);
    }
}

