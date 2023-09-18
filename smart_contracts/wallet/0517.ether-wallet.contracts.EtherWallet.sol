pragma solidity >=0.4.16 <0.8.0;

contract EtherWallet {
    address payable public Owner;

    constructor(address payable _owner) public {
        Owner = _owner;
    }

    function depoist() public payable {}

    /*
    send ethers from wallet contract to any address by contract owner
     */
    function send(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    /*
    send ethers from wallet contract(you should pay for this function) to multiple addresses by contract owner  
     */
    function sendMultiple(
        address payable[] memory _to,
        uint256[] memory _amount
    ) public payable onlyOwner {
        require(
            _to.length == _amount.length,
            "must be same length of the addresses and amounts"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            _to[i].transfer(_amount[i]);
        }
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "sender is not allowed");
        _;
    }
}
