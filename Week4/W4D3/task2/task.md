使用你熟悉的语言利用 eth_getStorageAt RPC API 从链上读取 _locks 数组中的所有元素值，或者从另一个合约中设法读取esRNT中私有数组 _locks 元素数据，并打印出如下内容：
locks[0]: user:…… ,startTime:……,amount:……

```solidity
contract esRNT {
    struct LockInfo{
        address user;
        uint64 startTime; 
        uint256 amount;
    }
    LockInfo[] private _locks;

    constructor() { 
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(I+1)), uint64(block.timestamp*2-i), 1e18*(i+1)));
        }
    }
}
```