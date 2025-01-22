// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ICreateX } from './ICreateX.sol';
import { AtomicProxy } from './AtomicProxy.sol';

/**
 * @title AtomicProxyFactory
 *
 * @dev For deploying upgradeable proxies with deterministic addresses.
 *
 * This factory enables a powerful deployment pattern:
 * 1. Any user can deploy a proxy to a deterministic address using just:
 *    - A salt value
 *    - An owner address
 *
 * 2. The initial proxy deployment uses:
 *    - address(0) as the implementation
 *    - empty initialization data
 *    - the specified owner address
 *
 * 3. This creates a "placeholder" proxy that:
 *    - Has a predictable address (based on salt and owner)
 *    - Can only be upgraded by the specified owner
 *    - Initially does nothing (implementation is address(0))
 *
 * This pattern allows users to "reserve" deterministic addresses that only
 * specific owners can later configure. The owner can upgrade to the actual
 * implementation and initialize it at their convenience, without racing against
 * other deployments.
 *
 * The factory uses CREATE2 (via CreateX) for deterministic addressing, making
 * proxy addresses consistent across all chains where this factory is deployed
 * at the same address.
 */
contract AtomicProxyFactory {

    ICreateX constant CREATE_X = ICreateX(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    event ProxyDeployed(address proxy, address initialOwner);

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

    function getProxyAddress(bytes32 salt, address admin)
        external view
        returns (address)
    {
        return deployedProxies[salt][admin];
    }

    function deployProxy(bytes32 salt, address admin)
        external
        returns (address)
    {
        address proxy = CREATE_X.deployCreate2(salt, _getCreationCode(admin));

        emit ProxyDeployed(proxy, admin);

        deployedProxies[salt][admin] = proxy;

        return proxy;
    }

    function computeProxyAddress(bytes32 salt, address admin)
        public view
        returns (address)
    {
        return CREATE_X.computeCreate2Address(
            salt,
            keccak256(_getCreationCode(admin)),
            address(this)
        );
    }
}
