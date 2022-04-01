pragma solidity >= 0.5.3 < 0.7.3;

contract AmigoLotterySystem{
    
    bool isPause ;
    
    address public owner;
    
    address[]   addressOfParticipant; // This keeps the address of the participants
    
    mapping(address => uint) private addressofLotteryParticipants; // This keeps track of amount deposited by the participants
    
    constructor() public {
        owner = msg.sender;
    }
    function  recieveEthersFromParticipation() payable public{
        require(msg.value >=1,"Minimum of 1 ether is required to participate in the lottery system");
        require(!isPause,"Lottery System is paused!! Try next time");
        addressofLotteryParticipants[msg.sender] = msg.value;
        addressOfParticipant.push(msg.sender);
        
    }
    
    function transferEtherToWinner() public OnlyOwner{
        
        uint randwinner = randomWinner();
        address payable Winner = payable(addressOfParticipant[randwinner]);
        Winner.transfer(address(this).balance);
       // ResetTheLotterySystem();  function to reset
        addressOfParticipant =new address[](0); // other method of reseting
        
    }
    
    function randomWinner() private  OnlyOwner view returns(uint) {
        
        
        uint randNumber = uint(sha256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender , addressOfParticipant))) % addressOfParticipant.length;
        
        return(randNumber);
    }
    
    //Function to reset
    // function ResetTheLotterySystem() private OnlyOwner{
        
    //     uint value= 0;
    //     for(uint i = 0; i < addressOfParticipant.length; i++){
    //         addressOfParticipant[i] = address(value);
    //     }
    // }
    
    function getPlayers() public view returns(address[] memory){
        
         return addressOfParticipant;
     } 
     
     function setPause(bool _ispause) OnlyOwner public{
         
         isPause = _ispause;
     }
     
    modifier OnlyOwner(){
        require(msg.sender == owner, "Only owner has the access!!");
        _;
    }
}
