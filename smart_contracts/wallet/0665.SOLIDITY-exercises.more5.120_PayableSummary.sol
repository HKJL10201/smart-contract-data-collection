//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract PayableSummary {
    //stores ether inside this contract.
    constructor() payable{}

    function foo() external payable{}

    fallback() external payable{}

    receive() external payable{}

    **** 
    //MSG.SENDER --> ANY ACCOUNT(_to) ETHER TRASNFER
    // IT does NOT send ether from this contract. It sends ethers of msg.sender to any account
    function bazz(address payable _to) external payable{
        (bool success, ) = _to.call{value: msg.value}("");
        require(success, "transaction failed");
    }

    **** 
    function getBalance() external view returns(uint){
        return address(this).balance;
    }
    
    ****
    receive: msg.data must be empty
    fallback: doesnt care about msg.data
}

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract PayableSummary {
    //stores ether inside this contract.
    constructor() payable{}

    function foo() external payable{}

    fallback() external payable{}

    receive() external payable{}


    //CONTRACT --> ACCOUNT
    function transferEther1(address payable _to, uint _value) external {
        (bool success, ) = _to.call{value: _value}("");
        require(success, "call failed");
    } 

    //ACCOUNT --> ACCOUNT
    // IT does NOT send ether from this contract. It sends ethers of msg.sender to any account
    function transferEther2(address payable _to) external payable{
        (bool success, ) = _to.call{value: msg.value}("");
        require(success, "call failed");
    }

    //ACCOUNT --> ACCOUNT
    // IT does NOT send ether from this contract. It sends ethers of msg.sender to any account
    function transferEther3(address payable _to, uint amount) external payable{
        (bool success, ) = _to.call{value: amount}("");
        require(success, "call failed");
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }
    
    // receive: msg.data must be empty
    // fallback: doesnt care about msg.data
}