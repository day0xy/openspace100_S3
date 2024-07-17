import { createPublicClient, http, parseAbiItem, formatUnits } from "viem";
import { mainnet } from "viem/chains";

const USDC_CONTRACT_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

const TRANSFER_EVENT_ABI = parseAbiItem(
  "event Transfer(address indexed from, address indexed to, uint256 value)"
);

async function main() {
  try {
    const client = createPublicClient({
      chain: mainnet,
      transport: http("https://rpc.flashbots.net"),
    });

    const latestBlock = await client.getBlockNumber();
    const startBlock = BigInt(latestBlock) - BigInt(100);

    const filter = await client.createEventFilter({
      address: USDC_CONTRACT_ADDRESS,
      event: TRANSFER_EVENT_ABI,
      fromBlock: startBlock,
      toBlock: "latest",
    });

    const logs = await client.getFilterLogs({ filter });

    logs.forEach((log) => {
      const { from, to, value } = log.args || {};
      if (from && to && value) {
        const formattedValue = Number(formatUnits(value, 6)).toFixed(5);
        console.log(
          `从 ${from} 转账给 ${to} ${formattedValue} USDC, 交易ID：${log.transactionHash}`
        );
      } else {
        console.log("日志解析错误：", log);
      }
    });
  } catch (error) {
    console.error(error);
  }
}

main();
