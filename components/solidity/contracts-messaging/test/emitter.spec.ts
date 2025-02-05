// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { hexlify, randomBytes } from 'ethers';
import { ethers } from 'hardhat';
import { OnMessageEvent } from '../typechain-ethers-v6/contracts/MessageEmitterV1';
import { hashMessage, packOrigin } from './utils';

describe('MessageEmitterV1', () => {
    it('Generally works...', async function () {
        this.timeout(1000*60*2);

        const mdf = await ethers.getContractFactory('MessageDecoderV1');
        const mdc = await mdf.deploy();
        await mdc.waitForDeployment();

        const mef = await ethers.getContractFactory('MessageEmitterV1');
        const mec = await mef.deploy(await mdc.getAddress());
        await mec.waitForDeployment();

        const network = await mec.runner?.provider?.getNetwork();

        let sequence = 0n;

        for( let i = 0; i < 3; i++ )
        {
            const message = randomBytes(32);
            const validAfterNBlocks = BigInt(hexlify(randomBytes(1)));
            const validAfterNSeconds = BigInt(hexlify(randomBytes(2)));

            sequence += 1n;

            const tx = await mec.send(message, validAfterNBlocks, validAfterNSeconds);
            const receipt = await tx.wait();

            const b = await mec.runner?.provider?.getBlock(tx.blockNumber!)!

            const event = mef.interface.decodeEventLog(
                                    'OnMessage',
                                    receipt!.logs[0].data,
                                    receipt!.logs[0].topics
                                ) as unknown as OnMessageEvent.OutputObject;

            const decoded = await mdc.decodeUnsigned(event.packedOriginAndMessage);

            const [owner] = await ethers.getSigners()
            const origin = decoded.origin;

            // Check the origin structure
            expect(origin.sequence).eq(sequence);
            expect(origin.validAfterNBlocks).eq(validAfterNBlocks);
            expect(origin.validAfterNSeconds).eq(validAfterNSeconds);
            expect(origin.srcChainId).eq(network?.chainId);
            expect(origin.emitterContract).eq(await mec.getAddress());
            expect(origin.sender).eq(owner.address);
            // XXX: on Sapphire the block timestamp might be ~1s behind
            expect(origin.timestamp).gte(b!.timestamp - 1)

            const packedOrigin = await packOrigin(decoded.origin)
            // on-chain messageId matches locally computed one
            const expectedMessageId = hashMessage(packedOrigin, message);
            expect(event.messageId).eq(expectedMessageId);
        }
    });
});
