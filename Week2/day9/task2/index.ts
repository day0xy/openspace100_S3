import { publicClient } from "./client";
import { wagmiAbi } from "./abi";

async function fetchOwnerAndMetadata(tokenId: bigint) {
  try {
    // 获取NFT的拥有者
    const owner = await publicClient.readContract({
      address: "0x0483b0dfc6c78062b9e999a82ffb795925381415",
      abi: wagmiAbi,
      functionName: "ownerOf",
      args: [tokenId], // 使用传递的 tokenId
    });

    console.log(`Owner of token ${tokenId}:`, owner);

    // 获取NFT的元数据URI
    const tokenURI = await publicClient.readContract({
      address: "0x0483b0dfc6c78062b9e999a82ffb795925381415",
      abi: wagmiAbi,
      functionName: "tokenURI",
      args: [tokenId], // 使用传递的 tokenId
    });

    console.log(`Token URI of token ${tokenId}:`, tokenURI);
  } catch (error) {
    console.error("Error fetching contract data or metadata:", error);
  }
}

fetchOwnerAndMetadata(BigInt(1));
