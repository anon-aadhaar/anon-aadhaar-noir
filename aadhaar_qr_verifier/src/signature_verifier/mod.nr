use dep::rsa::{rsa::verify_sha256_pkcs1v15, types::RBN2048};
use dep::std::hash::sha256;
use dep::bignum::{params::BigNumParams, RuntimeBigNum};
use crate::RSA_EXPONENT;

pub fn verify_signature(
    msg_str: str<2663>,
    signature_limbs: [Field; 18],
    modulus_limbs: [Field; 18],
    redc_limbs: [Field; 18],
) {
    let sha256_hash: [u8; 32] = sha256(msg_str.as_bytes());
    let has_multiplicative_inverse = false;
    let params: BigNumParams<18, 2048> =
        BigNumParams::new(has_multiplicative_inverse, modulus_limbs, redc_limbs);

    let signature: RBN2048 = RuntimeBigNum::from_array(params, signature_limbs);

    assert(verify_sha256_pkcs1v15(sha256_hash, signature, RSA_EXPONENT));
}
