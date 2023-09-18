pragma solidity ^0.5.0;

contract Voting
{
    struct CandidateInfo
    {
        string name;
        uint age;
        uint totalVotes;
        // other info
    }

    struct voterInfo
    {
        string name;
        uint16 age;
        bool voted;
        // other info
    }

    mapping(address => CandidateInfo) public candidateList;
    address[] public candidateAddrList;
    
    mapping(address => voterInfo) public voterList;
    address[] public voterAddrList;

    function SetCandidateInfo(address candidateAddr, string memory _name, uint _age) public
    {
        candidateList[candidateAddr].name = _name;
        candidateList[candidateAddr].age = _age;
        candidateList[candidateAddr].totalVotes = 0;

        candidateAddrList.push(candidateAddr);
    }

    function GetCandidateName(address addr) public view returns(string memory)
    {
        return candidateList[addr].name;
    }

    function SetVoterInfo(address _voterAddress, string memory _name, uint16 _age) 
    public
    {
        voterList[_voterAddress].name = _name;
        voterList[_voterAddress].age = _age;
        voterList[_voterAddress].voted = false;

        voterAddrList.push(_voterAddress); 
    }

    function GetVoterName(address addr) public view returns(string memory)
    {   
        return (voterList[addr].name);
    }

    function GiveVote(address _voterAddr, address _candidateAddr) public 
    {
        require(voterList[_voterAddr].voted == true, "Voter has already voted");

        candidateList[_candidateAddr].totalVotes += 1;
        voterList[_voterAddr].voted = true;
    }

    function Result() public view returns(string memory, uint)
    {
        uint res = 0;
        string memory winner;

        for(uint i = 0; i < candidateAddrList.length; ++i)
        {
            if(res < candidateList[candidateAddrList[i]].totalVotes)
            {
                res = candidateList[candidateAddrList[i]].totalVotes;
                winner = candidateList[candidateAddrList[i]].name;
            }  
        }
        return(winner, res);
    }

}
