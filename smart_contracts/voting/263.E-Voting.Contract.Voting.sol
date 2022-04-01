pragma solidity ^0.5.0;
contract Voting {
    address public organizer;
    uint public ballotNumber;
    string public blindPublicKey;
    string public blindModulus;
    
    struct Ballot{
        string VoteString;
        string signedVoteString;
    }
    
    Ballot [] public ballots;
    
    event newBlindMessage(string msg);
    event newSignedBlindMessage(string unsignedMsg, string signedMsg);
    
    modifier isOrganizer() {
        require(msg.sender == organizer);
        _;
    }
    
    modifier isVoter() {
        _;
    }
    
    constructor ()
        public
    {
        organizer = msg.sender;
        ballotNumber = 0;
        blindPublicKey = "5667400196177832758329878658058841222486294082556628643521591018277351809425";
        blindModulus = "29952708105638190336218986723988848558180452566729640097296222007752071641411";
    }
    
    function sendBlindMessage (string memory msg) 
        public
        isVoter
    {
        emit newBlindMessage(msg);
    }
    
    function sendSignedBlindMessage (string memory unsignedMsg, string memory signedMsg) 
        public
        isOrganizer
    {
        emit newSignedBlindMessage(unsignedMsg, signedMsg);
    }
    
    function sendBallot (string memory VoteString,string memory signedVoteString) 
        public
    {
        ballotNumber += 1;
        ballots.push(Ballot({
            VoteString: VoteString,
            signedVoteString: signedVoteString
        }));
    }
}
