pragma solidity ^0.5.0;

contract Lottery {
    
    //----STATE VARIABLES-----
    //Manager = address of the EOA that deployed the contract and start the Lottery
    address public Manager;
    
    //List of all players
    address payable[] public PlayerAddresses;
    
    
    //----CONSTRUCTOR-----
    constructor() public {
        //initialized the Manager state variable
        Manager = msg.sender;
    }
    
    //----FUNCTIONS-----
    //Callback function that will add address to PlayerAddresses
    function () external payable HasValidAmount {
       PlayerAddresses.push(msg.sender); 
    }
    
    //Calling this function will add the address to the PlayerAddresses
    function EnterLottery() payable public HasValidAmount {
        PlayerAddresses.push(msg.sender);
    }
    
    //Calling this function will return the current balance of the contract
    function GetBalance() public view Restricted returns (uint256) {
        return address(this).balance;
    }
    
    //Calling this function will generate a number of random kind
    function GetRandomNumber() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, PlayerAddresses.length)));
    }
    
    //Calling this function will give us the winner
    function GetLotteryWinner() public payable  Restricted returns (address) {
        uint randomNo = GetRandomNumber();
        uint winnerNo = (randomNo % PlayerAddresses.length);
        
        address payable winnerAddress = PlayerAddresses[winnerNo];
       
        //transfer the balance to the winner
        winnerAddress.transfer(address(this).balance);
        
        //reset the PlayerAddresses
        PlayerAddresses = new address payable[](0);
        
        return winnerAddress;
    }
    
    //----MODIFIERS
    //Modifier that will check if the ether amount being entered is greater than 0.01 
    modifier HasValidAmount() {
        require(msg.value > 0.01 ether,"Accepted value is greater than or equal to 0.01 ether.");
        _;    
    }
    
    //Modifier that will check if the address is equal to manager address
    modifier Restricted() {
        require(msg.sender == Manager,"Only manager can use this function.");
        _;
    }
}