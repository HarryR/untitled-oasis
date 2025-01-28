// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Library for handling cross-chain message origins with efficient storage and hashing
 * @dev Provides functionality to pack, unpack, and hash message origin data
 *
 * @dev Usage:
 * ```solidity
 * using MessageOriginV1 for MessageOriginV1.Struct;
 * using MessageOriginV1 for MessageOriginV1.PackedStruct;
 * ```
 */
library MessageOriginV1 {
    /**
     * @notice Data structure representing the origin of a cross-chain message
     * @dev This struct is designed to be packed efficiently into two 256-bit words
     */
    struct Struct {
        // a [ First into a 256bit word
        address emitterContract;    // MessageEmitter contract address
        uint8 validAfterNBlocks;    // Number of blocks after mining that message will be considered valid
        uint16 validAfterNSeconds;  // Number of seconds after timestamp that message will be signed
        uint32 blockHeight;
        uint32 a_reserved;
        uint8 messageVersion;
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
    struct Packed {
        uint256 a;
        uint256 b;
    }

    /**
     * @notice Generates a unique hash for a packed origin and message hash
     * @param packedOrigin The packed origin data
     * @param messageHash The hash of the message content
     * @return The combined hash of origin and message
     */
    function hash(
        Packed memory packedOrigin,
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
        Packed memory packedOrigin,
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
        Struct memory self,
        bytes memory message
    )
        internal pure
        returns (bytes32 messageId, Packed memory packedOrigin)
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
    function pack(Struct memory self)
        internal pure
        returns (Packed memory)
    {
        return Packed({
            a: uint256(uint160(self.emitterContract))
             | uint256(self.validAfterNBlocks) << 160
             | uint256(self.validAfterNSeconds) << 168
             | uint256(self.blockHeight) << 184
             | uint256(self.a_reserved) << 216
             | uint256(self.messageVersion) << 248
             ,
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
    function unpack(Packed memory packed)
        internal pure
        returns (Struct memory)
    {
        uint256 a = packed.a;
        uint256 b = packed.b;

        return Struct({
            // a = 256 bits
            emitterContract: address(uint160(a)),
            validAfterNBlocks: uint8(a >> 160),
            validAfterNSeconds: uint16(a >> 168),
            blockHeight: uint32(a >> 184),
            a_reserved: uint32(a >> 216),
            messageVersion: uint8(a >> 248),

            // b = 256 bits
            sequence: uint32(b),                // + 32  = 32
            srcChainId: uint32(b >> 32),        // + 32  = 64
            timestamp: uint32(b >> 64),         // + 32  = 96
            sender: address(uint160(b >> 96))   // + 160 = 256
        });
    }
}
