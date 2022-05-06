// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

contract TestContract {

    address payable public owner;

    constructor(string memory title) {
        owner = payable(msg.sender);
    }

    function kill() public {
        if (msg.sender == owner) {
            selfdestruct(owner);
            emit killed();
        }
    }

    mapping(bytes32 => bytes32) public signatures;

    function set(bytes32 id, bytes32 sig) public {
      require(msg.sender == owner);
      signatures[id] = sig;
      emit changed();
    }

    function get(bytes32 id) public view returns (bytes32, string memory) {
        return (signatures[id], "hello");
    }

    function unset(bytes32 id) public {
        require(msg.sender == owner);
        signatures[id] = bytes32(0x0);
    }

    event changed();
    event killed();
}
