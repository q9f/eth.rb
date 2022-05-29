// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

contract Mortal {

  // defines the owner of type payable address
  address payable owner;

  // initializes the contract and sets the owner
  constructor() {
    owner = payable(msg.sender);
  }

  // destroys the contract and recovers the funds
  function kill() public {
    if (msg.sender == owner) {
      selfdestruct(owner);
    }
  }
}

contract Greeter is Mortal {

  // defines the greeting of type string
  string greeting;

  // creates a greeter-contract with the given message
  constructor(string memory message) {
    greeting = message;
  }

  function setGreeting(string memory message) public {
    greeting =  message;
  }

  // call the greeting from the contract
  function greet() public view returns (string memory) {
    return greeting;
  }
}
