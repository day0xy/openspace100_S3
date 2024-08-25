import {
  BuyNFT as BuyNFTEvent,
  Delist as DelistEvent,
  EIP712DomainChanged as EIP712DomainChangedEvent,
  List as ListEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  SetWhiteListSigner as SetWhiteListSignerEvent,
} from "../generated/NFTMarket/NFTMarket";
import {
  BuyNFT,
  Delist,
  EIP712DomainChanged,
  List,
  OwnershipTransferred,
  SetWhiteListSigner,
} from "../generated/schema";

export function handleBuyNFT(event: BuyNFTEvent): void {
  let entity = new BuyNFT(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.seller = event.params.seller;
  entity.buyer = event.params.buyer;
  entity.price = event.params.price;
  entity.nftAddress = event.params.nftAddress;
  entity.tokenId = event.params.tokenId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleDelist(event: DelistEvent): void {
  let entity = new Delist(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.seller = event.params.seller;
  entity.nftAddress = event.params.nftAddress;
  entity.tokenId = event.params.tokenId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleEIP712DomainChanged(
  event: EIP712DomainChangedEvent
): void {
  let entity = new EIP712DomainChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleList(event: ListEvent): void {
  let entity = new List(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.nftAddress = event.params.nftAddress;
  entity.tokenId = event.params.tokenId;
  entity.seller = event.params.seller;
  entity.payToken = event.params.payToken;
  entity.price = event.params.price;
  entity.deadline = event.params.deadline;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.previousOwner = event.params.previousOwner;
  entity.newOwner = event.params.newOwner;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleSetWhiteListSigner(event: SetWhiteListSignerEvent): void {
  let entity = new SetWhiteListSigner(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.signer = event.params.signer;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
