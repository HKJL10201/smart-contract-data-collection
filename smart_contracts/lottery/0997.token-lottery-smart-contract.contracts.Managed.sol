pragma solidity ^0.5.0;

contract Managed {
    address public manager;
    address public newManager;

    constructor() public {
        manager = msg.sender;
    }

    modifier onlyManager {
        require(msg.sender == manager, 'Sender not authorized.');
        _;
    }

    function transferOwnership(address _newManager) public onlyManager {
        newManager = _newManager;
    }

    function acceptOwnership() public {
        require(msg.sender == newManager, 'Sender not authorized.');
        manager = newManager;
        newManager = address(0);
    }
}