1. 扩展 ERC20 合约，使其具备在转账的时候，如果目标地址是合约的话，调用目标地址的 tokensReceived() 方法.

2. 扩展 TokenBank, 在TokenBank 中利用上一题的转账回调实现存款。


3. 扩展挑战Token 购买 NFT 合约，能够使用ERC20扩展中的回调函数来购买某个 NFT ID。