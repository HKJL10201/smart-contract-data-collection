pragma solidity ^0.5.0;

contract UELcoin {
    string public name = "UELcoin";
    string public symbol = "UEL";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public claimableAmount = 100 * 10**uint256(decimals);
    uint256 public maxClaimSupply = 1000000 * 10**uint256(decimals);
    uint256 public claimedSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        totalSupply = 1000000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply - maxClaimSupply;
        claimedSupply = 0;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function claim() public {
        require(claimedSupply + claimableAmount <= maxClaimSupply, "No more tokens left to claim");
        balanceOf[msg.sender] += claimableAmount;
        claimedSupply += claimableAmount;
        emit Transfer(address(0), msg.sender, claimableAmount);
    }
    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}