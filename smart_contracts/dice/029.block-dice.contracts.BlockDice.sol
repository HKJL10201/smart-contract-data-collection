pragma solidity ^0.4.24;
import "./BlockShuffler.sol";

contract BlockDice is BlockShuffler {

    address private _owner;//remove in production

    event Rolling (
        address indexed account,
        uint256 indexed block,
        uint256 timestamp
    );
    
    event Rolled (
        address indexed account,
        uint8 sides,
        uint8 count,
        uint8[] roll,
        uint256 timestamp
    );
    
    constructor() public {
       _owner = msg.sender;//remove in production
    }
    
    function startRoll (bytes32 hash, uint8 verifyBlocks) external 
        returns(uint256 finishBlock) {
        finishBlock = startShuffle(hash, verifyBlocks);
        emit Rolling (
            tx.origin,
            finishBlock,
            now
        );
    }

    function finishRoll (
        bytes32 key,
        uint8 sides,
        uint8 count
    ) external returns(uint8[] memory roll) {
        bytes32 rollHash = finishShuffle(key);
        roll = translateRoll(rollHash, sides, count);
        emit Rolled (
            tx.origin, 
            sides,
            count,
            roll,
            now
        );
    }

    function abortRoll () external {
        abortShuffle();
    }

    function getRoll (
        bytes32 key,
        uint8 sides,
        uint8 count
    ) external view returns(uint8[] memory roll) {
        bytes32 rollHash = getShuffle(key);
        roll = translateRoll(rollHash, sides, count);
    }

    //remove in production
    function destroy() external {
       require (msg.sender == _owner);
       selfdestruct(_owner);
    }
    
    //Return to sender, any abstract transfers
    function () external payable { msg.sender.transfer(msg.value); }


    function translateRoll (
        bytes32 rollHash, uint8 sides, uint8 count
    ) internal pure returns(uint8[] memory roll) {
        require (sides > 1 && sides <= 255, "count can be 2-255");
        require (count <= 32, "count can be 0-32");
        roll = new uint8[](count);
        if  (count > 0 && rollHash != 0x0) {
            for (uint8 i = 0; i < count; i++) {
                roll[i] = (uint8 (rollHash[i])) % sides;
            }
        } 
    }

}