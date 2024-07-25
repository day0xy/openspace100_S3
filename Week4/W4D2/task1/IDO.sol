// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestTokenIDO {
    IERC20 public token;
    address public owner;
    bool public isPresaleActive = false;
    //项目方这次预售的tokem总量
    uint256 public totalPresaleAmount;

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
    uint256 public startTime;
    uint256 public endTime;
    //募集的总金额
    uint256 public totalRaised = 0;

    mapping(address => uint256) public funded;
    mapping(address => bool) public claimedRefund;

    event PresaleStarted();
    event Presale(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 tokens);
    event RefundClaimed(address indexed user, uint256 amount);

    constructor(
        address _token,
        uint256 _totalPresaleAmount,
        uint256 _startTime,
        uint256 _endTime,
        address _owner
    ) {
        owner = _owner;
        token = IERC20(_token);
        require(token.totalSupply() > 0, "invalid token");
        require(_totalPresaleAmount > 0, "invalid total presale amount");
        require(
            _totalPresaleAmount <= token.totalSupply(),
            "total presale amount exceeds total supply"
        );
        totalPresaleAmount = _totalPresaleAmount;
        startTime = _startTime;
        endTime = _endTime;
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
        require(block.timestamp > endTime, "presale not ended");
        _;
    }

    function startPresale() external onlyOwner {
        require(!isPresaleActive, "presale already active");
        isPresaleActive = true;
        emit PresaleStarted();
    }

    //预售，用户转入eth,换取token
    function presale() external payable onlyPresaleActive {
        require(msg.value >= MIN_BUY, "below min buy");
        require(msg.value <= MAX_BUY, "above max buy");
        //防止不超过cap金额
        require(totalRaised + msg.value <= RAISE_CAP, "exceeds raise cap");
        require(block.timestamp >= startTime, "presale not started");
        require(block.timestamp <= endTime, "presale ended");

        //统计用户转入ETH的金额
        funded[msg.sender] += msg.value;
        totalRaised += msg.value;
        token.transfer(msg.sender, msg.value / PRESALE_PRICE);

        emit Presale(msg.sender, msg.value);
    }

    //预售结束后，如果达到项目募集资金预期，那么用户可以领取token
    function claimTokens() external whenPresaleEnded {
        require(totalRaised >= RAISE_LIMIT, "raise limit not met");
        uint256 amount = funded[msg.sender];
        require(amount > 0, "no tokens to claim");

        funded[msg.sender] = 0;
        //按比例发token
        //token数量=总预售token数量*用户投入的eth/总募集的eth
        uint256 tokens = totalPresaleAmount *
            (funded[msg.sender] / totalRaised);

        //token发送给用户
        token.transfer(msg.sender, tokens);
        emit TokensClaimed(msg.sender, tokens);
    }

    //预售结束后，如果募集资金没有达到RAISE_LIMIT，用户可以申请退钱
    function claimRefund() external whenPresaleEnded {
        require(totalRaised < RAISE_LIMIT, "raise limit met");
        require(!claimedRefund[msg.sender], "refund already claimed");

        uint256 amount = funded[msg.sender];
        require(amount > 0, "no refund available");

        claimedRefund[msg.sender] = true;
        funded[msg.sender] = 0;

        //退钱给用户
        payable(msg.sender).transfer(amount);
        emit RefundClaimed(msg.sender, amount);
    }

    //预售结束后，募集资金达到值RAISE_LIMIT后.项目方可以提钱出来
    function withdrawFunds() external onlyOwner whenPresaleEnded {
        require(totalRaised >= RAISE_LIMIT, "raise limit not met");
        payable(owner).transfer(address(this).balance);
    }

    function totalRaised_() external view returns (uint256) {
        return totalRaised;
    }
}
