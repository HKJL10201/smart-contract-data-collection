// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address acc) external view returns (uint256);

    function transfer(address receiver, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract VoteToken is IERC20 {
    using SafeMath for uint256;

    string public constant name = "VoteToken";
    string public constant symbol = "VTKN";
    uint8 public constant decimals = 0;
    address owner;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    constructor() {
        totalSupply_ = 100000000000;
        balances[msg.sender] = totalSupply_;
        owner = msg.sender;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 amount)
        public
        override
        returns (bool)
    {
        require(amount <= balances[owner], "Amount exceeds remaining balance");
        balances[owner] = balances[owner].sub(amount);
        balances[receiver] = amount;
        emit Transfer(owner, receiver, amount);
        return true;
    }
}
