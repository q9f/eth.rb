// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

contract Tuple2 {
    struct  Nar {
        Nuu nuu;
    }

    struct Nuu {
        Foo foo;
    }

    struct Foo {
        string id;
        string name;
    }

    struct  Bar {
        uint256 id;
        uint256 data;
    }

    function idNarBarFooNarFooArrays(Nar[3] calldata var1, Bar[] calldata  var2, Foo[] calldata  var3, Nar[] calldata  var4, Foo[3] calldata  var5) public {
    }
}
