// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

struct BridgeTransferMessage {
    uint32 destChainId;
    uint256 amount;
    address recipient;
}
