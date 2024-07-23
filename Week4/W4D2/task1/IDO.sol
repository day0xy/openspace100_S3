// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestTokenIDO {
    IERC20 public token;
    address public owner;
    bool public isPresaleActive = false;

    //预售价格
    uint256 constant PRESALE_PRICE = 0.001 ether;
    //募集资金的期望值
    uint256 constant RAISE_LIMIT = 100 ether;
    //募集资金的最大值
    uint256 constant RAISE_CAP = 200 ether;
    //最小购买金额
    uint256 constant MIN_BUY = 0.01 ether;
    //最大购买金额
    uint256 constant MAX_BUY = 0.1 ether;
    //预售时间
    uint256 constant START_TIME = 1632960000;
    uint256 constant END_TIME = 1632960000 + 7 days;
    //募集的总金额
    uint256 public totalRaised = 0;

    mapping(address => uint256) public funded;
    mapping(address => bool) public claimedRefund;

    event PresaleStarted();
    event Presale(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 tokens);
    event RefundClaimed(address indexed user, uint256 amount);

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
        require(token.totalSupply() > 0, "invalid token");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyPresaleActive() {
        require(isPresaleActive, "presale not active");
        _;
    }

    modifier whenPresaleEnded() {
        require(block.timestamp > END_TIME, "presale not ended");
        _;
    }

    function startPresale() external onlyOwner {
        require(!isPresaleActive, "presale already active");
        isPresaleActive = true;
        emit PresaleStarted();
    }

    function presale() external payable onlyPresaleActive {
        require(msg.value >= MIN_BUY, "below min buy");
        require(msg.value <= MAX_BUY, "above max buy");
        //防止不超过cap金额
        require(totalRaised + msg.value <= RAISE_CAP, "exceeds raise cap");
        require(block.timestamp >= START_TIME, "presale not started");
        require(block.timestamp <= END_TIME, "presale ended");

        //用户放入ETH的金额
        funded[msg.sender] += msg.value;
        totalRaised += msg.value;

        //计算token数量,发给用户
        token.transfer(msg.sender, msg.value / PRESALE_PRICE);
        emit Presale(msg.sender, msg.value);
    }

    function claimTokens() external whenPresaleEnded {
        require(totalRaised >= RAISE_LIMIT, "raise limit not met");
        uint256 amount = funded[msg.sender];
        require(amount > 0, "no tokens to claim");

        //防止重入
        funded[msg.sender] = 0;
        uint256 tokens = amount / PRESALE_PRICE;

        token.transfer(msg.sender, tokens);
        emit TokensClaimed(msg.sender, tokens);
    }

    function claimRefund() external whenPresaleEnded {
        require(totalRaised < RAISE_LIMIT, "raise limit met");
        require(!claimedRefund[msg.sender], "refund already claimed");

        uint256 amount = funded[msg.sender];
        require(amount > 0, "no refund available");

        claimedRefund[msg.sender] = true;
        funded[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
        emit RefundClaimed(msg.sender, amount);
    }

    function withdrawFunds() external onlyOwner whenPresaleEnded {
        require(totalRaised >= RAISE_LIMIT, "raise limit not met");
        payable(owner).transfer(address(this).balance);
    }
}
