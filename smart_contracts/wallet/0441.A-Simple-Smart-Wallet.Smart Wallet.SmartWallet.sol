//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

contract Consumer {
    function getBalance () public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable {

    }
}


contract SmartWallet {
    address payable owner;

    mapping(address => uint) public allowance;

    constructor() {
        owner = payable(msg.sender);
    }

    function setAllowance(address _for, uint _amount) external {
        require(msg.sender == owner, "Not an owner!");
        allowance[_for] = _amount;
    }

    function transfer(
        address payable _to,
        uint256 _amount,
        bytes memory _payload
    ) external returns (bytes memory) {
        if(msg.sender != owner) {
            require(allowance[msg.sender] > 0, "You are not allowed to send funds!");
            require(allowance[msg.sender] >= _amount, "Max amount should be less or equal to allowance!");

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(
            _payload
        );
        require(success, "Call was not successful");
        return returnData;
    }

    receive() external payable {}
}
