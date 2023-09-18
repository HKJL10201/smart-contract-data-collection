pragma solidity ^0.5.0;

contract Lottery{
    //Participants to be mapped with their address and money invested
    mapping(address => uint) participants;
    //Owner 
    address public owner;
    //array of address of participant to iterate
    address[] participantsAddresses;
    address winner;
    //Short hand function can be called by using isOwner anywhere and restrict that function to be owner only can call
    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
    
    //constructor
    constructor() public {
        //msg object which contains address attribute
        owner = msg.sender;
    }
    
    //Function to participate people
    function participate() public payable {
        //payable means invocation of this method one can send money
        //msg.sender has address and msg.value has value of transaction sent
        uint value = msg.value;
        //To add condition for minimum value required for participation to register
        //One suggestion is more amount invested make his chance to win more so we will currently fix it to 0.005 a base
        require( value == 0.005 ether);
        
        //add to dictionary
        participants[msg.sender] = value;
        participantsAddresses.push(msg.sender);       
    }
    
    //Random number generator
    //isOwner is a short hand function which says that only Owner can call this function 
    function luckyDraw() public isOwner{
        // There is no random number generator create your own random logic
        uint randomNumber = random();
        
        winner = participantsAddresses[randomNumber];
    }
    
    function withdrawFund() public {
        require(msg.sender == winner);
        // to transfer amount to winners account using transfer function
        // address(this) is smart contracts balance
        msg.sender.transfer(address(this).balance);
    }
    //public used by all user accounts and contracts
    //private used by only internal functions or contracts but not by user accounts
    //write pays ether and read does not costs
    //One can add external appication in contracts but you don't as of security issues
    //view means one cannot change any value in it (readonly function)
    function random() private view returns (uint){
        return participantsAddresses.length - 2;
    }
}


// Storage (state variable are always storage)
// memory

// User Account storage and contract storage addresses
//eg: https://rinkeby.etherscan.io/tx/0xfda56d306c85701744e4191ea6b25e9108a562013c7be111d6f54682a57a77d2


//Method to UI deployment
//1
//OneclickDapp https://oneclickdapp.com/arrow-brenda/
// Just give a name and enter in new tab place contract ABI and contract address after deploy and select test network on which it is placed
// Now anyone can access from your Dapp to your contract


//2
//go to https://github.com/vineettyagi28/ethereum-dapp
// clone and npm install
