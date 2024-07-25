// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyWallet {
    string public name;
    mapping(address => bool) private approved;
    address private owner;

    modifier auth() {
        address _owner;
        assembly {
            _owner := sload(owner.slot)
        }
        require(msg.sender == _owner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        assembly {
            sstore(owner.slot, caller())
        }
    }

    function transferOwnership(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        assembly {
            let _owner := sload(owner.slot)
            if eq(_owner, _addr) {
                revert(0, 0)
            }
            sstore(owner.slot, _addr)
        }
    }
}
