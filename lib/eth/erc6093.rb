# Copyright (c) 2016-2025 The Ruby-Eth Contributors
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

  # Defines custom errors for ERC standard smart contracts as defined in ERC-6093.
  # Ref: https://eips.ethereum.org/EIPS/eip-6093
  module Erc6093

    # Erc20InsufficientBalance(address sender, uint256 balance, uint256 needed)
    class Erc20InsufficientBalance < StandardError; end

    # Erc20InvalidSender(address sender)
    class Erc20InvalidSender < StandardError; end

    # Erc20InvalidReceiver(address receiver)
    class Erc20InvalidReceiver < StandardError; end

    # Erc20InsufficientAllowance(address spender, uint256 allowance, uint256 needed)
    class Erc20InsufficientAllowance < StandardError; end

    # Erc20InvalidApprover(address approver)
    class Erc20InvalidApprover < StandardError; end

    # Erc20InvalidSpender(address spender)
    class Erc20InvalidSpender < StandardError; end

    # Erc721InvalidOwner(address owner)
    class Erc721InvalidOwner < StandardError; end

    # Erc721NonexistentToken(uint256 tokenId)
    class Erc721NonexistentToken < StandardError; end

    # Erc721IncorrectOwner(address sender, uint256 tokenId, address owner)
    class Erc721IncorrectOwner < StandardError; end

    # Erc721InvalidSender(address sender)
    class Erc721InvalidSender < StandardError; end

    # Erc721InvalidReceiver(address receiver)
    class Erc721InvalidReceiver < StandardError; end

    # Erc721InsufficientApproval(address operator, uint256 tokenId)
    class Erc721InsufficientApproval < StandardError; end

    # Erc721InvalidApprover(address approver)
    class Erc721InvalidApprover < StandardError; end

    # Erc721InvalidOperator(address operator)
    class Erc721InvalidOperator < StandardError; end

    # Erc1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId)
    class Erc1155InsufficientBalance < StandardError; end

    # Erc1155InvalidSender(address sender)
    class Erc1155InvalidSender < StandardError; end

    # Erc1155InvalidReceiver(address receiver)
    class Erc1155InvalidReceiver < StandardError; end

    # Erc1155MissingApprovalForAll(address operator, address owner)
    class Erc1155MissingApprovalForAll < StandardError; end

    # Erc1155InvalidApprover(address approver)
    class Erc1155InvalidApprover < StandardError; end

    # Erc1155InvalidOperator(address operator)
    class Erc1155InvalidOperator < StandardError; end

    # Erc1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength)
    class Erc1155InvalidArrayLength < StandardError; end
  end
end
