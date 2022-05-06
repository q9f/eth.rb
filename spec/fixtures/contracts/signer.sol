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
  address constant internal OWNER = 0xCaA29806044A08E533963b2e573C1230A2cd9a2d;
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
    signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s);
    return signer;
  }
}
