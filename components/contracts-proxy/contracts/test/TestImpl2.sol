// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

contract TestImpl2 {

    event EventTwo(bytes32 data);

    function twoFunction (bytes32 arg)
        public
    {
        emit EventTwo(arg);
    }

    function twoViewFunction ()
        public pure
        returns (uint)
    {
        return 456;
    }
}
