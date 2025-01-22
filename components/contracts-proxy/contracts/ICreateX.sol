// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface ICreateX {

    function deployCreate2(bytes32 salt, bytes memory initCode) external payable returns (address deployed);

    function computeCreate2Address(bytes32 salt, bytes32 initCodeHash, address deployer) external pure returns (address);
}
