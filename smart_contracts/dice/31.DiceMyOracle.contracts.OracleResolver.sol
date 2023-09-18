pragma solidity ^0.8.0;

contract OracleResolver {
    address owner;

    address public oracleAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) 
            revert();
        _;
    }

    function setOracleAddress(address _addr) public onlyOwner {
        oracleAddress = _addr;
    }
    
    function getOracleAddress() public view returns(address) {
        return oracleAddress;
    }
}
