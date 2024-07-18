import { createPublicClient, http, parseAbiItem, formatUnits } from "viem";
import { mainnet } from "viem/chains";

const fetchBlockData = async () => {
  const client = createPublicClient({
    chain: mainnet,
    transport: http("https://rpc.flashbots.net"),
  });

  const latestBlock = await client.getBlock({ blockTag: "latest" });
  console.log("Block height:", Number(latestBlock.number));
  console.log("Block hash:", latestBlock.hash);

  return latestBlock;
};

const subscribeToEvents = async () => {
  const client = createPublicClient({
    chain: mainnet,
    transport: http("https://rpc.flashbots.net"),
  });

  client.watchBlockNumber({
    onBlockNumber: async (blockNumber) => {
      if (blockNumber === undefined) {
        console.log("Unable to obtain block height");
        return;
      }

      const safeBlockNumber =
        blockNumber !== undefined ? BigInt(blockNumber) : 0n;
      console.log("Block height:", Number(safeBlockNumber));

      const fromBlock = safeBlockNumber - 100n;
      const toBlock = safeBlockNumber;

      const logs = await client.getLogs({
        address: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        event: parseAbiItem(
          "event Transfer(address indexed from, address indexed to, uint256 value)"
        ),
        fromBlock,
        toBlock,
      });

      const newTransfers = logs.map((log) => {
        const { from, to, value } = log.args || {};
        return {
          blockNumber: log.blockNumber,
          transactionHash: log.transactionHash,
          from,
          to,
          value: value ? Number(formatUnits(value, 6)).toFixed(5) : "0.00000",
        };
      });

      newTransfers.forEach((transfer) => {
        console.log(
          `在 {transfer.blockNumber} 区块 {transfer.transactionHash} 交易中从 {transfer.from} 转账 {transfer.value} USDT 到 {transfer.to}`
        );
      });
    },
  });
};

const init = async () => {
  await fetchBlockData();
  await subscribeToEvents();
};

init();
