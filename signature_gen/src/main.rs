use num_bigint::BigUint;
use rsa::pkcs1v15::Signature;
use rsa::{RsaPrivateKey, RsaPublicKey};
use toml::Value;

use rsa::signature::{SignatureEncoding, Signer};
use rsa::traits::PublicKeyParts;
use sha2::{Digest, Sha256};

use clap::{App, Arg};

use noir_bignum_paramgen::{
    bn_limbs, compute_barrett_reduction_parameter, split_into_120_bit_limbs,
};

fn format_limbs_as_toml_value(limbs: &Vec<BigUint>) -> Vec<Value> {
    limbs
        .iter()
        .map(|a| Value::String(format!("0x{:x}", a)))
        .collect()
}

fn format_array_hex(values: &Vec<BigUint>) -> String {
    let formatted = values
        .iter()
        .map(|x| format!("0x{:x}", x))
        .collect::<Vec<_>>()
        .join(",\n        ");
    format!("[\n        {}\n    ]", formatted)
}

fn print_parameters(
    signature_limbs: &Vec<BigUint>,
    modulus_limbs: &Vec<BigUint>,
    redc_limbs: &Vec<BigUint>,
) {
    println!("    // Signature limbs");
    println!(
        "    let signature_limbs= {};",
        format_array_hex(signature_limbs)
    );
    println!("\n    // Modulus limbs");
    println!(
        "    let modulus_limbs = {};",
        format_array_hex(modulus_limbs)
    );
    println!("\n    // REDC parameters");
    println!("    let redc_limbs = {};", format_array_hex(redc_limbs));
}

fn generate_signature_parameters(msg: &[u8], as_toml: bool, exponent: u32) {
    let mut hasher = Sha256::new();
    hasher.update(msg);

    let hashed_message = hasher.finalize();

    let hashed_as_bytes = hashed_message
        .iter()
        .map(|&b| b.to_string())
        .collect::<Vec<String>>()
        .join(", ");

    let mut rng: rand::prelude::ThreadRng = rand::thread_rng();
    let bits: usize = 2048;
    let priv_key: RsaPrivateKey =
        RsaPrivateKey::new_with_exp(&mut rng, bits, &BigUint::from(exponent))
            .expect("failed to generate a key");
    let pub_key: RsaPublicKey = priv_key.clone().into();

    let signing_key = rsa::pkcs1v15::SigningKey::<Sha256>::new(priv_key);
    let sig: Vec<u8> = signing_key.sign(msg).to_vec();

    let sig_bytes = &Signature::try_from(sig.as_slice()).unwrap().to_bytes();

    let sig_uint: BigUint = BigUint::from_bytes_be(sig_bytes);

    let sig_str = bn_limbs(sig_uint.clone(), 2048);

    let modulus_limbs: Vec<BigUint> = split_into_120_bit_limbs(&pub_key.n().clone(), 2048);
    let redc_limbs = split_into_120_bit_limbs(
        &compute_barrett_reduction_parameter(&pub_key.n().clone()),
        2048,
    );
    let sig_limbs = split_into_120_bit_limbs(&sig_uint.clone(), 2048);

    if as_toml {
        println!(
            "modulus_limbs = {}",
            Value::Array(format_limbs_as_toml_value(&modulus_limbs))
        );
        println!(
            "redc_limbs = {}",
            Value::Array(format_limbs_as_toml_value(&redc_limbs))
        );
        println!(
            "signature_limbs = {}",
            Value::Array(format_limbs_as_toml_value(&sig_limbs))
        );
    } else {
        println!("hash = [{}]", hashed_as_bytes);
        print_parameters(&sig_limbs, &modulus_limbs, &redc_limbs);
    }
}

// Usage : cargo run -- --msg "86, 32 ,"
// Comma Separated Array of Bytes
fn main() {
    let matches = App::new("RSA Signature Generator")
        .arg(
            Arg::with_name("msg")
                .short("m")
                .long("msg")
                .takes_value(true)
                .help("Comma-separated array of bytes (e.g. 65,66,67 for ABC)")
                .required(true),
        )
        .arg(
            Arg::with_name("toml")
                .short("t")
                .long("toml")
                .help("Print output in TOML format"),
        )
        .arg(
            Arg::with_name("exponent")
                .short("e")
                .long("exponent")
                .takes_value(true)
                .help("Exponent to use for the key")
                .default_value("65537"),
        )
        .get_matches();

    let msg_str = matches.value_of("msg").unwrap();

    // Parse comma-separated bytes into Vec<u8>
    let msg: Vec<u8> = msg_str
        .split(',')
        .map(|s| s.trim().parse::<u8>().expect("Failed to parse byte"))
        .collect();

    let as_toml = matches.is_present("toml");
    let e: u32 = matches.value_of("exponent").unwrap().parse().unwrap();

    generate_signature_parameters(&msg, as_toml, e);
}

#[cfg(test)]
mod tests {
    use super::*;
    use rand::thread_rng;
    use rsa::pkcs1v15::Signature;
    use rsa::signature::{Signer, Verifier};
    use rsa::{pkcs1v15::VerifyingKey, RsaPrivateKey, RsaPublicKey};
    use sha2::Sha256;

    #[test]
    fn test_signature_generation() {
        let mut rng = thread_rng();
        let bits = 2048;
        let priv_key = RsaPrivateKey::new(&mut rng, bits).expect("failed to generate a key");
        let pub_key: RsaPublicKey = priv_key.clone().into();
        let text : &str = "86502555125550545755504850524855495649505253535551565525583117109105116327511710997114255484945484945495756522557725567477932731151041199711432671049711010025569971151163268101108104105255255664551494432511141003270108111111114255255494948485349255751141051151041109732789710397114255681011081041052558297100104101121328310412197109328097114107326912011610111011510511111025571971101001041053278971039711425575114105115104110973278971039711425549505152255255792558104700000600006000000000000600006000000000037117117112558201220011544002559203566111241102341102341101881030103010222695769576951007237237269792107921079972551000340167114101971161011003298121583274745048484832118101114115105111110325246492551440100000223601255820122001154400255147255145040019523554111283816625514504011922496512816124552551450402192249650141752551450403195238413123741312328156122712814782441981019012874255145040419230103229702406415157125620616124255145040519212040719614122412816128161441021555255145040619523515131232297202363512311932211332201731232912419051158143042342161451518991822104590170523420915813108213781581372551450407192565615132112351641551612402402324214825514504081924932292075911316324138108156262551450409193241271352061221514418425252119237209173196150111252462381101672459724144213187170613323211993120413517139512748209141130143722001502338524155128173216495221613911091225301092041881461572141887328915710124618722311750628165205126255145040101602848341261891711052172551450401116058483513717561198184255145040121992002226271240248106128111222255137221220278232331161141251131002261624169361222317120240512716810925015559720612710818105216235321599317520823870166172160625851254855972461381291371633165205221869216310870251681309616213106787125489108233225399763171342950300130281545162151178125652354716224112152119138321210284248361936319310125421380591067974170227110220420118260114606519514823214530462321928159291531012061622810880229255145040131282551450401412825514504015195224188135193127151341961586220424517353224681022151735824481111311102451661561662157615815610170148182601151731761611516918711138226185241978834140218123203881128814374108171063769149691512153720920112581117124102108252251261410422935222191991801102447126104141232237115473117619011124311618532185121575919765612339818172235821461502413018617216115514817121223717012385177761322303811451254363723620221444820319115422219136728214717263173241376214114123112371062196840622925514504016128255145040171282552172358915253593318619356291171431162102652241501755729179517317321212324425047255139965434219243921002401822552116791244127531651802231312211847453233255238301665157243";
        let signing_key = rsa::pkcs1v15::SigningKey::<Sha256>::new(priv_key);
        let sig: Vec<u8> = signing_key.sign(text.as_bytes()).to_vec();
        let verifying_key = VerifyingKey::<Sha256>::new(pub_key);

        let result = verifying_key.verify(
            text.as_bytes(),
            &Signature::try_from(sig.as_slice()).unwrap(),
        );
        result.expect("failed to verify");
    }
}
