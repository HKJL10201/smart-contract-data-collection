pragma solidity ^0.4.24;

contract BlockShuffler {
    
    struct Shuffle {
        bytes32 hash;
        uint256 block;
    }
    
    uint8 constant VERIFY_BLOCKS = 1;
    mapping(address => Shuffle) private _shuffle;
    /*
    event Shuffling (
        address indexed account,
        bytes32 hash,
        uint256 block,
        uint256 timestamp
    );
   
    event Shuffled (
        address indexed account,
        bytes32 shuffleKey,
        uint256 finishBlock,
        bytes32 finishHash,
        bytes32 shuffle,
        uint256 timestamp
    );

     */
    constructor() public {}
    
    function startShuffle (bytes32 shuffleHash, uint8 verifyBlocks) internal returns(uint256 finishBlock) {
        require (verifyBlocks != 0, "verifyBlocks must be > 0");
        require (shuffleHash != 0x0, "Invalid zero hash");
        require (_shuffle[tx.origin].block == 0, "Already shuffling");
        
        finishBlock = block.number + verifyBlocks;
        _shuffle[tx.origin] = Shuffle (
            shuffleHash,
            finishBlock
        );

        /*
        emit Shuffling (
            msg.sender,
            _shuffleHash[shuffleId],
            _shuffleBlock[shuffleId],
            now
        );
        */
    }

    function finishShuffle (bytes32 shuffleKey) internal returns(bytes32 shuffle) {

        shuffle = getShuffle(shuffleKey);
        /*
        emit Shuffled (
            tx.origin, 
            shuffleKey,
            _shuffle[tx.origin].block,
            blockhash(finishBlock),
            shuffle,
            now
        );
        */
       delete _shuffle[tx.origin];

    }

    function abortShuffle () internal {
        if (_shuffle[tx.origin].block != 0) {
            delete _shuffle[tx.origin];
        }
    }

    function getShuffle (bytes32 shuffleKey) internal view returns(bytes32 shuffle) {
        require (
            shuffleKey != 0x0 && 
            _shuffle[tx.origin].hash == keccak256(abi.encodePacked(shuffleKey)),
            "Invalid shuffleKey."
        );
        require (
            _shuffle[tx.origin].block != 0 && 
            block.number > _shuffle[tx.origin].block,
            "Still shuffling."
        );
        if (block.number <= _shuffle[tx.origin].block + 255) {
            shuffle = keccak256(abi.encodePacked(
                shuffleKey,
                blockhash(_shuffle[tx.origin].block)
            ));
        }
    }

}
