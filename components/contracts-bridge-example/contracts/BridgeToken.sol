// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ERC20, ERC1363 } from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';

import { IBridgeToken } from './IBridgeToken.sol';

contract BridgeToken is ERC1363, IBridgeToken {

    constructor ()
        ERC20("Oasis ROSE", "ROSE")
    { }

    function bridge_mint(address recipient, uint amount)
        external
    {
        _mint(recipient, amount);
    }

    function bridge_burn(address owner, uint amount)
        external
    {
        _burn(owner, amount);
    }
}
