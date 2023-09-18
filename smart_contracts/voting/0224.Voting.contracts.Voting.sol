pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract Voting{

  struct Voter{
    address voterAddress;
    uint vote; //index of candidate voted for
    bool didVote; //false until voter did vote
    //voter can only vote when weight is >= 1!
    uint weight; //increases when someone delegates his/her vote to this voter or voteMaster approves voter!
    address delegate; //address that gets delegated with the vote
  }

  struct Candidate{
    bytes32 name;  //name of candidate
    uint votes;    //keeps track of votes given to this candidate
  }

  address public voteMaster; //voteMaster is the address approving voterAddress

  mapping (address => Voter) public voters; //connects address to Voter structs

  Candidate[] public candidates; //stores all candidates input by the voteMaster (deployer) in the constructor


  constructor(bytes32[] memory candidateNames) public {
    voteMaster = msg.sender;
    voters[voteMaster].weight = 1;

    for (uint i = 0; i < candidateNames.length; i++){  //pushes all candidate names of candidateName[] (from constructor input) to candidates[] (state array) and sets votes to 0
      candidates.push(Candidate({
        name: candidateNames[i],
        votes: 0
      }));
    }
  }


  //gets length for candidate array
  function candLength() public view returns(uint nrOfCandidates_){
    return nrOfCandidates_ = candidates.length;
  }



  //New approve function with input bytes20 to get input from through javascript in main.js, so voteMaster can input address in html from in bytes20 format to approve
  function approveVoter(address voter) public payable {
    require(msg.sender == voteMaster, "Only voteMaster can approve Voters!");
    require(!voters[voter].didVote, "Voter already voted!");
    require(voters[voter].weight == 0);


    voters[voter].weight = 1;
  }
/*
  //Voters validation function, only voteMaster(contrat owner) can execute
  function approveVoter(address voter) public {
    require(msg.sender == voteMaster, "Only voteMaster can access this function!");
    require(!voters[voter].didVote, "Voter already voted!");
    require(voters[voter].weight == 0);

    voters[voter].weight = 1;
  }
*/
  function vote(uint candidate) public payable {
    Voter storage sender = voters[msg.sender]; //creates Voter variable and sets it to voters[msg.sender]
    require(!sender.didVote, "You already did vote!");  //checks if msg.sender did already vote
    require(sender.weight > 0, "You are not approved as voter!");

    sender.didVote = true;
    sender.vote = candidate;

    candidates[candidate].votes += sender.weight;

  }

  function delegateVote(address to) public payable {
    Voter storage sender = voters[msg.sender]; //creates Voter variable sender for msg.sender to have cleaner code for require statement!
    require(!sender.didVote, "You cannot delegate your vote because you already voted!");
    require(to != msg.sender, "You cannot delegate your vote to yourself!");
    require(sender.weight > 0, "You are not approved as voter and can only delegate once you are!");

    while(voters[to].delegate != address(0)){ //as long as voters to delegate is not equal to zero address, (in case to also delegates his/her vote),

      to = voters[to].delegate;               // set to-address equal to voters to delegate, somehow this logic makes me crazy, haha.
      require(to != msg.sender, "Found loop in delegation!!");
    }

    sender.didVote = true; //set senders vote status to true;
    sender.delegate = to; //set senders delegate to "to" address

    Voter storage delegate_ = voters[to]; //creates Voter variable for delegate to help ourselves in the if statements! makes a cleaner code than to write voters[to] all the time
    if(delegate_.didVote){ //check if delegate already didVote, if yes:
      candidates[delegate_.vote].votes += sender.weight; //Ok this is tricky. If delegate already did vote, then we add the weight of the sender(that delegate his vote to the delegate) instantly to the candidate that the delegate voted for!
    }
    else { //if delegate did not vote yet we:
      delegate_.weight += sender.weight; //add senders weight to delegates weight.
    }
  }

  function electionWinner() public view returns(uint electionWinner_){  //will return the id of the candidate with the most votes!
      uint VotesCount = 0;                            //to store votes
      for (uint p = 0; p < candidates.length; p++) {  //loops through all candidates
          if (candidates[p].votes > VotesCount) {     //and checks if the candidates votes are higher than the votesCount
            VotesCount = candidates[p].votes;         //If so, then sets the VotesCount equal to the candidates votes
            electionWinner_ = p;                      //and returns candidate ID as electionWinner_
          }
      }
  }

  function theWinnerIs() public view returns(bytes32 winnerName_){  //returns name of the winner
      return winnerName_ = candidates[electionWinner()].name;       //sets winnerName_ to result of [electionWinner()].name. nice and nested functionality here, haha.
  }


}
