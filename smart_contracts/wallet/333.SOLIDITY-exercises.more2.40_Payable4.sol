// SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract Payable4 {
    mapping(uint => address payable) public accounts;

    function addToMapping(uint _myOrder, address payable _myAddress) external {
        accounts[_myOrder] = _myAddress;
    }

    function makeTransaction(uint _accountOrder) external payable {
        address payable _to = accounts[_accountOrder];
        (bool sent,) = _to.call{value: msg.value}("");
        require(sent, "failed to send Ether");
    }

    function getBalances(uint _accountOrder) external view returns(uint) {
        address queryAddress = accounts[_accountOrder];
        return address(queryAddress).balance;
    }
}
//now contract base is finished and it is a piece of art. 
//The contract first creates a mapping, then it adds to mapping with order number. Then just by 
//entering order number, I can send the amount to the relevant account represented by order number"
// last function checks the amount of ether in each contract by entering contract order number in mapping