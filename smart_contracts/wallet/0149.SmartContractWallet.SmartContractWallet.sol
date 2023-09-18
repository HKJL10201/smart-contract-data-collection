//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Consumer
{
        function getBalance() public view returns(uint)
        {
            return address(this).balance;
        }
        function deposit() public payable{}
}
contract Wallet
{  
    address payable owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public sendAllowed;
    mapping(address => bool) public guardian;
    mapping(address => mapping(address => bool)) sameGuardianCheck;
    address payable nextOwner;
    uint guardiansResetCount;
    uint public constant guardianConfirmationsNeededForReset = 3;
    

    constructor()
    {
        owner = payable(msg.sender);
    }

    function proposeNewOwner(address payable newOwner) public
    {
        require(guardian[msg.sender], "You are not a guardian, aborting");
        require(sameGuardianCheck[msg.sender][newOwner]==false, "You already voted");
        if(nextOwner!=newOwner)
        {
            nextOwner = newOwner;
            guardiansResetCount=0;
        }
        guardiansResetCount++;
        sameGuardianCheck[msg.sender][newOwner]==true;

        if(guardiansResetCount>= guardianConfirmationsNeededForReset)
        {
            owner = nextOwner;
            nextOwner = payable(address(0));//Add Code here
        }
    }

    function setAllowance(address from, uint amount) public 
    {
        require(msg.sender == owner, "You are not the owner");
        allowance[from]=amount;
        sendAllowed[from] = true;
    }

    function denySending(address from) public view
    {
        require(msg.sender == owner, "You are not the owner");
        sendAllowed[from] == false;
    }

    function transfer(address payable to, uint amount, bytes memory payload) public returns (bytes memory) 
    {
        require(amount <= address(this).balance, "Can't send more than the contract owns, aborting.");
        if(msg.sender != owner) {
            require(sendAllowed[msg.sender], "You are not allowed to send any transactions, aborting");
            require(allowance[msg.sender] >= amount, "You are trying to send more than you are allowed to, aborting");
            allowance[msg.sender] -= amount;

        }

        (bool success, bytes memory returnData) = to.call{value: amount}(payload);
        require(success, "Transaction failed, aborting");
        return returnData;
    }

    receive() external payable {}

}