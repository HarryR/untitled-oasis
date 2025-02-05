// SPDX-License-Identifier: Apache-2.0

import { AddressLike, BigNumberish, BytesLike, computeAddress, getAddress,
         getUint, hexlify, keccak256, mask, randomBytes, resolveAddress,
         SigningKey, solidityPackedKeccak256} from 'ethers';

export type MessageOriginV1 = {
    messageVersion: BigNumberish,
    emitterContract: AddressLike;
    validAfterNBlocks: BigNumberish;
    validAfterNSeconds: BigNumberish;
    blockHeight: BigNumberish;
    a_reserved: BigNumberish;

    sequence: BigNumberish;
    srcChainId: BigNumberish;
    timestamp: BigNumberish;
    sender: AddressLike;
};

export type PackedOriginV1 = {
    a: BigNumberish;
    b: BigNumberish;
};

export function randomOrigin() : MessageOriginV1 {
    return {
        emitterContract: getAddress(hexlify(randomBytes(20))),
        validAfterNBlocks: BigInt(hexlify(randomBytes(1))),
        validAfterNSeconds: BigInt(hexlify(randomBytes(2))),
        blockHeight: BigInt(hexlify(randomBytes(4))),
        a_reserved: BigInt(hexlify(randomBytes(4))),
        messageVersion: 1n,

        sequence: BigInt(hexlify(randomBytes(4))),
        srcChainId: BigInt(hexlify(randomBytes(4))),
        timestamp: BigInt(hexlify(randomBytes(4))),
        sender: getAddress(hexlify(randomBytes(20)))
    }
}

export async function packOrigin(self: MessageOriginV1) : Promise<PackedOriginV1> {
    return {
        a: BigInt(await resolveAddress(self.emitterContract))
         | getUint(self.validAfterNBlocks) << 160n
         | getUint(self.validAfterNSeconds) << 168n
         | getUint(self.blockHeight) << 184n
         | getUint(self.a_reserved) << 216n
         | getUint(self.messageVersion) << 248n
         ,
        b: getUint(self.sequence)
         | getUint(self.srcChainId) << 32n
         | getUint(self.timestamp) << 64n
         | BigInt(await resolveAddress(self.sender)) << 96n
    };
}

function bigintToAddress(n:bigint) : string {
    const x = mask(n, 160n).toString(16);
    return getAddress('0x' + '0'.repeat(40 - x.length) + x);
}

export function unpackOrigin(p: PackedOriginV1) : MessageOriginV1 {
    const a = getUint(p.a);
    const b = getUint(p.b);
    return {
        emitterContract: bigintToAddress(a),
        validAfterNBlocks: mask(a >> 160n, 8n),
        validAfterNSeconds: mask(a >> 168n, 16n),
        blockHeight: mask(a >> 184n, 32n),
        a_reserved: mask(a >> 216n, 32n),
        messageVersion: mask(a >> 248n, 8n),

        sequence: mask(b, 32n),
        srcChainId: mask(b >> 32n, 32n),
        timestamp: mask(b >> 64n, 32n),
        sender: bigintToAddress(b >> 96n)
    };
}

export function randomSigningKey() {
    return new SigningKey(randomBytes(32));
}

export type SignedMessageSignature = {
    r: BytesLike;
    sv: BytesLike;
}

export type SignedMessage = {
    sigs: Array<SignedMessageSignature>;
    packedOrigin: PackedOriginV1;
    message: BytesLike;
}

export function hashMessage(p:PackedOriginV1, message:BytesLike) {
    return solidityPackedKeccak256(
        ['uint256', 'uint256', 'bytes32'],
        [p.a, p.b, keccak256(message)],
    )
}

export function compactedSign(s:SigningKey, p:PackedOriginV1, unhashedMessage:BytesLike) {
    const signerAddress = computeAddress(s);
    const sig = s.sign(hashMessage(p, unhashedMessage));
    const signedMessage:SignedMessageSignature = {
        r: sig.r,
        sv: sig.yParityAndS
    };
    return { signerAddress, signedMessage };
}
