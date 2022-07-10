// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

contract Tuple {
    struct Tuple1 {
        string var1;
        string var2;
        Tuple2[] var3;
        uint256 var4;
        string[] var5;
        bytes[10] var6;
        Tuple3 var7;
    }

    struct Tuple2 {
        uint var1;
        string var2;
        Tuple3 var3;
    }

    struct Tuple3 {
        string var1;
        bytes var2;
    }

    function func1(Tuple1 calldata param1) public {}
}
