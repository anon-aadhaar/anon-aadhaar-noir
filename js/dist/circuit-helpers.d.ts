export declare function getPublicKeyModulusFromCertificate(certificate: string): Promise<bigint>;
export declare function generateCircuitInputs(aadhaarQRData: string): Promise<{
    qrDataPadded: {
        len: number;
        storage: string[];
    };
    qrDataPaddedLength: string;
    nullifierSeed: number;
    delimiterIndices: string[];
    signature_limbs: string[];
    modulus_limbs: string[];
    redc_limbs: string[];
    revealGender: string;
    revealAgeAbove18: string;
    revealPinCode: string;
    revealState: string;
    signalHash: string;
}>;
export declare function generateProof(qrData: string): Promise<void>;
