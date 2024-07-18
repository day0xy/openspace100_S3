import { createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";

async function main() {
  const client = createPublicClient({
    chain: mainnet,
    transport: http(),
  });

  const processedBlocks = new Set();

  async function fetchLatestBlock() {
    try {
      const latestBlock = await client.getBlock();

      if (latestBlock && !processedBlocks.has(latestBlock.hash)) {
        const blockHeight = latestBlock.number;
        const blockHash = latestBlock.hash;

        console.log(`${blockHeight} (${blockHash})`);

        // 记录已处理的区块哈希
        processedBlocks.add(blockHash);
      }
    } catch (error) {
      console.error("Error fetching latest block:", error);
    }
  }

  setInterval(fetchLatestBlock, 1000);
}

main().catch(console.error);
