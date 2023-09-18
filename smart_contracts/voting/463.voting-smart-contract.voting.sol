pragma solidity  ^0.8.17;
// SPDX-License-Identifier: GPL-3.0
contract voting{
    // state variables
    address public chairperson;
    struct Voters{
        bool voted;
        address delegate;
        uint vote;
        uint weight;
        
    }

    mapping(address=>Voters) public voters;
    struct Candidates{
        string  candidate_name;
        
        uint no_of_votes;
    }

    Candidates[]  public candidates;

    constructor(string[] memory members)  {
            chairperson = msg.sender;
            voters[chairperson].weight = 1;
            for(uint i=0;i<members.length;i++)
            {
                candidates.push(Candidates({
                        candidate_name: members[i],no_of_votes:0
                }));
            }
    }

    function register(address voter) public
    {
        require(msg.sender == chairperson);
        require(voters[voter].voted == false);
        voters[voter].weight = 1;
    }

    function voting_process(uint vo) public 
    {
            require(voters[msg.sender].weight !=0);
            require(!voters[msg.sender].voted);

            
            
                voters[msg.sender].vote = vo;
                voters[msg.sender].voted = true;
                candidates[vo].no_of_votes += 1;
            
    }

    function reveal_winner() public view returns (uint winning_candidate)
    {
        uint winningvotecounts = 0;
        for(uint i=0;i<candidates.length;i++)
        {
                if(winningvotecounts<candidates[i].no_of_votes)
                {
                    winningvotecounts = candidates[i].no_of_votes;
                    winning_candidate = i;
                }
               
        }
    }
}
