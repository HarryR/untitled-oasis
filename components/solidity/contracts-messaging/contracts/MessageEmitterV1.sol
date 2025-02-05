// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SlotDerivation } from '@openzeppelin/contracts/utils/SlotDerivation.sol';

import { MessageOriginV1Library, MessageOriginV1, PackedOrigin } from './lib/MessageOriginV1.sol';
import { MessageDecoderV1 } from './MessageDecoderV1.sol';
import { IEmitter } from './IEmitter.sol';

contract MessageEmitterV1 is IEmitter {

    using MessageOriginV1Library for MessageOriginV1;
    using MessageOriginV1Library for PackedOrigin;

    event OnMessage(bytes32 messageId, bytes packedOriginAndMessage);

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

    MessageDecoderV1 public immutable decoder;

    constructor(MessageDecoderV1 in_decoder)
    {
        decoder = in_decoder;
    }

    function decodeSigned(bytes calldata data)
        external view
        returns (
            bytes32 messageId,
            MessageOriginV1 memory origin,
            bytes memory message,
            address[] memory signers
    ) {
        return decoder.decodeSigned(data);
    }

    function send(
        bytes memory message,
        uint8 validAfterNBlocks,
        uint16 validAfterNSeconds
    )
        external
        returns (bytes32)
    {
        State storage state = _getState();

        state.sequence += 1;

        bytes32 messageId;

        PackedOrigin memory packedOrigin;

        (messageId, packedOrigin) = MessageOriginV1({
            // 256 bits
            emitterContract: address(this),
            validAfterNBlocks: validAfterNBlocks,
            validAfterNSeconds: validAfterNSeconds,
            blockHeight: uint32(block.number),
            a_reserved: 0,
            messageVersion: uint8(1),

            // 256 bits
            sequence: state.sequence,
            srcChainId: uint32(block.chainid),
            timestamp: uint32(block.timestamp),
            sender: msg.sender
        }).hash(message);

        emit OnMessage(
                messageId,
                abi.encodePacked(packedOrigin.a, packedOrigin.b, message));

        return messageId;
    }
}
