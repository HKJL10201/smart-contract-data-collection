pragma solidity 0.8.14;

contract EthereumWallet {
    address payable owner;

    modifier ownerOnly() {
        require(msg.sender == owner, "only the owner can call this function");
        _;
    }

    constructor(address payable _owner) {
        owner = _owner;
    }

    function deposit() public payable {}

    function send(address payable _recipient) public payable ownerOnly {
        _recipient.transfer(msg.value);
    }

     function balance() public view returns (uint) {
        return address(this).balance;
     }
}