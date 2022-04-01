pragma solidity ^0.4.24;

contract FarmingInsurance {

/////// Farm data management
    event CowEvent(uint indexed cowID, uint indexed eventID, address indexed farm);
  
    struct Cow {
        string name;
      
        mapping(uint => CowEventData) cowEvents;
        uint numEvents;
    }

    struct Farm {
        string name;
        uint numCows;
        mapping(uint => Cow) cows;
    }

    struct CowEventData {
        address registrar;
        string description;
    }
  
    mapping(address => Farm) public farms;

    function numberOfCows(address farm) view public returns (uint cowAmount) {
        return farms[farm].numCows;
    }

    function newCow(string name) public returns (uint cowID) {
        cowID = farms[msg.sender].numCows++;
        farms[msg.sender].cows[cowID] = Cow(name,0);
        return cowID;
    }

    function cowIncident(address farm, uint cowID, string description) public {
        require(cowID < farms[farm].numCows);
        uint eventID = farms[farm].cows[cowID].numEvents++;
        farms[farm].cows[cowID].cowEvents[eventID] = CowEventData(msg.sender, description);
        emit CowEvent(cowID,eventID,farm);
    }

///////// Claims
  	struct Claim {
  		uint cowId;
  		uint date; 
  		address farmer;
  	}

    struct CheckedClaim {
          Claim claim;
          bool is_sick;
          uint checkdate;
          address vet;
    }

    struct ReplyedClaim {
          CheckedClaim checkedClaim;
          bool is_accepted;
          uint replydate;
          address insurance;
      }

  	
  	mapping(uint => Claim) public Claims; 
    mapping(uint => CheckedClaim) public CheckedClaims; 
    mapping(uint => ReplyedClaim) public ReplyedClaims; 

    uint[] public Claimhistory; // No.0
    uint[] public TobeCheck; //No.1
    uint[] public TobeReply; //No.2

    uint numberOfClaims;


  	function initClaim(uint cowId, uint date) public returns (uint) {
  		uint claimId = numberOfClaims++;
        require(cowId < numberOfCows(msg.sender));
  		Claims[claimId] = Claim(cowId, date, msg.sender);
        Claimhistory.push(claimId);
        TobeCheck.push(claimId);

  		return claimId;
  	}

     
    function vetCheck(bool check, uint claimId, uint checkdate) public returns (uint) {
      	
        CheckedClaims[claimId] = CheckedClaim(Claims[claimId], check, checkdate, msg.sender);
        delete TobeCheck[TobeCheck.length - 1];
        TobeReply.push(claimId);

      	return claimId;
     }


    function replyClaim(bool reply, uint claimId, uint replydate) public returns (uint) {
      	 ReplyedClaims[claimId] = ReplyedClaim(CheckedClaims[claimId], reply, replydate, msg.sender);
         delete TobeReply[TobeReply.length - 1];

      	 return claimId;
     }


    function getClaim(uint index) public view returns (uint[]) {
        if (index == 0){
            return Claimhistory;    
        } else if (index == 1) {
            return TobeCheck;
        } else {
            return TobeReply;
        }
          
    }

//////// Voting 
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted farm
    }

    // This is a type for a single farm.
    struct FarmVote {
        uint voteCount; // number of accumulated votes
        address farmAddr;
    }

    address public chairperson; //one node who made this voting 

    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Farm` structs.
    FarmVote[] public farmVotes;

   function addFarmToVoting(address _farmAddr) public {
        
        require ( msg.sender == chairperson,'only chairperson could add farms');
        
        farmVotes.push(FarmVote({
            farmAddr: _farmAddr,
            voteCount: 0
        }));
        }

    // Give `voter` the right to vote.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) public {

        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) public {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            farmVotes[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to farm `farms[farm].name`.
    function vote(uint farm) public{
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = farm;

        // If `farm` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        farmVotes[farm].voteCount += sender.weight;
    }

    /// @dev Computes the winning farm taking all
    /// previous votes into account.
    function winningFarm() public view
            returns (uint winningFarm_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < farmVotes.length; p++) {
            if (farmVotes[p].voteCount > winningVoteCount) {
                winningVoteCount = farmVotes[p].voteCount;
                winningFarm_ = p;
            }
        }
    }

    // Calls winningFarm() function to get the index
    // of the winner contained in the farms array and then
    // returns the name of the winner
    function winnerName() public view
            returns (string winnerName_)
    {
        winnerName_ = farms[farmVotes[winningFarm()].farmAddr].name;
    }

}
