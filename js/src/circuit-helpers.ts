import {
  convertBigIntToByteArray,
  decompressByteArray,
  hash,
} from "@anon-aadhaar/core";
import * as TOML from "@iarna/toml";
import * as NoirBignum from "@mach-34/noir-bignum-paramgen";
import {
  Uint8ArrayToCharArray,
  bufferToHex,
} from "@zk-email/helpers/dist/binary-format";
import { sha256Pad } from "@zk-email/helpers/dist/sha-utils";
import crypto from "crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import path from "path";
import { testQRData } from "../assets/test.json";

let qrData = testQRData;
let certificateName = "testCertificate.pem";
if (process.env.REAL_DATA === "true") {
  qrData = process.env.QR_DATA as string;
  certificateName = "uidai_offline_publickey_26022021.cer";
  if (!qrData) {
    throw new Error("QR_DATA env is not set");
  }
}

export function generateCircuitInputs(aadhaarQRData: string) {
  // Get pubkey and convert to BigInt
  const pkData = readFileSync(
    path.join(__dirname, "../assets", certificateName)
  );
  const pk = crypto.createPublicKey(pkData);
  const pubKey = BigInt(
    "0x" +
      bufferToHex(
        Buffer.from(pk.export({ format: "jwk" }).n as string, "base64url")
      )
  );

  const compressedBytes = convertBigIntToByteArray(BigInt(qrData));
  const qrDataBytes = decompressByteArray(compressedBytes);
  const signedData = qrDataBytes.slice(0, qrDataBytes.length - 256);

  const signedDataPadded = new Uint8Array(512 * 3);
  signedDataPadded.set(signedData);

  const signatureBytes = qrDataBytes.slice(
    qrDataBytes.length - 256,
    qrDataBytes.length
  );

  const signatureBigInt = BigInt(
    "0x" + bufferToHex(Buffer.from(signatureBytes)).toString()
  );

  let signatureLimbs = NoirBignum.bnToLimbStrArray(signatureBigInt);
  let pubkeyModulusLimbs = NoirBignum.bnToLimbStrArray(pubKey);
  let redcLimbs = NoirBignum.bnToRedcLimbStrArray(pubKey);

  const delimiterIndices: number[] = [];
  for (let i = 0; i < signedDataPadded.length; i++) {
    if (signedDataPadded[i] === 255) {
      delimiterIndices.push(i);
    }
    if (delimiterIndices.length === 18) {
      break;
    }
  }

  const input = {
    qrDataPadded: {
      len: signedData.length,
      storage: Uint8ArrayToCharArray(signedData),
    },
    qrDataPaddedLength: signedData.length.toString(),
    nullifierSeed: 1,
    delimiterIndices: delimiterIndices.map((e) => e.toString()),
    signature_limbs: signatureLimbs,
    modulus_limbs: pubkeyModulusLimbs,
    redc_limbs: redcLimbs,
    revealGender: "1",
    revealAgeAbove18: "1",
    revealPinCode: "1",
    revealState: "1",
    signalHash: hash(1),
  };

  return input;
}

