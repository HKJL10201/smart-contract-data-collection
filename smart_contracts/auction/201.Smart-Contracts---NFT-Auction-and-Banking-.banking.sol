pragma solidity 0.8.10;

contract MyContract{
    ///stores the balance corresponding to bank accounts
    mapping(address => uint) private balances;

    function deposit() external payable {

        ///all key have a default value of 0
        balances[msg.sender] +=msg.value;
    }

    ///by default amount is in wei
    function withdraw(address payable addr, uint amount) public payable{

        require(balances[addr]>=amount,"Insufficinet funds"); ///if this condition is not met it just returns from here

        (bool sent, bytes memory data) = addr.call{value:amount}("");

        require(sent,"Could not withdraw");

        balances[msg.sender] -=amount;


    }

    function getBalance() public view returns (uint){
        
        return address(this).balance;
    }

    
}
