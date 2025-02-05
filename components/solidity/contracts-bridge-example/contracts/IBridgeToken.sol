// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface IBridgeToken is IERC20 {

    function bridge_mint(address recipient, uint amount) external;

    function bridge_burn(address owner, uint amount) external;
}
