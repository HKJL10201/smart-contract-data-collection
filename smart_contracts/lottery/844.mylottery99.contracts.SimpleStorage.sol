// Credit: This contract is copied and pasted from https://docs.ethers.io/ethers.js/html/api-contract.html. Some necessary modifications for 0.5.11 have been done.

// Place your solidity files in this contracts folder and run the compile.js file using node compile.js file in project directory to compile your contracts.

pragma solidity ^0.6.1;

contract SimpleStorage {
    string _value;
    uint256 public rollNumber;

    event ValueChanged(address indexed author, string oldValue, string newValue);
    event ValueChanged(address indexed author, uint256 oldValue, uint256 newValue);

    constructor(string memory value) public {
        emit ValueChanged(msg.sender, _value, value);
        _value = value;
    }

    function getValue() view public returns (string memory) {
        return _value;
    }

    function setValue(string memory value) public {
        emit ValueChanged(msg.sender, _value, value);
        _value = value;
    }
    function setRollno(uint256  _newRollNumber) public {
        emit ValueChanged(msg.sender, rollNumber,_newRollNumber);
        rollNumber = _newRollNumber;
    }
}
