// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <=0.7.0;
pragma experimental ABIEncoderV2;

contract voting{
    // DECLARATIONS -----------------------------------------    
    address public owner;

    //constructor
    constructor () public{
        owner = msg.sender;
    }

    // map names and hashes
    mapping(string => bytes32) idCandidate;

    // map candidates and votes counter
    mapping(string => uint) candidateVotes;

    // candidates list
    string[] candidates;

    // voters' hashes list
    bytes32[] voters;


    // CANDIDATES -------------------------------------------
    function NewCandidate(string memory _name, uint _age, string memory _candidateId) public{
        // candidates' data hash
        bytes32 candidatesHash = keccak256(abi.encodePacked(_name, _age, _candidateId));

        // store candidates' data
        idCandidate[_name] = candidatesHash;

        // store candidate in list
        candidates.push(_name);
    }

    function ViewCandidates() public view returns(string[] memory){
        return candidates;
    }

    // VOTING -----------------------------------------------
    function vote(string memory _candidate) public{
        // store voter's hash in array to avoid multiple votes per address
        bytes32 votersHash = keccak256(abi.encodePacked(msg.sender));

        for(uint i=0; i < voters.length; i++){
            require(voters[i] != votersHash, "You've already voted!");
        }

        voters.push(votersHash);
        candidateVotes[_candidate] += 1;
    }

    // VIEW VOTES -------------------------------------------
    function ViewVotes(string memory _candidate) public view returns(uint){
        return(candidateVotes[_candidate]);
    }
    
    // VIEW RESULTS -----------------------------------------
    function ViewResults() public view returns(string memory){
        string memory results = "";
        
        for(uint i=0; i < candidates.length; i++){
            results = string(abi.encodePacked(results, "(", candidates[i], ", ", uint2str(ViewVotes(candidates[i]))));
        }

        return(results);
    }

    // AUX (uint to string) ----------------------------------
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // VIEW WINER -----------------------------------------
    function Winner() public view returns(string memory){
        string memory winner = candidates[0];
        bool tie;

        for(uint i=1; i < candidates.length; i++){
            if(candidateVotes[candidates[i]] > candidateVotes[winner]){
                winner = candidates[i];
                tie = false;
            }
            else{
                if(candidateVotes[candidates[i]] == candidateVotes[winner]){
                    tie = true;
                }
            }
        }

        if(tie){
            winner = "It's a tie!";
        }
        return(winner); 
    }

}