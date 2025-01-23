// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';

import { PackedOrigin, MessageOrigin, MessageOriginLibrary } from './lib/MessageOrigin.sol';

contract MessageEmitter {

    using MessageOriginLibrary for MessageOrigin;

    event OnMessage(PackedOrigin packedOrigin, bytes message);

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

        (bytes32 messageId, PackedOrigin memory packedOrigin) = MessageOrigin({
            emitterContract: address(this),
            sequence: state.sequence,
            srcChainId: uint32(block.chainid),
            timestamp: uint32(block.timestamp),
            sender: msg.sender
        }).hash(message);

        emit OnMessage(packedOrigin, message);

        return messageId;
    }
}
