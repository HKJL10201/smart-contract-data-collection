// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


interface IVotingContract{

//only one address should be able to add candidates
    function addCandidate(address _candidate, string memory _name) external returns(bool);

    
    function voteCandidate( uint candidateId) external returns(bool);

    //getWinner returns the name of the winner
    function getWinner() external returns(address, string memory, uint);
}



///@notice Voting smart contract written in solidity.
contract VotingContract is IVotingContract{

        /// @notice chair person
        address public owner;

        Candidate[] public candidatesList;
        Voter[] public votersList;
        mapping(address =>Voter) public voters;
        uint startTime;
        
        struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    struct Candidate {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votesa
        address id;
    }

    constructor(){
        owner = msg.sender;
        startTime = block.timestamp;

    }



    function addCandidate(address _candidate, string memory _name) external returns(bool added){

        ///You can add candidates for only three minutes after the deployment of the contract
        require(block.timestamp <= startTime + 180, "Time to add candidate is past");
    
        require(msg.sender == owner, "Only chairperson can add candidate");
        //require(!voters[_candidate].voted);

      bytes32 candidateName =  stringToBytes32(_name);
   
        //Check if the _candidate is already in the list 
        // if YES, do not add. If NO add the candidate to the list
        for( uint i = 0; i < candidatesList.length; i++){
            
            if(candidatesList[i].id != _candidate){

            Candidate memory _candidate1 = Candidate({name:candidateName, voteCount:0, id:_candidate});

             candidatesList.push(_candidate1);

             added = true;
             return added;

            }
        }

          
    }


        ///@notice A function that gies right to individuals to vote
    function giveRightToVote(address voter)public{
        
        require(msg.sender == owner ,"Only the chair person can broadcast result");

            require(!voters[voter].voted,"You have voted");

            require(voters[voter].weight ==0,"Voter can not be authroise to vote" );

            voters[voter].weight = 1;


        }

        ///@notice A function that enables voters to vote
    function voteCandidate(uint proposal) external returns(bool){
        ///You can add candidates for only three minutes after the deployment of the contract

        Voter memory sender = voters[msg.sender];
        require(block.timestamp >= startTime + 180 || block.timestamp <= startTime + 360, "Not time to vote");
        require(!sender.voted);
        require(sender.weight !=0, "has no right to vote" );

        sender.voted = true;
        sender.vote = proposal;

        candidatesList[proposal].voteCount += sender.weight;
        
        return true;
    }

    function getWinner() external view returns(address   winnerId_, string memory winnerName_, uint voteCount_){

       require(block.timestamp >= startTime + 360, "Not time to get result");
        
        uint winner = 0;
        uint listLength = candidatesList.length;

        require(listLength == 0, "No candidate was registered!");

        for(uint i=0; i < listLength ; i++){
            if(candidatesList[i].voteCount > winner){
                winner = candidatesList[i].voteCount;
                 winnerId_ = candidatesList[i].id;
                 winnerName_ = bytesToString(candidatesList[i].name);
                  voteCount_ = candidatesList[i].voteCount;

            }

        }
    }


    ///@notice A function that converts string to bytes32 
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {

    bytes memory tempEmptyStringTest = bytes(source);

    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

    ///@notice A function that converts bytes32 to string
    function bytesToString(bytes32 name) public pure returns(string memory){
        uint8 i =0;
        while(i < 32 && name[i] != 0 ){
                 
            i++;
        }
        bytes memory anotherName =  new bytes(i);
        for(i = 0; i < 32 && name[i] != 0; i++){

            anotherName[i] = name[i];
        }
        return string(anotherName);

    }


}
