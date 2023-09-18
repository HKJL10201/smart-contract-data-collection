// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract Ballot{

    address public officer;
    struct Voter{
        uint8 weight;
        string constituency;
        bool voted;
        uint8 vote;
    }

    struct Issue{
        string name;
        uint8 votecount;
        string location;
    }

    struct Vendor{
        string name;
        uint quotation;
        string place;
        bool givenQuotation;
    }

    Issue[] public issues;
    Vendor[] public Vendors;

    mapping(address => Voter) public voters;
    mapping(address => Vendor) public vendors;
    
    constructor(string[] memory issuenames, string[] memory locations){
        officer = msg.sender;
        voters[officer].weight = 1;

        for(uint i=0; i<issuenames.length; i++){
            issues.push(Issue({
                name : issuenames[i],
                votecount : 0,
                location : locations[i]
            }));
        }

    }

    function giveRightToVote(address voter) public {
        //identity is verified and authorized by the election officer
        require(msg.sender == officer,"Only officer can give right");
        require(!voters[voter].voted,"You have already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function vote(uint issueindex, string memory loc) public{
        //vote is casted and required checks are done
        Voter storage sender = voters[msg.sender];
        sender.constituency = loc;
        require(keccak256(abi.encodePacked(issues[issueindex].location)) == keccak256(abi.encodePacked(loc)),
        "Only vote for your constituency");
        require(sender.weight == 1,"You have no right to vote");
        require(!sender.voted,"You have voted already");
        sender.voted = true;
        issues[issueindex].votecount += 1;
    }

    function winningProposal() public view  returns (uint winningProposal_){
        //Issue with most number of votes is taken as a priority
        uint winningVoteCount = 0;
        for (uint i = 0; i < issues.length; i++) {
            if (issues[i].votecount > winningVoteCount) {
                winningVoteCount = issues[i].votecount;
                winningProposal_ = i;
            }
        }
    }

    function insertQuotation(string memory name,uint amount, string memory place) public{
        //Different vendors submit their bids for the task to be done in the relevant location
        Vendor storage v = vendors[msg.sender];
        v.place = place;
        require(keccak256(abi.encodePacked(place)) == keccak256(abi.encodePacked(issues[winningProposal()].location))
        ,"Tender can only be given according to the proposal's location");
        require(!v.givenQuotation,
        "Already submitted quotation");
        v.name = name;
        v.quotation = amount;
        v.givenQuotation = true;
        Vendors.push(v);    
    }

    function lowestTendor() public view returns(Vendor memory winningTendor){
        //Lowest bid is picked and contract is awarded to that vendor
        require(msg.sender == officer);
        uint256 smallest = 100000;
        for(uint8 i=0; i<Vendors.length; i++){
            if (Vendors[i].quotation < smallest){
                smallest = Vendors[i].quotation;
                winningTendor = Vendors[i];
            }
        }

    }
}
    



