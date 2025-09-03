# frozen_string_literal: true

require "bls"

module Eth
  # Helper methods for interacting with BLS12-381 points and signatures
  module Bls
    module_function

    # Decode a compressed G1 public key from hex.
    # @param [String] hex a compressed G1 point
    # @return [BLS::PointG1]
    def decode_public_key(hex)
      BLS::PointG1.from_hex Util.remove_hex_prefix(hex)
    end

    # Encode a G1 public key to compressed hex.
    # @param [BLS::PointG1] point
    # @return [String] hex string prefixed with 0x
    def encode_public_key(point)
      Util.prefix_hex point.to_hex(compressed: true)
    end

    # Decode a compressed G2 signature from hex.
    # @param [String] hex a compressed G2 point
    # @return [BLS::PointG2]
    def decode_signature(hex)
      BLS::PointG2.from_hex Util.remove_hex_prefix(hex)
    end

    # Encode a G2 signature to compressed hex.
    # @param [BLS::PointG2] point
    # @return [String] hex string prefixed with 0x
    def encode_signature(point)
      Util.prefix_hex point.to_hex(compressed: true)
    end

    # Derive a compressed public key from a private key.
    # @param [String] priv_hex private key as hex
    # @return [String] compressed G1 public key (hex)
    def get_public_key(priv_hex)
      key = BLS.get_public_key Util.remove_hex_prefix(priv_hex)
      encode_public_key key
    end

    # Sign a message digest with the given private key.
    # @param [String] message message digest (hex)
    # @param [String] priv_hex private key as hex
    # @return [String] compressed G2 signature (hex)
    def sign(message, priv_hex)
      sig = BLS.sign Util.remove_hex_prefix(message),
                     Util.remove_hex_prefix(priv_hex)
      encode_signature sig
    end

    # Verify a BLS signature using pairings. This mirrors the behaviour of
    # the BLS12-381 pairing precompile.
    # @param [String] message message digest (hex)
    # @param [String] signature_hex compressed G2 signature (hex)
    # @param [String] pubkey_hex compressed G1 public key (hex)
    # @return [Boolean] verification result
    def verify(message, signature_hex, pubkey_hex)
      signature = decode_signature(signature_hex)
      pubkey = decode_public_key(pubkey_hex)
      BLS.verify(signature, Util.remove_hex_prefix(message), pubkey)
    end
  end
end
