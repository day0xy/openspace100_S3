import { createPublicClient, http, toHex } from "viem";
import { mainnet } from "viem/chains";

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http(),
});

const data = await publicClient.getStorageAt({
  address: "0xFBA3912Ca04dd458c843e2EE08967fC04f3579c2",
  slot: toHex(0),
});
