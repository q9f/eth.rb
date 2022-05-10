// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

library LibBytes {
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    index += 32;
    require(b.length >= index);
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }
}

contract Signer {
  using LibBytes for bytes;
  address constant internal OWNER = 0xd5732335EB868F17B750B29fF4097987DF8D0D35;
  bytes4 constant internal MAGIC_VALUE = 0x1626ba7e;

  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature
  )
    external
    pure
    returns (bytes4)
  {
    if (recoverSigner(_hash, _signature) == OWNER) {
      return MAGIC_VALUE;
    } else {
      return 0xffffffff;
    }
  }

  function recoverSigner(
    bytes32 _hash,
    bytes memory _signature
  )
    internal
    pure
    returns (address signer)
  {
    require(_signature.length == 65);
    uint8 v = uint8(_signature[64]);
    bytes32 r = _signature.readBytes32(0);
    bytes32 s = _signature.readBytes32(32);
    signer = ecrecover(_hash, v, r, s);
    return signer;
  }
}
