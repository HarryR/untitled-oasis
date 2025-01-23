// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Data structure representing the origin of a cross-chain message
 * @dev This struct is designed to be packed efficiently into two 256-bit words
 */
struct MessageOrigin {
    // a [
    address emitterContract;
    //      12 bytes remaining
    // ]

    // b [ Fits into a 256bit word
    uint32 sequence;
    uint32 srcChainId;
    uint32 timestamp;
    address sender;
    // ]
}

/**
 * @notice Optimized storage format for MessageOrigin
 * @dev Packs all MessageOrigin fields into two 256-bit words for gas efficiency
 */
struct PackedOrigin {
    uint256 a;
    uint256 b;
}

/**
 * @title MessageOriginLibrary
 * @notice Library for handling cross-chain message origins with efficient storage and hashing
 * @dev Provides functionality to pack, unpack, and hash message origin data
 *
 * @dev Usage:
 * ```solidity
 * using MessageOriginLibrary for MessageOrigin;
 * using MessageOriginLibrary for PackedOrigin;
 * ```
 */
library MessageOriginLibrary {

    /**
     * @notice Generates a unique hash for a packed origin and message hash
     * @param packedOrigin The packed origin data
     * @param messageHash The hash of the message content
     * @return The combined hash of origin and message
     */
    function hash(
        PackedOrigin memory packedOrigin,
        bytes32 messageHash
    )
        internal pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            packedOrigin.a,
            packedOrigin.b,
            messageHash));
    }

    /**
     * @notice Generates a unique hash for a packed origin and message
     * @param packedOrigin The packed origin data
     * @param message The raw message content
     * @return The combined hash of origin and message
     */
    function hash(
        PackedOrigin memory packedOrigin,
        bytes memory message
    )
        internal pure
        returns (bytes32)
    {
        return hash(packedOrigin, keccak256(message));
    }

    /**
     * @notice Generates a unique hash for a message origin and message content
     * @param self The message origin data
     * @param message The raw message content
     * @return messageId The unique identifier for this message
     * @return packedOrigin The packed version of the origin data
     */
    function hash(
        MessageOrigin memory self,
        bytes memory message
    )
        internal pure
        returns (bytes32 messageId, PackedOrigin memory packedOrigin)
    {
        packedOrigin = pack(self);

        messageId = hash(packedOrigin, message);
    }

    /**
     * @notice Packs a MessageOrigin struct into an optimized storage format
     * @dev Combines multiple fields into two 256-bit words using bit operations
     * @param self The message origin to pack
     * @return A PackedOrigin containing the same data in an optimized format
     */
    function pack(MessageOrigin memory self)
        internal pure
        returns (PackedOrigin memory)
    {
        return PackedOrigin({
            a: uint160(self.emitterContract),
            b: uint256(self.sequence)
               | (uint256(self.srcChainId) << 32)
               | (uint256(self.timestamp) << 64)
               | (uint256(uint160(self.sender)) << 96)
        });
    }

    /**
     * @notice Unpacks a PackedOrigin back into a MessageOrigin struct
     * @dev Extracts individual fields using bit operations
     * @param packed The packed origin data
     * @return The unpacked MessageOrigin struct
     */
    function unpack(PackedOrigin memory packed)
        internal pure
        returns (MessageOrigin memory)
    {
        uint256 a = packed.a;
        uint256 b = packed.b;

        return MessageOrigin({
            emitterContract: address(uint160(a)),

            sequence: uint32(b),
            srcChainId: uint32(b >> 32),
            timestamp: uint32(b >> 64),
            sender: address(uint160(b >> 96))
        });
    }
}
