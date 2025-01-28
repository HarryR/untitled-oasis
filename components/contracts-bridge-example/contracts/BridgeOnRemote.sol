// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';

import { IBridgeToken } from './IBridgeToken.sol';
import { CommonEndpoint } from './CommonEndpoint.sol';

contract BridgeOnRemote is CommonEndpoint {

    constructor()
        CommonEndpoint()
    { }

    struct State {
        IBridgeToken token;
    }

    function internal_getState()
        internal pure
        returns (State storage state)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("AQUYHDTSNGSONIFJ56ATHU2UXCGOQ");

        assembly {
            state.slot := x
        }
    }

    function initialize(
        IBridgeToken in_token,
        address in_owner,
        Settings memory in_settings
    )
        initializer
        external
    {
        common_initialize(in_owner, in_settings);

        State storage state = internal_getState();

        state.token = in_token;
    }

    function sendTokensToRemoteChain(
        uint32 destChainId,
        address recipient,
        uint amount
    )
        public
        payable
    {
        IBridgeToken token = internal_getState().token;

        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

        (address feeCollector, uint fee) = common_sendTokensToRemoteChain(destChainId, recipient, amount);

        SafeERC20.safeTransfer(token, feeCollector, fee);
    }

    function receiveTokensFromRemoteChain(bytes calldata data)
        public
    {
        (address recipient, uint amount) = common_receiveTokensFromRemoteChain(data);

        SafeERC20.safeTransfer(internal_getState().token, recipient, amount);
    }
}
