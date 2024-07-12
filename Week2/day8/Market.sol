// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Market {
    IERC20 public token;
    IERC721 public nft;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    event NFTPurchased(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    event NFTDelisted(address indexed seller, uint256 indexed tokenId);

    constructor(IERC20 _token, IERC721 _nft) {
        token = _token;
        nft = _nft;
    }

    function list(uint256 tokenId, uint256 price) external {
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "caller is not the owner of the nft"
        );
        require(price > 0, "Price must be greater than 0");
        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(msg.sender, address(this)),
            "NFT not approved for transfer"
        );

        listings[tokenId] = Listing({seller: msg.sender, price: price});

        nft.transferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(msg.sender, tokenId, price);
    }

    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not listed for sale");

        delete listings[tokenId];

        //先把钱给卖家，再把nft给买家,防止reentrancy
        require(
            token.transferFrom(msg.sender, listing.seller, listing.price),
            "Token transfer failed"
        );

        nft.transferFrom(address(this), msg.sender, tokenId);

        emit NFTPurchased(msg.sender, tokenId, listing.price);
    }

    function delist(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not listed for sale");
        require(listing.seller == msg.sender, "caller is not the seller");

        nft.transferFrom(address(this), msg.sender, tokenId);

        delete listings[tokenId];

        emit NFTDelisted(msg.sender, tokenId);
    }
}
