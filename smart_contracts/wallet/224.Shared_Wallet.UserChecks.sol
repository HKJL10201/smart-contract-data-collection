pragma solidity ^0.8.4;

//UserChecks Smart Contract to provide the user with the ability to check the followings
// - Smart Contract owner
//- Allowance
//- Smart Contract Balance
//- Allowance Frequency
//- Amount Already Withdrawn
// - How long the user has to wait if the totality of the withdrawable allowance in the allowed time period has been already withdrawn
// - How much time left the user has to withdraw its remaining allowance in the allocated time period
contract UserChecks {
    
    address owner;
    uint allowance = 100;
    uint allowance_frequency = 180;
    mapping(address => uint) public balanceReceived;
    mapping(address => uint) TimeCount;
    mapping(address => uint) countAmountWithdrawn;
    
    event AllowanceChanged(uint _oldAmount, uint _newAmount);
    event FrequencyAllowanceChanged(uint _oldFreqAmount, uint _newFreqAmount);
    
    constructor () {
        owner = msg.sender;
    }
     //Function to get address of the Smart Contract Owner
    function getOwner() public view returns(address) {
        return owner;
    }
    
    //Function to get the total balance of the smart contract
    function getBalance() public view returns(uint) {
         return address(this).balance;
     }
     
     //Function to get the allowance
     function getAllowance() public view returns(uint) {
         return uint(allowance);
     }

     //Function to get the frequency at which a user can withdraw its allowance 
     function getFreqAllowance() public view returns(uint) {
         return uint(allowance_frequency);
     }
     //Function to get how much money a user has withdrawn in the allowed time period
    function getAmountWithdrawn() public view returns(uint) {
         return uint(countAmountWithdrawn[msg.sender]);
     }
     // Function to get:
        // - How long the user has to wait if the totality of the withdrawable allowance in the allowed time period has been already withdrawn
        // - How much time left the user has to withdraw its remaining allowance in the allocated time period
     function getTime() public view returns(uint) {
         if (TimeCount[msg.sender] == 0) {
            return uint(0);
         } else {
             return(TimeCount[msg.sender] - block.timestamp);
         }
     }
}