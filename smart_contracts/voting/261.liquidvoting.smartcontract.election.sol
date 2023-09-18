pragma solidity >=0.3.0;
contract Election{

  struct Proposal { // This is a type for a single proposal.
    bytes32 name;
    uint voteCount; // number of total votes
  }
  struct Voter {
    bool voted;
    uint vote;
    bytes32 aadhar_id;
  }

  mapping(address => Voter) public voters;

  address public curator;
  Proposal[] public proposals;
  mapping(address =>bytes32) voter; // wallet address mapped to aadhar-id

  function Election( bytes32[] proposalNames){
    curator = msg.sender;
    for(uint i = 0; i < proposalNames.length; i++){
      proposals.push(
        Proposal({
          name: proposalNames[i],
          voteCount: 0
          })
          );
        }

      }

      function addVoter(address  wallet_address, bytes32 aadhar_id){
        if (wallet_address == msg.sender){
          Voter sender = voters[msg.sender];
          sender.aadhar_id = aadhar_id;
        }
      }

      function addVote(uint proposal_index){
        Voter sender = voters[msg.sender];
        if (sender.voted)
        throw;
        sender.voted = true;
        sender.vote = proposal_index;
        proposals[proposal_index].voteCount += 1;
      }

      function show_count(uint proposal_index) returns(uint count){
        return proposals[proposal_index].voteCount;
      }

      }
