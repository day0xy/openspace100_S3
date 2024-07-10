// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// 定义 TokenRecipient 接口
interface TokenRecipient {
    function tokensReceived(address from, uint256 amount) external returns (bool);
}

contract Market is TokenRecipient {
    IERC20 public token;
    IERC721 public nft;

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => Listing) public listings;
    uint256[] public listedTokenIds;

    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTPurchased(address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(IERC20 _token, IERC721 _nft) {
        token = _token;
        nft = _nft;
    }

    function list(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "caller is not the owner of the nft");
        require(price > 0, "Price must be greater than 0");

        nft.transferFrom(msg.sender, address(this), tokenId);

        listings[tokenId] = Listing({seller: msg.sender, price: price, isListed: true});
        listedTokenIds.push(tokenId);

        emit NFTListed(msg.sender, tokenId, price);
    }

    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.isListed, "NFT not listed for sale");
        require(token.transferFrom(msg.sender, listing.seller, listing.price), "Token transfer failed");

        _purchase(tokenId, msg.sender);
    }

    // 实现 TokenRecipient 接口中的 tokensReceived 方法
    function tokensReceived(address from, uint256 amount) external override returns (bool) {
        // 查找符合金额的 NFT 列表
        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            uint256 tokenId = listedTokenIds[i];
            Listing memory listing = listings[tokenId];
            if (listing.isListed && listing.price == amount) {
                _purchase(tokenId, from);
                return true;
            }
        }

        revert("No NFT matches the token amount");
    }

    // 内部的购买处理函数
    function _purchase(uint256 tokenId, address buyer) internal {
        Listing memory listing = listings[tokenId];
        require(listing.isListed, "NFT not listed for sale");

        listing.isListed = false;
        nft.transferFrom(address(this), buyer, tokenId);

        // 从 listedTokenIds 移除已购买的 tokenId
        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                listedTokenIds.pop();
                break;
            }
        }

        emit NFTPurchased(buyer, tokenId, listing.price);
    }
}
