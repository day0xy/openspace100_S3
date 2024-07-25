// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is IERC721Receiver, Ownable, EIP712 {
    using ECDSA for bytes32;

    struct Listing {
        address seller;
        uint256 price;
        address payToken;
        uint256 deadline;
    }

    struct ListingKey {
        address nftAddress;
        uint256 tokenId;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    ListingKey[] public listingKeys;
    address public whiteListSigner;
    bytes32 constant WL_TYPEHASH = keccak256("IsWhiteList(address user)");

    constructor() EIP712("NFTMarket", "1") Ownable(msg.sender) {
        whiteListSigner = msg.sender;
    }

    event List(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        address payToken,
        uint256 price,
        uint256 deadline
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

    event SetWhiteListSigner(address indexed signer);

    function setWhiteListSigner(address signer) external onlyOwner {
        require(signer != address(0), "NFTMarket: Invalid signer");
        whiteListSigner = signer;
        emit SetWhiteListSigner(signer);
    }

    function list(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address payToken,
        uint256 deadline
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
        require(deadline > block.timestamp, "NFTMarket: Invalid deadline");

        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        listings[nftAddress][tokenId] = Listing(
            msg.sender,
            price,
            payToken,
            deadline
        );
        listingKeys.push(ListingKey(nftAddress, tokenId));

        emit List(nftAddress, tokenId, msg.sender, payToken, price, deadline);
    }

    function listWithSignature(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address payToken,
        uint256 deadline,
        bytes memory signature
    ) public {
        _checkWL(signature);
        list(nftAddress, tokenId, price, payToken, deadline);
    }

    function buyNFT(address nftAddress, uint256 tokenId) public payable {
        _executeBuy(nftAddress, tokenId);
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

    function permitBuy(
        address nftAddress,
        uint256 tokenId,
        bytes memory signature
    ) public payable {
        // Check white list signature
        _checkWL(signature);
        _executeBuy(nftAddress, tokenId);
    }

    function _executeBuy(address nftAddress, uint256 tokenId) private {
        Listing memory listing = listings[nftAddress][tokenId];

        require(listing.seller != address(0), "NFTMarket: Product not exists");
        require(listing.price > 0, "NFTMarket: Product not exists");
        require(
            IERC721(nftAddress).ownerOf(tokenId) == address(this),
            "NFTMarket: Product not exists"
        );
        require(
            block.timestamp <= listing.deadline,
            "NFTMarket: Listing expired"
        );

        // Transfer funds and NFT
        if (listing.payToken == address(0)) {
            require(
                msg.value == listing.price,
                "NFTMarket: Incorrect ETH value"
            );
            payable(listing.seller).transfer(listing.price);
        } else {
            IERC20 payToken = IERC20(listing.payToken);
            require(
                payToken.transferFrom(
                    msg.sender,
                    listing.seller,
                    listing.price
                ),
                "NFTMarket: Payment failed"
            );
        }

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit BuyNFT(
            listing.seller,
            msg.sender,
            listing.price,
            nftAddress,
            tokenId
        );

        // Remove the listing after successful transaction
        delete listings[nftAddress][tokenId];
    }

    function _checkWL(bytes memory signature) private view {
        bytes32 wlHash = _hashTypedDataV4(
            keccak256(abi.encode(WL_TYPEHASH, msg.sender))
        );
        address signer = wlHash.recover(signature);
        require(signer == whiteListSigner, "NFTMarket: not whileListSigner");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Getter function for WL_TYPEHASH
    function getWLTypeHash() external pure returns (bytes32) {
        return WL_TYPEHASH;
    }

    // Public function to access _hashTypedDataV4
    function hashTypedDataV4(
        bytes32 structHash
    ) external view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }

    // Function to get all listings
    function getListings() external view returns (ListingKey[] memory) {
        return listingKeys;
    }
}
