pragma solidity ^0.4.17;

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract DalaWallet {
    address public owner;
    address public destination;
    address public token;
    
    event DestinationChanged(address indexed oldAddress, address indexed newAddress);
    event LogSweep(address indexed from, address indexed to, address indexed token, uint amount);
    
    modifier onlyOwner() {
        if (msg.sender != owner)
            revert(); 
        _;
    }

    function DalaWallet(address _destination, address _token) public {
        destination = _destination;
        token = _token;
        owner = msg.sender;
    }

    function sweep() public onlyOwner returns (bool) {
        var erc20 = ERC20(token);
        var balance = erc20.balanceOf(this);
        var success = erc20.transfer(destination, balance);
        if (success) {
            LogSweep(msg.sender, destination, token, balance);
        } 
        return success;
    }

    function setDestination(address _destination) public onlyOwner returns (bool) {
        var oldDest = destination;
        destination = _destination;
        DestinationChanged(oldDest, _destination);
        return true;
    }
}