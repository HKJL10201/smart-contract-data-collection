pragma solidity ^0.5.1;

contract theMultiLottery {


    address payable [] public players;
    mapping (address => bool) public uniquePlayers;
    address payable[] public winners;
//    address payable public winner;

uint256 drawnBlock = 0;  //define last. To ensure two of same drawn nrs are not done

function() external payable {
    play(msg.sender);
}
    
function play(address payable _participant) payable public {
    require (winners.length < 2);
    require (msg.value == 1000000000000000000);  //1eth
    require(uniquePlayers[_participant] == false);
    players.push(_participant);
    uniquePlayers[_participant] = true;
}

    function draw () external {
//      require (now > 1522908000);
        require (block.number != drawnBlock);
        require (winners.length < 2);
        drawnBlock = block.number;
        uint256 winningIndex = randomGen();   //local vars stored in memory
        address payable winner = players[winningIndex];
        winners.push(winner);
        players[winningIndex] = players[players.length - 1];
        players.length--;
        
        if (winners.length == 2) {
            payout();
        }
}

      function payout () private {
          
//        winner.transfer(address(this).balance);
//        selfdestruct(winner);       
        //charity.transfer(address(this).balance)
//            uint256 half = (address(this).balance)/2;
            winners[0].transfer((address(this).balance)/2);
            winners[1].transfer(address(this).balance);
            
      }
          
    
    function randomGen() view public returns(uint256 randomNumber) {
 //       uint256 seed = uint256(blockhash(block.number -200));
 //       return(uint256(keccak256(block.blockhash(block.number - 1)))%players.length);
    uint256 rand = uint256((blockhash(block.number-1)));
    return uint256(rand % players.length);
// return 2;

    }
    
}




