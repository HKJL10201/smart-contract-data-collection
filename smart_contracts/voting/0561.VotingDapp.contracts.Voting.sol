pragma solidity >=0.4.22 <0.9.0;

contract Voting{
   

        address owner;
        uint public numberOfCandidates;
        mapping(address => bool) hasVote;
        constructor() {
            owner = msg.sender;
        }       

        struct candidate{
            string name;
            uint age;

        }

        candidate[] public candidates;
        mapping(uint=>uint) public votes;


        modifier owneronly{
            require(msg.sender == owner);
            _;
        }

        function addCandidate(string memory name, uint age) public owneronly {

           
            candidates.push(candidate(name,age));
            numberOfCandidates++;


        }

        function giveVote(uint _number) public {
            require(hasVote[msg.sender]==false);
            votes[_number]++;
            hasVote[msg.sender]=true;
        }






}