// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IAtomicProxyFactory {

    event ProxyDeployed(address proxy, address initialOwner);

    function getProxyAddress(address creator, string memory name) external view returns (address);

    function deployProxy(string memory name) external returns (address);

    function computeProxyAddress(address creator, string memory name) external view returns (address);
}
