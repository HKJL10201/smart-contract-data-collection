// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract AnonymousElection {

    string name;
    // sets the owner of the election to the one who deploys the smart contract
    address private owner;

    string[] private candidates; // array of valid candidates
    address[] private voters; // array of addresses that can submit votes
    mapping(address => uint256) voterToIndex; // mapping of voter address to their index in voters
    mapping(address => bool) private canVote; // mapping that shows if an address can vote

    // indicates what round the election is on
    // round = 1, when all users are submitting their public keys. From contract start to once all have submitted their pk
    // round = 2, when all users are submitting their votes. From once everyone has submitted their pk to once everyone has submitted their vote
    // round = 3, for after everyone submits their votes
    uint256 private round;

    // these variables keep track of numbers of submissions
    uint256 private submittedPKs; // holds the number of voters who have submitted valid PKs
    uint256 private submittedVotes; // holds number of voters who have submitted their valid votes

    // cryptography related variables
    bytes private p; // prime
    bytes private g; // generator
    mapping(address => bytes) private voterPK; // mapping of users to their public keys, in the form of g^(x) (mod p)
    bytes[] private allPKBytes; // array of all PKs corresponding to voter index. In hex form
    mapping(address => bytes) private voterVotes; // mapping of users to their vote
    bytes[] private allVotes; // array of all votes corresponding to voter index. In hex form


    uint256 private m; // 2^m > number of candidates, used for tallying votes


    constructor(string[] memory _candidates, address[] memory _voters, bytes memory _p, bytes memory _g, address _owner, string memory _name) {
        // check to ensure that this election makes sense, has >0 voters and >1 candidates
        require(_candidates.length > 1 && _voters.length > 0, "ensure the candidate list and voter list are of non-zero length.");
        // TODO: Using the solidity require function, ensure the candidate list and voter list are of non-zero length.
        
        // TODO: instantiate round, owner, candidates, and voters.
        name = _name;
        owner=_owner;  //Declare Owner 
        candidates =_candidates; //Declare Candidates 
        voters=_voters;  // Declare Voters 
        round = 1;       //Declare Round

        p = _p; // prime
        g = _g; // generator
        m = 0; // 2^m > _voters.length
      

        // find m, 2^m > _voters.length
        while (2**m <= _voters.length){
            m++;
        }

        submittedPKs = 0;
        submittedVotes = 0;
        allPKBytes = new bytes[](0);


        // set voter addresses to be allowed to vote
        for (uint i = 0; i < _voters.length; i++) {
            canVote[_voters[i]] = true;
            voterToIndex[_voters[i]] = i;
            allPKBytes.push(hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
            allVotes.push(hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
            voterVotes[_voters[i]] = hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        }
    }

    // for the Zero-Knowledge proof in submitPK
    // returns bytes2048
    function calculatePKHash(bytes memory _gv, bytes memory _pk, address _a) public view returns (bytes memory) {
        bytes memory zeroes1792 = hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        return abi.encodePacked(zeroes1792, bytes32(sha256(abi.encodePacked(g, _gv, _pk, _a))));
    }

    function hasSubmittedPK(address _a) public view returns (bool) {
        bytes memory thisEmpty;
        return keccak256(abi.encodePacked(voterPK[_a])) != keccak256(thisEmpty);
    }


    // For the voter submitting their public key
    function submitPK(bytes memory _pk) public {
        // Ensure the following:
        //   the election is on round 1, which is the pk submitting round
        //   the sender is a verified voter and they are allowed to vote
        //   the voter has not already submitted a public key
        // TODO: Use the solidity require function to ensure these conditions.
         require (round == 1 && canVote[msg.sender] && !hasSubmittedPK(msg.sender));

        // set relevant pk variables
        voterPK[msg.sender] = _pk; // map voter's address to their public key
        // allPK[voterToIndex[msg.sender]] = pk; // put voter's pk in correct index in allPK array
        allPKBytes[voterToIndex[msg.sender]] = _pk;

        // Increment submittedPKs and check if everyone has submitted their pk
        //TODO: increment submittedPKs
         submittedPKs++; //Increase PK+1
        //TODO: Check if everyone has submitted their pk, and set the round to 2.
        if (submittedPKs == voters.length) { round=2;  // Voter shall vote in round 2.
    }

    }
 
    // check if voter has already submitted a vote
     function hasSubmittedVote(address _a) public view returns (bool) {
    // TODO: Write a function that checks if a voter has already submitted their vote.
        return !(canVote[_a]) && hasSubmittedPK(_a);
     }
    // need both, one to see if registered voter & voter to vote
    
       

    // for recording voter's vote
    // TODO: write a function "vote", that records a voter's vote.  Make sure to
    // use require to ensure you are in the right round and the voter can vote.

    function vote(bytes memory _encVote) public {
    require (round == 2 && canVote[msg.sender]);
    canVote[msg.sender] = false;

    voterVotes[msg.sender] = _encVote;
    allVotes[voterToIndex[msg.sender]] = _encVote;


    // TODO: increase submittedVotes and check if everyone has submitted their vote,
     submittedVotes++;
    // set the round to round 3.
     if (submittedVotes == voters.length) { round = 3; // set the round to 3, such that now contract listens for winner
        }
    }

    // TODO: Develop the following getter functions.
    // return prime p
    function getP() public view returns (bytes memory) {
      return p;
    }

    // return generator g
    function getG() public view returns (bytes memory) {
      return g;
    }


    // return m
    function getM() public view returns (uint256) {
      return m;
    }

    // returns the array of potential candidates
    function getCandidates() public view returns (string[] memory) {
      return candidates;
    }

    // returns the array of voters
    function getVoters() public view returns (address[] memory) {
      return voters;
     }

    // returns the array of all public keys
    function getAllPK() public view returns (bytes[] memory) {
    // Use the require function to make sure you are in a round >= 2
    require(round >= 2, "everyone is busy not submitted");
    return allPKBytes;
    }

    // returns array of all votes
      function getAllVotes() public view returns (bytes[] memory) {
    // Use the require function to make sure you are in a round >= 3
     require(round >= 3, "everyone is busy not submitted");
      return allPKBytes;
      }
    
    
    // return the integer value of what round the election is on
    function getRound() public view returns (uint256) {
        return round;
    }

    // checks if address can vote
    function canIVote(address _a) public view returns (bool) {
        return canVote[_a];
    }
    
}