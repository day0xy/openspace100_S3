编写一个 BigBank 合约， 它继承自该挑战 的 Bank 合约，并实现功能：

要求存款金额 >0.001 ether（用modifier权限控制）
BigBank 合约支持转移管理员
同时编写一个 Ownable 合约，把 BigBank 的管理员转移给Ownable 合约， 实现只有Ownable 可以调用 BigBank 的 withdraw().
编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
用数组记录存款金额的前 3 名用户