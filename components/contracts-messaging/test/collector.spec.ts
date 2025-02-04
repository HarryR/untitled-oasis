// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { keccak256, randomBytes } from 'ethers';
import { ethers } from 'hardhat';
import { hashMessage, randomOrigin, packOrigin, randomSigningKey, compactedSign } from './utils';
import { SignatureCollector } from '../typechain-ethers-v6';

describe('SignatureCollector', () => {
    let c: SignatureCollector;

    before(async () => {
        const f = await ethers.getContractFactory('SignatureCollector');
        c = await f.deploy();
        await c.waitForDeployment();
    });

    it('Collects & Rejects Duplicate', async () => {
        const origin = randomOrigin();
        const packedOrigin = await packOrigin(origin);
        const message = randomBytes(100);
        const messageHash = keccak256(message);
        const messageId = hashMessage(packedOrigin, message);

        let signerCount = 0n;

        for( let i = 0; i < 5; i++ )
        {
            signerCount += 1n;

            const signingKey = randomSigningKey();
            const {signedMessage} = compactedSign(signingKey, packedOrigin, message);

            const tx1 = await c.collect_signature(packedOrigin, messageHash, signedMessage);
            await tx1.wait();

            expect(await c.signatures_count(messageId)).eq(signerCount);

            await expect(c.collect_signature.staticCall(packedOrigin, messageHash, signedMessage)).revertedWithCustomError(c, 'DuplicateSignatureError');
        }
    });

    it('IAllowedSigner', async () => {
        const f = await ethers.getContractFactory('TestAllowedSigner');
        const tas = await f.deploy();
        await tas.waitForDeployment();

        // Set the sender as the test contract, to verify if signer allowed
        const origin = randomOrigin();
        origin.sender = await tas.getAddress();

        // Create common message to sign
        const packedOrigin = await packOrigin(origin);
        const message = randomBytes(100);
        const messageHash = keccak256(message);
        const messageId = hashMessage(packedOrigin, message);

        // Using a random signer, sign the message
        const signingKey1 = randomSigningKey();
        const {signerAddress: signerAddress1,
               signedMessage: sig1} = compactedSign(signingKey1, packedOrigin, message);

        const tx1 = await tas.addSigner(signerAddress1);
        await tx1.wait();

        // Submit the signature and verify it's been accepted
        await c.collect_signature(packedOrigin, messageHash, sig1);
        expect(await c.signatures_count(messageId)).eq(1n);
        expect((await c.signers_fetch(messageId))[0]).eq(signerAddress1);

        // Then create another signing key
        const signingKey2 = randomSigningKey();
        const {signedMessage: sig2} = compactedSign(signingKey2, packedOrigin, message);

        // Then, verify it's not allowed
        expect(c.collect_signature.staticCall(packedOrigin, messageHash, sig2)).revertedWithCustomError(c, 'SignerNotAllowedError');
    });
});
