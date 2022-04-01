pragma solidity ^0.4.18;
// We have to specify what version of compiler this code will compile with

contract Voting {
    // TODO : getVoteCandidateList
    struct Poll {
        // method 1
        bool exists;
        bytes32[] public candidateList;
        bytes32[] public NameList;
        mapping(bytes32 => Human) public humans;
    }

    struct Human {
        uint8 count;
    }

    mapping( uint8 => poll ) public polls;

    function createPoll( uint8 _roomNumber ) public {
        require( !polls[_roomNumber].exists );

        polls[_roomNumber] = Poll( true, , , );
    }

    function removePoll( uint8 _roomNumber ) public {
        require( polls[_roomNumber].exists );

        delete polls[_roomNumber];
    }


    function insertCandidate( uint8 _roomNumber, bytes32 _candidate, bytes32 _Name ) public {
        require( !validCandidate( _roomNumber, _candidate ) );  
   
        polls[_roomNumber].candidateList.push(_candidate);
        polls[_roomNumber].NameList.push(_Name);
        polls[_roomNumber].human[_candidate] = Human ( 0 );
    }

    function removeCandidate( uint8 _roomNumber, bytes32 _candidate ) public {
        require( validCandidate( _roomNumber, _candidate ) );

        delete polls[_roomNumber][_candidate];
    }

    function getCandidateList(uint8 _roomNumber) view public returns ( bytes32[] ) {
        bytes32[] memory c;
        require( polls[_roomNumber].exists );
        c = polls[_roomNumber].NameList;
        return ( c );
    }

    // This function returns the total votes a candidate has received so far
    function totalVotesFor( uint8 _roomNumber, bytes32 _candidate ) view public returns ( uint8 ) {
        require( validCandidate( _roomNumber, _candidate ) );
        return polls[_roomNumber][_candidate].count;
    }

    // This function increments the vote count for the specified candidate. This
    // is equivalent to casting a vote
    //TODO : Edit argc
    function voteForCandidate( uint8 _roomNumber, bytes32 _candidate ) public {
        require(validCandidate( _roomNumber, _candidate ) ) ;
        polls[_roomNumber][_candidate].count += 1;
    }

    // method 2
    function validCandidate( uint8 _roomNumber, bytes32 _candidate ) view public returns ( bool ) {
        uint leng;
        require( polls[_roomNumber].exists );
        leng = polls[_roomNumber].candidateList.length;

        for( uint i = 0; i < leng; i++ ) {
            if ( polls[_roomNumber].candidateList[i] == _candidate ) {
                return true;
            }
        }
        return false;
    }


}