pragma solidity ^0.4.22;

contract Random {
    mapping(uint => uint) commonRandom;

    function randomNewLucky() public payable returns(uint, uint, uint, uint, uint, uint ) {
        uint winner = uint(keccak256(abi.encodePacked(block.timestamp+block.number+uint(blockhash(block.number)))))%6;
        uint loser = uint(keccak256(abi.encodePacked(winner+block.timestamp+block.number+uint(blockhash(block.number)))))%6;
        uint count = 0;

        if( winner == loser ){
            loser = (winner+1)%6;
        }
        for( uint i=0; i<=6; i++ ){
            if( i!=winner && i!=loser ){
                commonRandom[count] = i;
                count = count+1;
            }
        }
        count = 0;
        return ( winner, loser, commonRandom[0],commonRandom[1],commonRandom[2],commonRandom[3] );
    }

    function randomArrLucky() public payable returns(uint256[6] memory) {
        uint winner = uint(keccak256(abi.encodePacked(block.timestamp+block.number+uint(blockhash(block.number)))))%6;
        uint loser = uint(keccak256(abi.encodePacked(winner+block.timestamp+block.number+uint(blockhash(block.number)))))%6;
        uint count = 0;

        if( winner == loser ){
            loser = (winner+1)%6;
        }
        for( uint i=0; i<=6; i++ ){
            if( i!=winner && i!=loser ){
                commonRandom[count] = i;
                count = count+1;
            }
        }
        count = 0;
        return [winner, loser, commonRandom[0],commonRandom[1],commonRandom[2],commonRandom[3] ];
    }
}