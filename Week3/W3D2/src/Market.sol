// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
TODO:
思考    1.如果说是list上架，应该有两种方式，一个是授权，一个是转移nft到市场合约,
        2.那么如果是直接授权nft给市场合约，那么buy函数要怎么修改？


 */
contract NFTMarket is IERC721Receiver {
    mapping(address => mapping(uint256 => Listing)) public listings;

    struct Listing {
        address seller;
        uint256 price;
        address payToken;
    }

    event List(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        address payToken,
        uint256 price
    );

    event BuyNFT(
        address seller,
        address indexed buyer,
        uint256 price,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event Delist(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    function list(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address payToken
    ) public {
        IERC721 nft = IERC721(nftAddress);
        require(price > 0, "NFTMarket: Price must be greater than 0");
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "NFTMarket: Token not owned by seller"
        );
        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(msg.sender, address(this)),
            "NFTMarket: Contract is not approved"
        );
        require(payToken != address(0), "NFTMarket: Invalid pay token");
        require(
            listings[nftAddress][tokenId].seller == address(0),
            "NFTMarket: Product already listed"
        );

        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        listings[nftAddress][tokenId] = Listing(msg.sender, price, payToken);

        emit List(nftAddress, tokenId, msg.sender, payToken, price);
    }

    function buyNFT(address nftAddress, uint256 tokenId) public {
        Listing memory listing = listings[nftAddress][tokenId];

        require(listing.seller != address(0), "NFTMarket: Product not exists");
        require(listing.price > 0, "NFTMarket: Product not exists");
        require(
            IERC721(nftAddress).ownerOf(tokenId) == address(this),
            "NFTMarket: Product not exists"
        );

        delete listings[nftAddress][tokenId];

        IERC20 payToken = IERC20(listing.payToken);
        require(
            payToken.transferFrom(msg.sender, listing.seller, listing.price),
            "NFTMarket: Payment failed"
        );

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit BuyNFT(
            listing.seller,
            msg.sender,
            listing.price,
            nftAddress,
            tokenId
        );
    }

    function delist(address nftAddress, uint256 tokenId) public {
        Listing memory listing = listings[nftAddress][tokenId];

        require(listing.seller == msg.sender, "NFTMarket: Not seller");
        require(
            IERC721(nftAddress).ownerOf(tokenId) == address(this),
            "NFTMarket: Contract does not own the NFT"
        );

        IERC721(nftAddress).safeTransferFrom(
            address(this),
            listing.seller,
            tokenId
        );

        emit Delist(msg.sender, nftAddress, tokenId);

        delete listings[nftAddress][tokenId];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
