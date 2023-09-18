// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "hardhat/console.sol";



interface IVotingContract{

//only one address should be able to add candidates
    function addCandidate(string memory _name, string memory candid1) external;


    function voteCandidate(uint voteIndex) external ;

    //getWinner returns the name of the winner
    function getWinner() external;
}

contract Election
{
    uint startTime;

    struct Candidate{ //custom data type to define a candidate struct
        string name;   // short name using string
        uint voteCount; // number of accumulated votes
    }

    struct Voter{//store wether or not they have voted and who they have voted for
        bool voted;
        uint voteIndex;
        uint weight;
    }

    address public chairperson; //keeping track of the owner of the contract,
    //they have special rights to authorize voters
    string public name;

    mapping(address => Voter) public voters; //mapping to store voter info

    Candidate[] public candids;

    event ElectResults(string name, uint voteCount);

    constructor() {
        startTime = block.timestamp;
    }

    function addCandidate(string memory _name, string memory candid1) public payable //timerOver
    {   chairperson = msg.sender;
        require(block.timestamp <= startTime + 180, "Time exceeded for registring. Let them Vote!");
        //require messages are too long, they add to code size
        name = _name;

        candids.push(Candidate(candid1, 0)); //defining candidates obj using names

    }

    function authorize (address voter) public payable
    {
        require(msg.sender == chairperson);
        require(!voters[voter].voted);

        voters[voter].weight = 1; //only count people we authorize withe weight of one;

    }

    function showCandidate() public view{ //returns (string[uint] memory)


        for(uint i = 0; i < candids.length; i++)
            {
               console.log (i, candids[i].name);
            }

    }

    function voteCandidate(uint voteIndex) public //timerOver1
    {
             require(block.timestamp > startTime + 180, "Time not exceeded for registering");
             require(block.timestamp <= startTime + 380, "Time exceeded for voting. View results");

            require(!voters[msg.sender].voted, "Has already voted");
            require(voters[msg.sender].weight != 0, "Has no right to vote");
            voters[msg.sender].voted = true;
            voters[msg.sender].voteIndex = voteIndex;

            candids[voteIndex].voteCount += voters[msg.sender].weight;

    }

    function getWinner() public
    {

            require(msg.sender == chairperson);

            for(uint i = 0; i < candids.length; i++) //spend gas here, don't do it again
            //using index if loss of data
            {
                //require(block.timestamp > startTime + 120);
                emit ElectResults(candids[i].name, candids[i].voteCount);
                console.log(candids[i].name, candids[i].voteCount);
            }

    }


}
