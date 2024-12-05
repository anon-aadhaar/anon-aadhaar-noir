import { Noir } from "@noir-lang/noir_js";
import { UltraHonkBackend } from "@aztec/bb.js";
import { pki } from "node-forge";
import circuit from "./assets/circuit-0.1.0.json";
import { verifySignature } from "@anon-aadhaar/react";
import {
  convertBigIntToByteArray,
  decompressByteArray,
  hash,
} from "@anon-aadhaar/core";
import * as NoirBignum from "@mach-34/noir-bignum-paramgen";
import {
  Uint8ArrayToCharArray,
  bufferToHex,
} from "@zk-email/helpers/dist/binary-format";


export async function getPublicKeyModulusFromCertificate(certificate: string) {
  const RSAPublicKey = pki.certificateFromPem(certificate).publicKey;
  const publicKey = (RSAPublicKey as pki.rsa.PublicKey).n.toString(16);

  const pubKeyBigInt = BigInt("0x" + publicKey);
  return pubKeyBigInt;
}

export async function generateCircuitInputs(aadhaarQRData: string) {
  // Verify locally
  const { certificate } = await verifySignature(aadhaarQRData, true);
  const pubKey = await getPublicKeyModulusFromCertificate(certificate as string);

  const compressedBytes = convertBigIntToByteArray(BigInt(aadhaarQRData));
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

  const signatureLimbs = NoirBignum.bnToLimbStrArray(signatureBigInt);
  const pubkeyModulusLimbs = NoirBignum.bnToLimbStrArray(pubKey);
  const redcLimbs = NoirBignum.bnToRedcLimbStrArray(pubKey);

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
      storage: Uint8ArrayToCharArray(signedDataPadded),
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

export async function generateProof(qrData: string) {
  const input = await generateCircuitInputs(qrData);
  console.log("Generated inputs", input);

  const noir = new Noir(circuit as any);
  const backend = new UltraHonkBackend(circuit.bytecode, { threads: 8 });

  const startTime = performance.now();
  const { witness } = await noir.execute(input);
  const proof = await backend.generateProof(witness);
  const provingTime = performance.now() - startTime;
  console.log(`Proof generated in ${provingTime}ms`);

  const verified = await backend.verifyProof(proof);
  console.log(`Proof verified: ${verified}`);
}
