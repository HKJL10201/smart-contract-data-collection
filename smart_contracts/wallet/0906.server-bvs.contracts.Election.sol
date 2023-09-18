// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

contract Election{

    address admin;
    bool registrationPhase = false;
    bool votingPhase = false;

    //Candidate data structures
    mapping(address=> Candidate) candidate;
    Candidate[] governorCandidates;
    Candidate[] presidentCandidates;

    //Voter data stuctures
    mapping(address=>Voter) voters;
    Voter[] allVoters;

    //Votes
    address[] presidentVotes;
    address[] governorVotes;

    struct Voter {
        address voter;
        bool votedPresident;
        bool votedGovernor;
        bool registered;
    }

    struct Candidate{
        string name;
        address addr;
        string position;
        uint votes;
    }

    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(msg.sender==admin, "Only admins are permitted to do this");
        _;
    }

    modifier RegistrationPhase (){
        require(registrationPhase==true,"Registration phase is not open");
        _;
    }

    modifier VotingPhase(){
        require(votingPhase==true, "Voting phase not open");
        _;
    }

    function CastPresident(address _address) VotingPhase public returns(bool){
        string memory president = "president";
        if (!voters[msg.sender].votedPresident && keccak256(abi.encodePacked(candidate[_address].position)) == keccak256(abi.encodePacked(president))){
            presidentVotes.push(msg.sender);
            candidate[_address].votes++;
            voters[msg.sender].votedPresident=true;
            return true;
        }
        return false;
    }

    function CastGovernor(address _address) VotingPhase public returns (bool){
        string memory governor = "gorvenor";
        if (!voters[msg.sender].votedGovernor && keccak256(abi.encodePacked(candidate[_address].position)) == keccak256(abi.encodePacked(governor))){
            governorVotes.push(msg.sender);
            candidate[_address].votes+=1;
            voters[msg.sender].votedGovernor=true;
            return true;
        }
        return false;
    }

    function RegisterCandidate(address _address, string memory _name, string memory position) RegistrationPhase onlyAdmin public returns(bool){
        string memory president = "president";
        string memory governor = "governor";
        if (keccak256(abi.encodePacked(position)) == keccak256(abi.encodePacked(president))){
            for (uint i=0; i<presidentCandidates.length; i++){
                if (presidentCandidates[i].addr==_address){
                    return false;
                }
            }
            Candidate memory newCandidate = Candidate({name: _name, addr: _address,votes: 0, position:position});
            candidate[_address]=newCandidate;
            presidentCandidates.push(newCandidate);
            return true;
        }
        if (keccak256(abi.encodePacked(position)) == keccak256(abi.encodePacked(governor))){
            for (uint i=0; i<governorCandidates.length; i++){
                if (governorCandidates[i].addr==_address){
                    return false;
                }
            }
            Candidate memory newCandidate = Candidate({name: _name, addr: _address, votes: 0, position: position});
            candidate[_address]=newCandidate;
            governorCandidates.push(newCandidate);
            return true;
        }
        return false;
    }

    function RegisterVoter (address _address) RegistrationPhase onlyAdmin public returns (bool){
       Voter memory voter = Voter({
           voter:_address,
           votedPresident: false,
           votedGovernor: false,
           registered: true               
       });
       if (!voters[_address].registered){
           voters[_address]=voter;
           allVoters.push(voter);
       }else{
           return false;
       }
       return true;
    }

    function GetAllVoters() public view returns(Voter[] memory){
        return allVoters;
    }

    function GetGovernorCandidates() public view returns(Candidate[] memory){
        return governorCandidates;
    }

    function GetPresidentCandidates() public view returns (Candidate[] memory){
        return presidentCandidates;
    }

    function GetCandidateVotes(address _address) public view returns (uint){
        return candidate[_address].votes;
    }

    function ChangeRegistrationPhase() public onlyAdmin returns(bool) {
        registrationPhase=!registrationPhase;
        return registrationPhase;
    }

    function GetPresidentialVotes() public view returns(address[] memory){
        return presidentVotes;
    }

     function GetGubernatorial() public view returns(address[] memory){
        return governorVotes;
    }

    function GetSpecificCandidate(address _addr) public view returns (Candidate memory){
        return candidate[_addr];
    }


    function ChangeVotingPhase() public onlyAdmin returns(bool){
        votingPhase=!votingPhase;
        return votingPhase;
    }

    function GetRegisrationPhase() public view returns(bool){
        return registrationPhase;
    }

    function GetVotingPhase() public view returns (bool){
        return votingPhase;
    }

}