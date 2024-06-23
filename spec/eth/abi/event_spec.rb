# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Event do
  let(:erc20_abi_file) { File.read "spec/fixtures/abi/ERC20.json" }
  subject(:erc20_abi) { JSON.parse erc20_abi_file }

  let(:erc721_abi_file) { File.read "spec/fixtures/abi/ERC721.json" }
  subject(:erc721_abi) { JSON.parse erc721_abi_file }

  let(:erc1155_abi_file) { File.read "spec/fixtures/abi/ERC1155.json" }
  subject(:erc1155_abi) { JSON.parse erc1155_abi_file }

  describe ".compute_topic" do
    it "computes topic hash for event interfaces" do
      interface = erc20_abi.find { |i| i["type"] == "event" && i["name"] == "Transfer" }
      expect(Abi::Event.compute_topic(interface)).to eq "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

      interface = erc20_abi.find { |i| i["type"] == "event" && i["name"] == "Approval" }
      expect(Abi::Event.compute_topic(interface)).to eq "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"

      interface = erc721_abi.find { |i| i["type"] == "event" && i["name"] == "Transfer" }
      expect(Abi::Event.compute_topic(interface)).to eq "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

      interface = erc1155_abi.find { |i| i["type"] == "event" && i["name"] == "TransferSingle" }
      expect(Abi::Event.compute_topic(interface)).to eq "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62"
    end
  end

  describe ".decode_log" do
    it "can decode ERC-20 Transfer event" do
      interface = erc20_abi.find { |i| i["type"] == "event" && i["name"] == "Transfer" }

      log = {
        "address" => "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        "blockHash" => "0x41bbb59a6ae30e1e62379d100b0bc3485384843c51bad2c2f7a7a9b86848f19e",
        "blockNumber" => "0xddcb4d",
        "data" => "0x00000000000000000000000000000000000000000000000000000002540be400",
        "logIndex" => "0xcd",
        "removed" => false,
        "topics" => [
          "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
          "0x00000000000000000000000071660c4005ba85c37ccec55d0c4493e66fe775d3",
          "0x000000000000000000000000639671019ddd8ec28d35113d8d1c5f1bbfd7e0be",
        ],
        "transactionHash" => "0xcff6d58021eb9f743e29ca84cb94964332cc91babcc3533714d34264535ed3c5",
        "transactionIndex" => "0x8c",
      }

      args, kwargs = Abi::Event.decode_log(interface["inputs"], log["data"], log["topics"])

      expect(args[0]).to eq "0x71660c4005ba85c37ccec55d0c4493e66fe775d3"
      expect(args[1]).to eq "0x639671019ddd8ec28d35113d8d1c5f1bbfd7e0be"
      expect(args[2]).to eq 10000000000

      expect(kwargs[:from]).to eq "0x71660c4005ba85c37ccec55d0c4493e66fe775d3"
      expect(kwargs[:to]).to eq "0x639671019ddd8ec28d35113d8d1c5f1bbfd7e0be"
      expect(kwargs[:value]).to eq 10000000000
    end

    it "can decode ERC-20 Approval event" do
      interface = erc20_abi.find { |i| i["type"] == "event" && i["name"] == "Approval" }

      log = {
        "address" => "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        "blockHash" => "0x7461cf774021f421441df69bb1a04c66fac58fb72071c8286b2874d2e41ba448",
        "blockNumber" => "0xdcc880",
        "data" => "0x00000000000000000000000000000000000000000000000000000000aa3752a2",
        "logIndex" => "0xbc",
        "removed" => false,
        "topics" => [
          "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925",
          "0x0000000000000000000000007f8c1877ed0da352f78be4fe4cda58bb804a30df",
          "0x00000000000000000000000068b3465833fb72a70ecdf485e0e4c7bd8665fc45",
        ],
        "transactionHash" => "0xcbf51c188fb3d24760d083c6b53a4b604d2658321ef92cd48489ce3804b3de2b",
        "transactionIndex" => "0x78",
      }

      args, kwargs = Abi::Event.decode_log(interface["inputs"], log["data"], log["topics"])

      expect(args[0]).to eq "0x7f8c1877ed0da352f78be4fe4cda58bb804a30df"
      expect(args[1]).to eq "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45"
      expect(args[2]).to eq 2855752354

      expect(kwargs[:owner]).to eq "0x7f8c1877ed0da352f78be4fe4cda58bb804a30df"
      expect(kwargs[:spender]).to eq "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45"
      expect(kwargs[:value]).to eq 2855752354
    end

    it "can decode ERC-1155 TransferBatch event" do
      interface = erc1155_abi.find { |i| i["type"] == "event" && i["name"] == "TransferBatch" }

      log = {
        "address" => "0xfaafdc07907ff5120a76b34b731b278c38d6043c",
        "blockHash" => "0xd7d6e9481193043d27055e11f13d70fcc0dc280633119588d81c7af329f5acd7",
        "blockNumber" => "0x98b787",
        "data" => "0x0000000000000000000000000000000000000000000000000000000000000040" +
                  "00000000000000000000000000000000000000000000000000000000000000a0" +
                  "0000000000000000000000000000000000000000000000000000000000000002" +
                  "18000000000014f9000000000000000000000000000000000000000000000000" +
                  "300000000000028e000000000000000000000000000000000000000000000000" +
                  "0000000000000000000000000000000000000000000000000000000000000002" +
                  "0000000000000000000000000000000000000000000000000000000000000001" +
                  "0000000000000000000000000000000000000000000000000000000000000001",
        "logIndex" => "0x73",
        "removed" => false,
        "topics" => [
          "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb",
          "0x000000000000000000000000d7dd052ff73d9177f884592814f844a7788787d1",
          "0x000000000000000000000000d7dd052ff73d9177f884592814f844a7788787d1",
          "0x000000000000000000000000974efa242e2ce5282fe5d4379e4e9046bef70317",
        ],
        "transactionHash" => "0x54e20f60af57ed3240f039c29429427341092900347d1f003437ca23871176b8",
        "transactionIndex" => "0x3f",
      }

      args, kwargs = Abi::Event.decode_log(interface["inputs"], log["data"], log["topics"])

      expect(args[0]).to eq "0xd7dd052ff73d9177f884592814f844a7788787d1"
      expect(args[1]).to eq "0xd7dd052ff73d9177f884592814f844a7788787d1"
      expect(args[2]).to eq "0x974efa242e2ce5282fe5d4379e4e9046bef70317"
      expect(args[3]).to eq [
                              10855508365998427022718997135653512395597474264364790932245529828143155642368,
                              21711016731996790747144094632018202271094404902621441888338757680962283241472,
                            ]
      expect(args[4]).to eq [1, 1]

      expect(kwargs[:operator]).to eq "0xd7dd052ff73d9177f884592814f844a7788787d1"
      expect(kwargs[:from]).to eq "0xd7dd052ff73d9177f884592814f844a7788787d1"
      expect(kwargs[:to]).to eq "0x974efa242e2ce5282fe5d4379e4e9046bef70317"
      expect(kwargs[:ids]).to eq [
                                   10855508365998427022718997135653512395597474264364790932245529828143155642368,
                                   21711016731996790747144094632018202271094404902621441888338757680962283241472,
                                 ]
      expect(kwargs[:values]).to eq [1, 1]
    end
  end

  it "can decode anonymous Transfer event" do
    interface = {
      "type" => "event",
      "name" => "Transfer",
      "anonymous" => true,
      "inputs" => [
        { "indexed" => true, "internalType" => "address", "name" => "from", "type" => "address" },
        { "indexed" => true, "internalType" => "address", "name" => "to", "type" => "address" },
        { "indexed" => false, "internalType" => "uint256", "name" => "value", "type" => "uint256" },
      ],
    }

    data = "0x00000000000000000000000000000000000000000000000000000002540be400"
    topics = [
      "0x00000000000000000000000071660c4005ba85c37ccec55d0c4493e66fe775d3",
      "0x000000000000000000000000639671019ddd8ec28d35113d8d1c5f1bbfd7e0be",
    ]

    args, kwargs = Abi::Event.decode_log(interface["inputs"], data, topics, true)

    expect(args[0]).to eq "0x71660c4005ba85c37ccec55d0c4493e66fe775d3"
    expect(args[1]).to eq "0x639671019ddd8ec28d35113d8d1c5f1bbfd7e0be"
    expect(args[2]).to eq 10000000000

    expect(kwargs[:from]).to eq "0x71660c4005ba85c37ccec55d0c4493e66fe775d3"
    expect(kwargs[:to]).to eq "0x639671019ddd8ec28d35113d8d1c5f1bbfd7e0be"
    expect(kwargs[:value]).to eq 10000000000
  end

  describe ".decode_logs" do
    it "can decode ERC-20 Transfer event" do
      logs = [
        {
          "address" => "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "blockHash" => "0x41bbb59a6ae30e1e62379d100b0bc3485384843c51bad2c2f7a7a9b86848f19e",
          "blockNumber" => "0xddcb4d",
          "data" => "0x00000000000000000000000000000000000000000000000000000002540be400",
          "logIndex" => "0xcd",
          "removed" => false,
          "topics" => [
            "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
            "0x00000000000000000000000071660c4005ba85c37ccec55d0c4493e66fe775d3",
            "0x000000000000000000000000639671019ddd8ec28d35113d8d1c5f1bbfd7e0be",
          ],
          "transactionHash" => "0xcff6d58021eb9f743e29ca84cb94964332cc91babcc3533714d34264535ed3c5",
          "transactionIndex" => "0x8c",
        },
        {
          "address" => "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "blockHash" => "0x7461cf774021f421441df69bb1a04c66fac58fb72071c8286b2874d2e41ba448",
          "blockNumber" => "0xdcc880",
          "data" => "0x00000000000000000000000000000000000000000000000000000000aa3752a2",
          "logIndex" => "0xbc",
          "removed" => false,
          "topics" => [
            "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925",
            "0x0000000000000000000000007f8c1877ed0da352f78be4fe4cda58bb804a30df",
            "0x00000000000000000000000068b3465833fb72a70ecdf485e0e4c7bd8665fc45",
          ],
          "transactionHash" => "0xcbf51c188fb3d24760d083c6b53a4b604d2658321ef92cd48489ce3804b3de2b",
          "transactionIndex" => "0x78",
        },
        {
          "address" => "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "data" => "0x0000000000000000000000000000000000000000000000000000000000000000",
          "topics" => [
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000000000000000000000000000",
          ],
        },
      ]

      results = Abi::Event.decode_logs(erc20_abi, logs).to_a

      log, decoded_log = results[0]
      expect(log).to eq logs[0]
      expect(decoded_log.name).to eq "Transfer"
      expect(decoded_log.signature).to eq "Transfer(address,address,uint256)"
      expect(decoded_log.topic).to eq "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
      expect(decoded_log.kwargs[:from]).to eq "0x71660c4005ba85c37ccec55d0c4493e66fe775d3"
      expect(decoded_log.kwargs[:to]).to eq "0x639671019ddd8ec28d35113d8d1c5f1bbfd7e0be"
      expect(decoded_log.kwargs[:value]).to eq 10000000000

      log, decoded_log = results[1]
      expect(log).to eq logs[1]
      expect(decoded_log.name).to eq "Approval"
      expect(decoded_log.signature).to eq "Approval(address,address,uint256)"
      expect(decoded_log.topic).to eq "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
      expect(decoded_log.kwargs[:owner]).to eq "0x7f8c1877ed0da352f78be4fe4cda58bb804a30df"
      expect(decoded_log.kwargs[:spender]).to eq "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45"
      expect(decoded_log.kwargs[:value]).to eq 2855752354

      log, decoded_log = results[2]
      expect(log).to eq logs[2]
      expect(decoded_log).to eq nil
    end
  end

  let(:erc20_abi_file) { File.read "spec/fixtures/abi/ERC20.json" }
  subject(:erc20_abi) { JSON.parse erc20_abi_file }

  describe ".signature" do
    it "generates Transfer event signature" do
      abi = erc20_abi.find { |i| i["type"] == "event" && i["name"] == "Transfer" }
      signature = Abi::Event.signature(abi)
      expect(signature).to eq "Transfer(address,address,uint256)"
    end

    it "generates transfer function signature" do
      abi = erc20_abi.find { |i| i["type"] == "function" && i["name"] == "transfer" }
      signature = Abi::Event.signature(abi)
      expect(signature).to eq "transfer(address,uint256)"
    end
  end
end
