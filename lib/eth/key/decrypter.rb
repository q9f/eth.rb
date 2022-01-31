# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Provides the {Eth} module.
module Eth

  # The {Eth::Key::Decrypter} class to handle PBKDF2-SHA-256 decryption.
  class Key::Decrypter

    # Provides a specific decrypter error if decryption fails.
    class DecrypterError < StandardError; end

    # Class method {Eth::Key::Decrypter.perform} to perform an keystore
    # decryption.
    #
    # @param data [JSON] encryption data including cypherkey.
    # @param password [String] password to decrypt the key.
    # @return [Eth::Key] decrypted key-pair.
    def self.perform(data, password)
      new(data, password).perform
    end

    # Constructor of the {Eth::Key::Decrypter} class for secret key
    # decryption. Should not be used; use {Eth::Key::Decrypter.perform}
    # instead.
    #
    # @param data [JSON] encryption data including cypherkey.
    # @param password [String] password to decrypt the key.
    def initialize(data, password)
      data = JSON.parse(data) if data.is_a? String
      @data = data
      @password = password
    end

    # Method to decrypt key using password.
    #
    # @return [Eth::Key] decrypted key.
    def perform
      derive_key password
      check_macs
      private_key = Util.bin_to_hex decrypted_data
      Eth::Key.new priv: private_key
    end

    private

    attr_reader :data
    attr_reader :key
    attr_reader :password

    def derive_key(password)
      case kdf
      when "pbkdf2"
        @key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, key_length, digest)
      when "scrypt"
        @key = SCrypt::Engine.scrypt(password, salt, n, r, p, key_length)
      else
        raise DecrypterError, "Unsupported key derivation function: #{kdf}!"
      end
    end

    def check_macs
      mac1 = Util.keccak256(key[(key_length / 2), key_length] + ciphertext)
      mac2 = Util.hex_to_bin crypto_data["mac"]

      if mac1 != mac2
        raise DecrypterError, "Message Authentications Codes do not match!"
      end
    end

    def decrypted_data
      @decrypted_data ||= cipher.update(ciphertext) + cipher.final
    end

    def crypto_data
      @crypto_data ||= data["crypto"] || data["Crypto"]
    end

    def ciphertext
      Util.hex_to_bin crypto_data["ciphertext"]
    end

    def cipher_name
      "aes-128-ctr"
    end

    def cipher
      @cipher ||= OpenSSL::Cipher.new(cipher_name).tap do |cipher|
        cipher.decrypt
        cipher.key = key[0, (key_length / 2)]
        cipher.iv = iv
      end
    end

    def iv
      Util.hex_to_bin crypto_data["cipherparams"]["iv"]
    end

    def salt
      Util.hex_to_bin crypto_data["kdfparams"]["salt"]
    end

    def iterations
      crypto_data["kdfparams"]["c"].to_i
    end

    def kdf
      crypto_data["kdf"]
    end

    def key_length
      crypto_data["kdfparams"]["dklen"].to_i
    end

    def n
      crypto_data["kdfparams"]["n"].to_i
    end

    def r
      crypto_data["kdfparams"]["r"].to_i
    end

    def p
      crypto_data["kdfparams"]["p"].to_i
    end

    def digest
      OpenSSL::Digest.new digest_name
    end

    def digest_name
      "sha256"
    end
  end
end
