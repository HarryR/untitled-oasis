// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC20, ERC1363 } from '@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';

import { IBridgeToken } from './IBridgeToken.sol';

contract BridgeToken is Ownable, ERC1363, IBridgeToken {

    error NotTheBridgeError();

    struct State {
        address bridge;
    }

    constructor (address in_bridge)
        ERC20("Oasis ROSE", "ROSE")
        Ownable(msg.sender)
    {
        State storage state = internal_getState();

        state.bridge = in_bridge;
    }

    function onlyOwner_setBridge(address in_bridge)
        external
        onlyOwner
    {
        State storage state = internal_getState();

        state.bridge = in_bridge;
    }

    function internal_getState()
        internal pure
        returns (State storage state)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("C3NS2PPSXU5XTHEH7JZVF7MC2N6ZF");

        assembly {
            state.slot := x
        }
    }

    function getBridgeAddress()
        public view
        returns (address)
    {
        return internal_getState().bridge;
    }

    function bridge_mint(address recipient, uint amount)
        external
    {
        require( msg.sender == getBridgeAddress(),
            NotTheBridgeError() );

        _mint(recipient, amount);
    }

    function bridge_burn(address owner, uint amount)
        external
    {
        require( msg.sender == getBridgeAddress(),
            NotTheBridgeError() );

        _burn(owner, amount);
    }
}
