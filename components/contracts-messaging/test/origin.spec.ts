// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { ethers } from 'hardhat';

import { randomOrigin, packOrigin, unpackOrigin } from './utils';

describe('MessageOrigin', () => {
    it('Pack & Unpack', async () => {
        for( let i = 0; i < 0xFF; i++ ) {
            const f = await ethers.getContractFactory('TestOrigin');
            const c = await f.deploy();
            await c.waitForDeployment();

            const origin = randomOrigin();

            const packed = await c.testPack(origin);
            const jsPacked = await packOrigin(origin);
            expect(packed.a).eq(jsPacked.a);
            expect(packed.b).eq(jsPacked.b);

            const unpacked = await c.testUnpack({a: packed.a, b: packed.b});
            expect(unpacked.messageVersion).eq(origin.messageVersion);
            expect(unpacked.emitterContract).eq(origin.emitterContract);
            expect(unpacked.validAfterNBlocks).eq(origin.validAfterNBlocks);
            expect(unpacked.validAfterNSeconds).eq(origin.validAfterNSeconds);
            expect(unpacked.sequence).eq(origin.sequence);
            expect(unpacked.srcChainId).eq(origin.srcChainId);
            expect(unpacked.timestamp).eq(origin.timestamp);
            expect(unpacked.sender).eq(origin.sender);

            const jsUnpacked = unpackOrigin(packed);
            expect(jsUnpacked.messageVersion).eq(origin.messageVersion);
            expect(jsUnpacked.emitterContract).eq(origin.emitterContract);
            expect(jsUnpacked.validAfterNBlocks).eq(origin.validAfterNBlocks);
            expect(jsUnpacked.validAfterNSeconds).eq(origin.validAfterNSeconds);
            expect(jsUnpacked.sequence).eq(origin.sequence);
            expect(jsUnpacked.srcChainId).eq(origin.srcChainId);
            expect(jsUnpacked.timestamp).eq(origin.timestamp);
            expect(jsUnpacked.sender).eq(origin.sender);
        }
    });
});
