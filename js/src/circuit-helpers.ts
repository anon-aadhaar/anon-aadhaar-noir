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


export async function getPublicKeyModulusFromCertificate(certificate: string) {
  const RSAPublicKey = pki.certificateFromPem(certificate).publicKey;
  const publicKey = (RSAPublicKey as pki.rsa.PublicKey).n.toString(16);

  const pubKeyBigInt = BigInt("0x" + publicKey);
  return pubKeyBigInt;
}

export type GenerateCircuitInputsOptions = {
  useTestingKey: boolean;
  nullifierSeed: number;
  signal: string;
  revealGender: boolean;
  revealAgeAbove18: boolean;
  revealPinCode: boolean;
  revealState: boolean;
}

export async function generateCircuitInputs(aadhaarQRData: string, options: GenerateCircuitInputsOptions) {
  // Verify locally
  const { certificate } = await verifySignature(aadhaarQRData, options.useTestingKey);
  const pubKey = await getPublicKeyModulusFromCertificate(certificate as string);

  const compressedBytes = convertBigIntToByteArray(BigInt(aadhaarQRData));
  const qrDataBytes = decompressByteArray(compressedBytes);
  const signedData = qrDataBytes.slice(0, qrDataBytes.length - 256);

  const signedDataPadded = new Uint8Array(1100);
  signedDataPadded.set(signedData);

  const signatureBytes = qrDataBytes.slice(
    qrDataBytes.length - 256,
    qrDataBytes.length
  );
  const signatureHex = signatureBytes.reduce(
    (str, byte) => str + byte.toString(16).padStart(2, '0'),
    ''
  );
  const signatureBigInt = BigInt('0x' + signatureHex);

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
      storage: Array.from(signedDataPadded).map(e => e.toString()),
    },
    qrDataPaddedLength: signedData.length.toString(),
    nullifierSeed: options.nullifierSeed.toString(),
    delimiterIndices: delimiterIndices.map((e) => e.toString()),
    signature_limbs: signatureLimbs,
    modulus_limbs: pubkeyModulusLimbs,
    redc_limbs: redcLimbs,
    revealGender: options.revealGender ? "1" : "0",
    revealAgeAbove18: options.revealAgeAbove18 ? "1" : "0",
    revealPinCode: options.revealPinCode ? "1" : "0",
    revealState: options.revealState ? "1" : "0",
    signalHash: hash(options.signal),
  };

  return input;
}

export async function generateProof(qrData: string, options: GenerateCircuitInputsOptions) {
  const input = await generateCircuitInputs(qrData, options);
  console.log("Generated inputs", input);

  const noir = new Noir(circuit as any);
  const backend = new UltraHonkBackend(circuit.bytecode, { threads: 8 });

  const startTime = performance.now();
  const { witness } = await noir.execute(input);
  const proof = await backend.generateProof(witness);
  const provingTime = performance.now() - startTime;

  return { proof: proof.proof, publicInputs: proof.publicInputs, provingTime };
}

export async function verifyProof(proof: any) {
  const backend = new UltraHonkBackend(circuit.bytecode, { threads: 8 });
  const verified = await backend.verifyProof(proof);

  return verified;
}
