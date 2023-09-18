//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract Polling{


    uint32 public ID = 1;


    struct voteDetails{
        address voteOwnerAddress; 
        string Topic;
        string Details;
        string bannerURL;
        uint120 _noOfVOte;
        Rating rate;
        uint32 votingPeriod;
        uint32 No; 
        uint32 Undecided;
        uint32 Yes; 
    }

    enum Rating{
        No,
        Undecided,
        Yes   
    }

    mapping (uint => voteDetails) _votedetails;

    mapping(address => mapping(uint => bool)) hasVoted;

    modifier exists(uint _id){
        require(_id < ID, "vote does not exist");
        _;
    }

    
    function createVote(
        string memory _topic, uint duration, string memory bannerLink, string memory _details
        ) 
        external returns(uint, string memory)
    {
        voteDetails storage VD =  _votedetails[ID];
        VD.voteOwnerAddress = msg.sender;
        VD.Topic = _topic;
        VD.Details = _details;
        VD.bannerURL = bannerLink;
        VD.votingPeriod = uint32(block.timestamp + (duration * (1 days)));
        uint currentId = ID;
        ID++;
        return(currentId, "Created Succesfully");
    }

    
    function Vote(uint32 _id, uint _rate) external exists(_id){

        require(hasVoted[msg.sender][_id] == false, "already voted");
        require(_rate <= 2, "invalid Rating");

        voteDetails storage VD =  _votedetails[_id];

        require(block.timestamp <= VD.votingPeriod, "Voting has ended");

        hasVoted[msg.sender][_id] = true;
        VD._noOfVOte++; 

        if (_rate == 0){
            VD.No += 1;
            VD.rate = Rating.No;
        }else if (_rate == 1){
            VD.Undecided += 1;
            VD.rate = Rating.Undecided;
        } else{
            VD.Yes += 1;
            VD.rate = Rating.Yes;
        }        
    }

    function getVoteDetails(uint _id) 
        external view exists(_id)
        returns(address, string memory, string memory, uint, uint32, string memory, uint32, uint32, uint32)
    {
        voteDetails storage VD =  _votedetails[_id];
        return(
            VD.voteOwnerAddress, 
            VD.Topic, VD.Details, 
            VD._noOfVOte, 
            VD.votingPeriod, 
            VD.bannerURL, 
            VD.No, 
            VD.Undecided, 
            VD.Yes
        );
    }

    //this function returns the timeleft for a particular poll
    function timeLeft(uint _id) external view exists(_id) returns(uint32) {
        voteDetails storage VD =  _votedetails[_id];
        return uint32(VD.votingPeriod - block.timestamp);
    }


}