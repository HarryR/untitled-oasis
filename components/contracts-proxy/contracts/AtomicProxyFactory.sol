// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ICreateX } from './ICreateX.sol';
import { AtomicProxy } from './AtomicProxy.sol';
import { IAtomicProxyFactory } from './IAtomicProxyFactory.sol';

/**
 * @title AtomicProxyFactory
 *
 * @dev For deploying upgradeable proxies with deterministic addresses.
 *
 * This factory enables a powerful deployment pattern:
 * 1. Any user can deploy a proxy to a deterministic address using just a name
 *
 * 2. The initial proxy deployment uses:
 *    - address(0) as the implementation
 *    - the invoker as the `creator` address
 *
 * 3. This creates a "placeholder" proxy that:
 *    - Has a predictable address (based on the `name` and `creatoe`)
 *    - Can only be upgraded by the specified `creator`
 *    - Initially does nothing (implementation is address(0))
 *
 * This pattern allows users to "reserve" deterministic addresses that only a
 * specific `creator` can later configure. The `creator` can upgrade to the
 * actual implementation and initialize it at their convenience, without racing
 * against other deployments.
 *
 * The factory uses CREATE2 (via CreateX) for deterministic addressing, making
 * proxy addresses consistent across all chains where this factory is deployed
 * at the same address.
 */
contract AtomicProxyFactory is IAtomicProxyFactory {

    ICreateX constant CREATE_X = ICreateX(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    mapping(bytes32 => mapping(address => address)) private deployedProxies;

    function _getCreationCode(address admin)
        internal pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            type(AtomicProxy).creationCode,
            abi.encode(admin)
        );
    }

    function getProxyAddress(address creator, string memory name)
        external view
        returns (address)
    {
        bytes32 salt = keccak256(bytes(name));

        return deployedProxies[salt][creator];
    }

    function deployProxy(string memory name)
        external
        returns (address)
    {
        bytes32 salt = keccak256(bytes(name));

        bytes32 newSalt = bytes32(abi.encodePacked(
            address(bytes20(salt)),
            uint8(0x00),    // Cross-chain redeploy protection is disabled
            bytes11(keccak256(abi.encodePacked(salt)))
        ));

        address admin = msg.sender;

        address proxy = CREATE_X.deployCreate2(newSalt, _getCreationCode(admin));

        emit ProxyDeployed(proxy, admin);

        deployedProxies[salt][admin] = proxy;

        return proxy;
    }

    function computeProxyAddress(address creator, string memory name)
        public view
        returns (address)
    {
        bytes32 salt = keccak256(bytes(name));

        return CREATE_X.computeCreate2Address(
            salt,
            keccak256(_getCreationCode(creator)),
            address(this)
        );
    }
}
