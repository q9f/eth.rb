// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

contract SimpleRegistry {
  uint number1;
  uint number2;

  function set(uint x, uint y) public {
    number1 = x;
    number2 = y;
  }

  function get() public view returns (uint, uint) {
    return (number1, number2);
  }
}
