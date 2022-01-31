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

  # The {Eth::Key::Encrypter} class to handle PBKDF2-SHA-256 encryption.
  class Key::Encrypter

    # Provides a specific encrypter error if decryption fails.
    class EncrypterError < StandardError; end

    # Class method {Eth::Key::Encrypter.perform} to performa an key-store
    # encryption.
    #
    # @param key [Eth::Key] representing a secret key-pair used for encryption.
    # @param options [Hash] the options to encrypt with.
    # @option options [String] :kdf key derivation function defaults to pbkdf2.
    # @option options [String] :id uuid given to the secret key.
    # @option options [String] :iterations number of iterations for the hash function.
    # @option options [String] :salt passed to PBKDF.
    # @option options [String] :iv 128-bit initialisation vector for the cipher.
    # @option options [Integer] :parallelization parallelization factor for scrypt, defaults to 8.
    # @option options [Integer] :block_size for scrypt, defaults to 1.
    # @return [JSON] formatted with encrypted key (cyphertext) and [other identifying data](https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition#pbkdf2-sha-256).
    def self.perform(key, password, options = {})
      new(key, options).perform(password)
    end

    # Constructor of the {Eth::Key::Encrypter} class for secret key
    # encryption. Should not be used; use {Eth::Key::Encrypter.perform}
    # instead.
    #
    # @param key [Eth::Key] representing a secret key-pair used for encryption.
    # @param options [Hash] the options to encrypt with.
    # @option options [String] :kdf key derivation function defaults to pbkdf2.
    # @option options [String] :id uuid given to the secret key.
    # @option options [String] :iterations number of iterations for the hash function.
    # @option options [String] :salt passed to PBKDF.
    # @option options [String] :iv 128-bit initialisation vector for the cipher.
    # @option options [Integer] :parallelization parallelization factor for scrypt, defaults to 8.
    # @option options [Integer] :block_size for scrypt, defaults to 1.
    def initialize(key, options = {})
      key = Key.new(priv: key) if key.is_a? String
      @key = key
      @options = options

      # the key derivation functions default to pbkdf2 if no option is specified
      # however, if an option is given then it must be either pbkdf2 or scrypt
      if kdf != "scrypt" && kdf != "pbkdf2"
        raise EncrypterError, "Unsupported key derivation function: #{kdf}!"
      end
    end

    # Encrypt the key with a given password.
    #
    # @param password [String] a secret key used for encryption
    # @return [String] a JSON-formatted keystore string.
    def perform(password)
      derive_key password
      encrypt
      data.to_json
    end

    # Output containing the encrypted key and
    # [other identifying data](https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition#pbkdf2-sha-256)
    #
    # @return [Hash] the encrypted keystore data.
    def data
      # default to pbkdf2
      kdfparams = if kdf == "scrypt"
          {
            dklen: 32,
            n: iterations,
            p: parallelization,
            r: block_size,
            salt: Util.bin_to_hex(salt),
          }
        else
          {
            c: iterations,
            dklen: 32,
            prf: prf,
            salt: Util.bin_to_hex(salt),
          }
        end

      {
        crypto: {
          cipher: cipher_name,
          cipherparams: {
            iv: Util.bin_to_hex(iv),
          },
          ciphertext: Util.bin_to_hex(encrypted_key),
          kdf: kdf,
          kdfparams: kdfparams,
          mac: Util.bin_to_hex(mac),
        },
        id: id,
        version: 3,
      }
    end

    private

    attr_reader :derived_key, :encrypted_key, :key, :options

    def cipher
      @cipher ||= OpenSSL::Cipher.new(cipher_name).tap do |cipher|
        cipher.encrypt
        cipher.iv = iv
        cipher.key = derived_key[0, (key_length / 2)]
      end
    end

    def digest
      @digest ||= OpenSSL::Digest.new digest_name
    end

    def derive_key(password)
      if kdf == "scrypt"
        @derived_key = SCrypt::Engine.scrypt(password, salt, iterations, block_size, parallelization, key_length)
      else
        @derived_key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, key_length, digest)
      end
    end

    def encrypt
      @encrypted_key = cipher.update(Util.hex_to_bin key.private_hex) + cipher.final
    end

    def mac
      Util.keccak256(derived_key[(key_length / 2), key_length] + encrypted_key)
    end

    def kdf
      options[:kdf] || "pbkdf2"
    end

    def cipher_name
      "aes-128-ctr"
    end

    def digest_name
      "sha256"
    end

    def prf
      "hmac-#{digest_name}"
    end

    def key_length
      32
    end

    def salt_length
      32
    end

    def iv_length
      16
    end

    def id
      @id ||= options[:id] || SecureRandom.uuid
    end

    def iterations
      options[:iterations] || 262_144
    end

    def salt
      @salt ||= if options[:salt]
          Util.hex_to_bin options[:salt]
        else
          SecureRandom.random_bytes(salt_length)
        end
    end

    def iv
      @iv ||= if options[:iv]
          Util.hex_to_bin options[:iv]
        else
          SecureRandom.random_bytes(iv_length)
        end
    end

    def parallelization
      options[:parallelization] || 8
    end

    def block_size
      options[:block_size] || 1
    end
  end
end
