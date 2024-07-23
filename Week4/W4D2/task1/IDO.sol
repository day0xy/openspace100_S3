// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract testTokenIDO {
    IERC20 token;
    address public owner;
    bool isPresaleActive = false;

    uint256 constant PRESALE_PRICE = 0.001 ether;
    uint256 constant RAISE_LIMIT = 100 ether;
    uint256 constant RAISE_CAP = 200 ether;
    uint256 constant MIN_BUY = 0.01 ether;
    uint256 constant MAX_BUY = 0.1 ether;
    uint256 constant SATRT_TIME = 1632960000;
    uint256 constant END_TIME = 1632960000 + 7 days;
    uint256 public totalRaised = 0;

    mapping(address => uint256) public funded;

    event Presale(address indexed user, uint256 amount);

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
        //需要检查这个token是否是有效的
        require(token.totalSupply() > 0, "invalid token");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyPresaleActive() {
        require(isPresaleActive == true, "presale not active");
        _;
    }

    modifier whenPresaleEnded() {
        require(block.timestamp > END_TIME, "presale not ended");
        _;
    }

    // 用来开启presale,只有项目方能调用
    function startPresale() external onlyOwner {
        require(isPresaleActive == false, "presale already active");
        isPresaleActive = true;
    }

    function presale() external payable onlyPresaleActive {
        require(msg.value >= MIN_BUY, "below min buy");
        require(msg.value <= MAX_BUY, "above max buy");
        require(totalRaised + msg.value <= RAISE_CAP, "exceeds raise cap");
        //检查时间是否在预售范围内
        require(block.timestamp >= SATRT_TIME, "presale not started");
        require(block.timestamp <= END_TIME, "presale ended");

        funded[msg.sender] += msg.value;
        totalRaised += msg.value;

        token.transfer(msg.sender, msg.value / PRESALE_PRICE);
        emit Presale(msg.sender, msg.value);
    }

    function claim() external whenPresaleEnded {
        require(isPresaleActive, "presale already ended");
        //结束掉presale
        isPresaleActive = false;
    }
}
