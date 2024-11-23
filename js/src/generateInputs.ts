import {
    convertBigIntToByteArray,
    decompressByteArray,
    hash,
} from '@anon-aadhaar/core'
import * as TOML from '@iarna/toml'
import * as NoirBignum from "@mach-34/noir-bignum-paramgen"
import {
    Uint8ArrayToCharArray,
    bufferToHex,
} from '@zk-email/helpers/dist/binary-format'
import { sha256Pad } from '@zk-email/helpers/dist/sha-utils'
import crypto from 'crypto'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs'
import path from 'path'
import { testQRData } from '../assets/test.json'

let qrData = testQRData
let certificateName = 'testCertificate.pem'
if (process.env.REAL_DATA === 'true') {
    qrData = process.env.QR_DATA as string
    certificateName = 'uidai_offline_publickey_26022021.cer'
    if (!qrData) {
        throw new Error('QR_DATA env is not set')
    }
}

function computeBarrettReductionParameter(modulus: bigint): bigint {
    const k = modulus.toString(2).length;
    const overflowBits = 4;
    const multiplicand = BigInt(1) << (BigInt(2) * BigInt(k) + BigInt(overflowBits));
    const barrettReductionParameter = multiplicand / modulus;
    return barrettReductionParameter;
}

const main = () => {
    const nullifierSeed = "12345678"

    const pkData = readFileSync(
        path.join(__dirname, '../assets', certificateName),
    )
    const pk = crypto.createPublicKey(pkData)

    const QRData = BigInt(qrData)

    const qrDataBytes = convertBigIntToByteArray(BigInt(QRData))
    const decodedData = decompressByteArray(qrDataBytes)

    const signatureBytes = decodedData.slice(
        decodedData.length - 256,
        decodedData.length,
    )

    const signedData = decodedData.slice(0, decodedData.length - 256)

    const [paddedMsg, messageLen] = sha256Pad(signedData, 512 * 3)

    const pubKey = BigInt(
        '0x' +
        bufferToHex(
            Buffer.from(pk.export({ format: 'jwk' }).n as string, 'base64url'),
        ),
    )

    const signature = BigInt(
        '0x' + bufferToHex(Buffer.from(signatureBytes)).toString(),
    )

    let signature_limbs = NoirBignum.bnToLimbStrArray(signature);
    let modulus_limbs = NoirBignum.bnToLimbStrArray(pubKey);
    let redc_limbs = NoirBignum.bnToLimbStrArray(computeBarrettReductionParameter(pubKey));

    const delimiterIndices: number[] = []
    for (let i = 0; i < paddedMsg.length; i++) {
        if (paddedMsg[i] === 255) {
            delimiterIndices.push(i)
        }
        if (delimiterIndices.length === 18) {
            break
        }
    }

    const input = {
        qrDataPadded: {
            len: paddedMsg.length.toString(),
            storage: Uint8ArrayToCharArray(paddedMsg)
        },
        qrDataPaddedLength: signedData.length.toString(),
        nullifierSeed: nullifierSeed,
        delimiterIndices: delimiterIndices.map((e) => e.toString()),
        signature_limbs,
        modulus_limbs,
        redc_limbs,
        revealGender: '1',
        revealAgeAbove18: '1',
        revealPinCode: '1',
        revealState: '1',
        signalHash: hash(1),
    }

    const dir = path.join(__dirname, '../../circuits/testcases')
    if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true })
    }

    const toml_path = "../../circuits/testcases/test.toml";
    writeFileSync(
        path.join(__dirname, toml_path),
        TOML.stringify(input)
    )

    console.log('Generated file at', toml_path)
}

main()