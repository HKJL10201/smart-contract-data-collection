pragma solidity >=0.4.22 <0.6.0;

contract EthWallet {
    // Variable to store managers address
    address public manager;
    
    // Storing addresses of participants
    address[] public participants;
    
    constructor () public {
        manager = msg.sender;
    }
    
    //Function to enter the lottery, make each user pay small gas fee
    function enterLottery() public payable {
        
        require(msg.value > 0.01 ether);
        participants.push(msg.sender);
    }
        
    function pickWinner() public { 
         // Only Manager can call pick winner
        require(msg.sender == manager);
         // Select Random participant
        uint index = random() % participants.length;
         // Transfer Balance of contract to participant
        participants[index].transfer(this.balance);
         // empty participants array
        participants = new address[](0);
    }
        
    function random() private view returns(uint256){
            // create random uint256 number
    return uint(keccak256(block.difficulty, now, participants));
    }
        
}