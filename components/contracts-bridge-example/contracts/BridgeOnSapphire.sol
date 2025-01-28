// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Address } from '@openzeppelin/contracts/utils/Address.sol';

import { CommonEndpoint } from './CommonEndpoint.sol';

contract BridgeOnSapphire is CommonEndpoint {

    constructor()
        CommonEndpoint()
    { }

    function initialize(address in_owner, Settings memory in_settings)
        initializer
        external
    {
        common_initialize(in_owner, in_settings);
    }

    function sendTokensToRemoteChain(
        uint32 destChainId,
        address recipient
    )
        public
        payable
    {
        (address feeCollector, uint fee) = common_sendTokensToRemoteChain(destChainId, recipient, msg.value);

        Address.sendValue(payable(feeCollector), fee);
    }

    function receiveTokensFromRemoteChain(bytes calldata data)
        public
    {
        (address recipient, uint amount) = common_receiveTokensFromRemoteChain(data);

        Address.sendValue(payable(recipient), amount);
    }
}
