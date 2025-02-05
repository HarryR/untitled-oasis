import { expect } from 'chai';
import { hexlify, parseEther, randomBytes, Transaction } from 'ethers';
import { ethers } from 'hardhat';
import createxPresignedTx from '../signed_serialised_transaction_gaslimit_3000000_.json';

const createXAddress = '0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed'

describe('AtomicProxyFactory', () => {
    before(async () => {
        const [signer] = await ethers.getSigners();
        const p = signer.provider;
        const n = await p.getNetwork()

        // With hardhat, it won't accept pre-signed transactions
        if( n.chainId == 1337n || n.chainId == 31337n ) {
            // So, re-sign it, to get deployed bytecode
            const parsedTx = Transaction.from(createxPresignedTx)
            const tx = await signer.sendTransaction({
                data: parsedTx.data,
                gasLimit: parsedTx.gasLimit,
            });

            // then perform switcharoo, putting runtime code at expected addr
            const receipt = await tx.wait();
            const actualAddress = receipt!.contractAddress!;
            const runtimeBytecode = await ethers.provider.getCode(actualAddress);
            await signer.provider.send("hardhat_setCode", [createXAddress, runtimeBytecode]);

            // Verify the two match
            const verificationCode = await ethers.provider.getCode(createXAddress);
            expect(verificationCode).eq(runtimeBytecode);
        }
        else {
            // First send enough gas to the deployment account
            const tx = await signer.sendTransaction({
                to: '0xeD456e05CaAb11d66C4c797dD6c1D6f9A7F352b5',
                value: parseEther('4'),
                data: '0x'
            })
            await tx.wait();

            // On sapphire localnet, deploy using pre-signed CreateX
            const tx2 = await p.broadcastTransaction(createxPresignedTx);
            await tx2.wait();
        }
    });

    it('AtomicProxyFactory', async () => {
        // Deploy factory
        const ff = await ethers.getContractFactory('AtomicProxyFactory');
        const f = await ff.deploy();
        await f.waitForDeployment();

        // Deploy a new proxy
        //const salt = getBytes(keccak256(new TextEncoder().encode()));
        const name = "My Proxy"
        const ownerAddr = (await ethers.getSigners())[0].address;
        await f.deployProxy(name);
        const proxyAddr = await f.getProxyAddress(ownerAddr, name);

        // Deploy test implementation
        const impl1_factory = await ethers.getContractFactory('TestImpl1');
        const impl1 = await impl1_factory.deploy();
        impl1.waitForDeployment();

        // Upgrade newly deployed proxy with our implementation
        const upgradable = await ethers.getContractAt('IHasUpgradeAndCall', proxyAddr);
        const upgd_tx = await upgradable.upgradeToAndCall(await impl1.getAddress(), new Uint8Array());
        await upgd_tx.wait();

        // Verify implementation has been switched
        const proxied_impl1 = await ethers.getContractAt('TestImpl1', proxyAddr);
        expect(await proxied_impl1.oneViewFunction()).eq(123n);

        // Check we can retrieve implementation address & it matches
        const withERC1967 = await ethers.getContractAt('IHasERC1967Implementation', proxyAddr);
        expect(await withERC1967.ERC1967_implementation()).eq(await impl1.getAddress());

        // Next implementation
        const impl2_factory = await ethers.getContractFactory('TestImpl2');
        const impl2 = await impl2_factory.deploy();
        impl2.waitForDeployment();

        // Then upgrade, with a call
        const impl2_randdata = randomBytes(32);
        const impl2_fndata = await impl2.twoFunction.populateTransaction(impl2_randdata);
        const impl2_tx = await upgradable.upgradeToAndCall(await impl2.getAddress(), impl2_fndata.data);
        const impl2_receipt = await impl2_tx.wait();
        // Verify the event was emitted with correct data
        expect(impl2_receipt?.logs[1].data).eq(hexlify(impl2_randdata));
        // and implementation has been switched
        expect(await withERC1967.ERC1967_implementation()).eq(await impl2.getAddress());
    });

    // TODO: verify negatives, non-owners can't upgrade etc
});
