// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

contract Dummy {
  uint number;
  function set(uint x) public {
    number = x;
  }

  function get() public view returns (uint) {
    return number;
  }
}
