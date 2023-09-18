pragma solidity ^0.5.0;

contract DiceGame {
    struct Play{
        uint8  target; // this is target
        bool  isSet; //default value is false 
        uint8  destiny; // our outcome
        }
    mapping(address => Play) private ply;
    uint8 private randomFactor;
    
    event NewSet(address player , uint8 target);
    event GameResult(address player, uint8 target , uint8 destiny);
    
    function getNewbet() public returns(uint8){
        require(ply[msg.sender].isSet == false);
        ply[msg.sender].isSet = true;
        ply[msg.sender].target = random();
        randomFactor += ply[msg.sender].target;
        emit NewSet(msg.sender, ply[msg.sender].target);
        return ply[msg.sender].target;
        }
    
    function roll() public returns(address , uint8 , uint8){
        require(ply[msg.sender].isSet == true);
        ply[msg.sender].destiny = random();
        randomFactor += ply[msg.sender].destiny;
        ply[msg.sender].isSet = false;
        if(ply[msg.sender].destiny == ply[msg.sender].target){
   
            emit GameResult(msg.sender, ply[msg.sender].target, ply[msg.sender].destiny);   
            }
            else{
            emit GameResult(msg.sender, ply[msg.sender].target, ply[msg.sender].destiny);
            }
            return (msg.sender , ply[msg.sender].target , ply[msg.sender].destiny);
        }
        
    function isBetSet() public view returns(bool){
        return ply[msg.sender].isSet;
        }
    function random() private view returns (uint8) {
        uint256 blockValue = uint256(blockhash(block.number-1 +    block.timestamp));
        blockValue = blockValue + uint256(randomFactor);
        return uint8(blockValue % 5) + 1;
        }

}
