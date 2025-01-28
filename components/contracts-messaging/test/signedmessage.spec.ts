// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { randomBytes } from 'ethers';
import { ethers } from 'hardhat';
import { compactedSign, packOrigin, randomOrigin, randomSigningKey, SignedMessage } from './utils';
import { TestSignedMessage } from '../typechain-ethers-v6';

describe('SignedMessage', () => {
    let c: TestSignedMessage;

    before(async () => {
        const f = await ethers.getContractFactory('TestSignedMessage');
        c = await f.deploy();
        await c.waitForDeployment();
    });

    it('No signers', async () => {
        const sm:SignedMessage = {
            sigs: [],
            packedOrigin: await packOrigin(randomOrigin()),
            message: randomBytes(10)
        };
        await expect(c.testDecodeSigned(sm)).revertedWithCustomError(c, 'NoSignaturesError');
    });

    it('Invalid Signature', async () => {
        const field = 115792089237316195423570985008687907853269984665640564039457584007908834671663n;
        const curveOrder = 115792089237316195423570985008687907852837564279074904382605163141518161494337n;
        const sm:SignedMessage = {
            sigs: [{
                r: '0x' + (field + 1n).toString(16),
                sv: '0x' + (curveOrder + 1n).toString(16)
            }],
            packedOrigin: await packOrigin(randomOrigin()),
            message: randomBytes(10)
        };
        await expect(c.testDecodeSigned(sm)).revertedWithCustomError(c, 'InvalidSignatureError');
    });

    it('Duplicate Signature', async () => {
        const k = randomSigningKey();
        const packedOrigin = await packOrigin(randomOrigin());
        const message = randomBytes(10);
        const sig = compactedSign(k, packedOrigin, message);

        const sm:SignedMessage = {
            sigs: [sig.signedMessage, sig.signedMessage],
            packedOrigin,
            message,
        };
        await expect(c.testDecodeSigned(sm)).revertedWithCustomError(c, 'DuplicateSignatureError');
    });

    it('One or more valid signers', async () => {
        const keys = [];
        for( let i = 0; i < 10; i++ )
        {
            keys.push(randomSigningKey());

            const message = randomBytes(10);
            const packedOrigin = await packOrigin(randomOrigin());

            const sigs: Array<ReturnType<typeof compactedSign>> = [];
            for( let j = 0; j < keys.length; j++ ) {
                const sig = compactedSign(keys[j], packedOrigin, message);
                sigs.push(sig);
            }

            const sm:SignedMessage = {
                sigs: sigs.map(x => x.signedMessage),
                packedOrigin,
                message
            };

            const {addresses} = await c.testDecodeSigned(sm);
            expect(addresses.length).eq(keys.length);

            for( let j = 0; j < keys.length; j++ ) {
                expect(addresses[j]).eq(sigs[j].signerAddress);
            }
        }
    });
});
