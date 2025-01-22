// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// Fits into a 256bit word
struct MessageOrigin {
    uint32 sequence;
    uint32 srcChainId;
    uint32 timestamp;
    address sender;
}

library MessageOriginLibrary {

    function hash(
        address emitterContract,
        uint256 packedOrigin,
        bytes32 messageHash
    )
        internal pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(emitterContract, packedOrigin, messageHash));
    }

    function hash(
        address emitterContract,
        uint256 packedOrigin,
        bytes memory message
    )
        internal pure
        returns (bytes32)
    {
        return hash(emitterContract, packedOrigin, keccak256(message));
    }

    function hash(
        MessageOrigin memory self,
        address emitterContract,
        bytes memory message
    )
        internal pure
        returns (bytes32 messageId, uint256 packedOrigin)
    {
        packedOrigin = pack(self);

        messageId = hash(emitterContract, packedOrigin, message);
    }

    function pack(MessageOrigin memory self)
        internal pure
        returns (uint256)
    {
        return uint256(self.sequence)
            | (uint256(self.srcChainId) << 32)
            | (uint256(self.timestamp) << 64)
            | (uint256(uint160(self.sender)) << 96);
    }

    function unpack(uint256 packed)
        internal pure
        returns (MessageOrigin memory)
    {
        return MessageOrigin({
            sequence: uint32(packed),
            srcChainId: uint32(packed >> 32),
            timestamp: uint32(packed >> 64),
            sender: address(uint160(packed >> 96))
        });
    }
}
