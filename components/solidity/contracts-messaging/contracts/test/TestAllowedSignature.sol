// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IAllowedSigner } from '../IAllowedSigner.sol';

contract TestAllowedSigner is IAllowedSigner {

    mapping(address => bool) allowedSigners;

    function addSigner (address signer)
        external
    {
        allowedSigners[signer] = true;
    }

    function isSignerAllowed(address x)
        external view
        returns (bool)
    {
        return allowedSigners[x];
    }
}
