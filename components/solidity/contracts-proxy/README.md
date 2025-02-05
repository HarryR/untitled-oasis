# Proxy Deployment Pattern

The proxy deployment factory pattern is similar to the OpenZeppelin `TransparentUpgradeableProxy`, but is designed to be used together with CreateX and contracts that inherit `Ownable`.

The proxy factory creates proxies with deterministic addresses based on a salt and the person calling `deployProxy`. Because the deterministic address doesn't depend on the contract being deployed or passing special arguments directly to CreateX, this maintains a clear separation between deployment accounts & management accounts.

The proxy factory has the following interface:

```solidity
interface IAtomicProxyFactory {
    function getProxyAddress(bytes32 salt, address admin) external view returns (address);

    function deployProxy(bytes32 salt) external returns (address);

    function computeProxyAddress(bytes32 salt, address admin) public view returns (address);
}
```

The created proxies have the following interface:

```solidity
interface IHasUpgradeAndCall {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

interface IHasERC1967Implementation {
    function ERC1967_implementation() external view returns (address);
}
```

It doesn't rely on `eth_getStorageAt` to get the implementation address, as there's the `ERC1967_implementation` method.

The owner is allowed to call `upgradeToAndCall`, if the implementation is borked then, assuming `owner` doesn't change, they can call `upgradeToAndCall` even if the proxy is in an uninitialized state.