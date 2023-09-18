pragma solidity ^0.8.0;

contract Oracle {
    address owner;
    address public cbAddress; // callback address

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) 
            revert();
        _;
    }

    event QueryEvent(bytes32 id, string query);

    function setCbAddress(address _cbAddress) public onlyOwner {
        cbAddress = _cbAddress;
    }

    function query(string memory _query) public returns (bytes32 id) {
        id = keccak256(abi.encode(block.number, block.timestamp, _query, msg.sender));
        emit QueryEvent(id, _query);
        return id;
    }
}