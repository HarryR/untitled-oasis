// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';

import { MessageOrigin, MessageOriginLibrary } from './lib/MessageOrigin.sol';

contract MessageEmitter {

    using MessageOriginLibrary for MessageOrigin;

    event OnMessage(uint256 packedOrigin, bytes message);

    struct State {
        uint32 sequence;
    }

    function _getState()
        private pure
        returns (State storage state)
    {
        // Randomly chosen, b32encode(urandom(20))[:29]
        bytes32 x = SlotDerivation.erc7201Slot("7IJPCPEPFISV5WC5LUPGRMCTC7A5Z");

        assembly {
            state.slot := x
        }
    }

    constructor()
    {
        // Does nothing, no state initialization is necessary
    }

    function send(bytes memory message)
        external
        returns (bytes32)
    {
        State storage state = _getState();

        state.sequence += 1;

        (bytes32 messageId, uint256 packedOrigin) = MessageOrigin({
            sequence: state.sequence,
            srcChainId: uint32(block.chainid),
            timestamp: uint32(block.timestamp),
            sender: msg.sender
        }).hash(address(this), message);

        emit OnMessage(packedOrigin, message);

        return messageId;
    }
}
