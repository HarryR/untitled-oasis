// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Proxy } from '@openzeppelin/contracts/proxy/Proxy.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC1967Utils } from '@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol';

interface IHasUpgradeAndCall {

    /// @dev See {UUPSUpgradeable-upgradeToAndCall}
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

interface IHasERC1967Implementation {

    function ERC1967_implementation() external view returns (address);
}

// Note: `Warning: This contract has a payable fallback function, but no receive ether function. Consider adding a receive ether function.`
// This isn't a problem, the payable fallback is by design and works
// But there's no way of easily silencing the warning.

/// @dev storage slot 0 is special as it's used by Ownable for the owner address
contract AtomicProxy is Ownable, Proxy {

    /**
     * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
     */
    error ProxyDeniedAdminAccess();

    constructor(address owner)
        Ownable(owner)
    {
        // Does nothing, this is a placeholder
        // real owner must upgrade with implementation + initialization data
    }

    function _fallback()
        internal
        virtual override
    {
        if (msg.sender == owner() && msg.sig == IHasUpgradeAndCall.upgradeToAndCall.selector)
        {
            (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));

            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        }
        else {
            super._fallback();
        }
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation()
        internal view
        virtual override
        returns (address)
    {
        return ERC1967Utils.getImplementation();
    }

    function ERC1967_implementation()
        external view
        returns (address)
    {
        return _implementation();
    }
}
