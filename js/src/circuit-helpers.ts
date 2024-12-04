import { Noir } from "@noir-lang/noir_js";
import { UltraHonkBackend } from "@aztec/bb.js";
import circuit from "../assets/circuit-0.1.0.json";
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
  // Convert PEM certificate to bigint pubkey
  const pemCertificate = certificate;
  const base64Certificate = pemCertificate.split(/\r?\n/).filter((line: string) => line.trimStart().endsWith('-----BEGIN CERTIFICATE-----') || line.trimStart().endsWith('-----END CERTIFICATE-----')).join('');
  const binaryCertificate = atob(base64Certificate);
  const certificateArrayBuffer = new ArrayBuffer(binaryCertificate.length);
  const certificateView = new Uint8Array(certificateArrayBuffer);
  for (let i = 0; i < binaryCertificate.length; i++) {
    certificateView[i] = binaryCertificate.charCodeAt(i);
  }
  const modulusBuffer = await window.crypto.subtle.importKey("spki", certificateArrayBuffer, { name: "RSA-OAEP", hash: "SHA-256" }, true, ["encrypt"]);
  const modulus = await window.crypto.subtle.exportKey("jwk", modulusBuffer);
  const modulusBigInt = BigInt("0x" + Buffer.from(modulus.n as string, 'utf-8').toString('hex'));

  return modulusBigInt;
}

export async function generateCircuitInputs(aadhaarQRData: string) {
  // Verify locally
  const { certificate } = await verifySignature(aadhaarQRData, true);
  const pubKey = await getPublicKeyModulusFromCertificate(certificate as string);

  console.log(pubKey);

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

export async function generateProof(qrData: string) {
  const input = await generateCircuitInputs(qrData);

  const noir = new Noir(circuit as any);

  const backend = new UltraHonkBackend(circuit.bytecode);

  const startTime = performance.now();
  const { witness } = await noir.execute(input);
  const proof = await backend.generateProof(witness);
  const provingTime = performance.now() - startTime;
  console.log(`Proof generated in ${provingTime}ms`);

  const verified = await backend.verifyProof(proof);
  console.log(`Proof verified: ${verified}`);
}
