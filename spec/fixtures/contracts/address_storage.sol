// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

contract AddressStorage {

  address myAddress;
  address[] myArray;

  function storeMyAddress(address addr) public {
    myAddress = addr;
  }

  function storeMyArray(address[] memory array) public {
    myArray = array;
  }

  function retrieveMyAddress() public view returns (address){
    return myAddress;
  }

  function retrieveMyArray(uint256 index) public view returns (address){
    return myArray[index];
  }
}
