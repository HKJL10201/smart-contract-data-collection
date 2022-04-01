pragma solidity ^0.4.17;
pragma experimental ABIEncoderV2;

contract votingSystem{

    //the variables
    struct candidate{
        address candidateAddress;
        uint voteCount;
    }
    candidate[] public candidates;
    address[] public voters;
    address public manager;

    //get manager address
    function votingSystem() public {
        manager = msg.sender;
    }

    //register candidate address
    function registerCandidate() public{
        // Check the manager can't register hisself as a candiate
        require(manager != msg.sender);
        // Check if candidate is already exist
        // for (uint i=0; i<=candidates.length; i++) {
        //     require(candidates[i].candidateAddress != msg.sender);
        // }  
        candidate memory m;
        m.candidateAddress = msg.sender;
        m.voteCount = 0;
        candidates.push(m);
    }

    //return all candidates
    // Method: 1
    // function getAllCandiates() public view returns (address[] memory){
    //     address[] memory candidatesList = new address[](candidates.length);
    //     for (uint i=0; i<=candidates.length; i++) {
    //         candidatesList[i] = candidates[i].candidateAddress;
    //     } 
    //     return candidatesList;
    // }

    // Method 2
    function getAllCandiates() public view returns (candidate[] memory){
        if(candidates.length > 0){
            return candidates;
        }
    }

    //register the vote
    function registerVote(string memory cAddress) public{
        if(candidates.length > 0){
            for (uint i=0; i<=candidates.length; i++) {
            if (keccak256(abi.encodePacked(cAddress)) == keccak256(abi.encodePacked(candidates[i].candidateAddress))) {
                candidates[i].voteCount = candidates[i].voteCount + 1;
                break;
            }
        }
        }
    }

    // get a winner
    function getWinner() public view returns(address[] memory){
    }
}