/******************************************************************************
 * @title New Request Voting Smart Contract for PowerLedger, POWR Token Holders
 * @description A PowerLedger Smart Contract that allows POWR holders to:
 * 1) Request for a New Functionality and,
 * 2) Allow POWR holders to Vote for the request's need.
 * @author Ankur Daharwal - <ankur.daharwal@gmail.com>
 * @license - Apache 2.0
 ******************************************************************************/

pragma solidity 0.4.24;

import "./SafeMath.sol";
import "./PowerLedger.sol";


contract NewRequestVoting {
    using SafeMath for uint256;

    /*
     *  Global Storage Variables
     */

    // PowerLedger ERC-20 Token Contract
    PowerLedger public powerLedger;

    // New Functionality Request
    mapping ( address => string ) public requests;

    // Votes for each Functionality Request
    mapping ( address => Vote[] ) public votes;

    // Total votes for each Functionality Request
    mapping ( string => uint256 ) totalVotes;

    /*
     * Struct for Votes
     * requestName - Name of the Functionality requestName
     * voteType - Upvote (true) or Downvote (false)
     * hasVoted - Has the voter voted (true) or Not yet voted (false)
     * vote - vote value is the balance of the voters POWR Token
     */
    struct Vote {
        string requestName;
        bool voteType;
        bool hasVoted;
        uint256 vote;        
    }
    
    /*
     *  Modifiers
     */
    
    /*
     * @dev the modifier isPOWRHolder - 
     *  Validates if the msg sender is a POWR Token Holder or not
     */
    modifier isPOWRHolder() {
        require(powerLedger.balanceOf(msg.sender) > 0);
        _;
    }

    /*
     * @dev the modifier isValidVoter - Validates if the msg sender
     *  is a valid New Functionality Request voter or not
     */
    modifier isValidVoter(string _requestName) {
        
        // The Requestor should not be the Voter
        require( !(compareString(requests[msg.sender],_requestName)), "Functionality Requestor cannot vote for the Request");

        // A valid voter can vote only once for a particular request
        for ( uint i = 0 ; i < votes[msg.sender].length ; i++ ) {
            if( compareString(votes[msg.sender][i].requestName, _requestName) ) {
                require( !(votes[msg.sender][i].hasVoted) );
            }   
        }
        _;
    }

    /*
     *  Constructor
     */
     
    /*
     * @dev Constructor for the New Request Voting Smart Contract
     * @param _powerLedger is the PowerLedger Token Contract
     */
    constructor(PowerLedger _powerLedger) public {
        powerLedger = _powerLedger;
    }

    /*
     *  Public Functions
     */
     
    /*
     * @dev newFunctionalityRequest - To raise a new Functionality Request
     * @param _requestName - Name of the Functionality Request
     * @returns - Successful or not (true/false)
     */
    function newFunctionalityRequest(string _requestName)
        isPOWRHolder public returns (bool) {

            // Request Name should not be empty
            require(bytes(_requestName).length > 0);

            // Ensure no voted requests are duplicated while raising a new request
            require( totalVotes[_requestName] == 0 );
            // Store the request
            requests[msg.sender] = _requestName;

            return true;
    }
    
    /*
     * @dev voteForRequest - To vote for a new Functionality Request
     * @param _requestName - Name of the Functionality Request
     * @param _isUpvote - Is the vote an Upvote or Downvote
     * @returns - Successful or not (true/false)
     */
    function voteForRequest(string _requestName, bool _isUpvote)
        isPOWRHolder
        isValidVoter(_requestName)
        public returns (bool) {

            Vote memory newVote;

            // Prepare the new Vote where the votes of any voter is their POWR Balance
            newVote.requestName = _requestName;
            newVote.vote = powerLedger.balanceOf(msg.sender);
            newVote.voteType = _isUpvote;
            newVote.hasVoted = true;

            // Store the new Vote
            votes[msg.sender].push(newVote);
            
            if ( _isUpvote ) {
                totalVotes[_requestName] += newVote.vote;
                return true;
            }
            else if ( !_isUpvote ) {
                totalVotes[_requestName] -= newVote.vote;
                return true;
            }
            return false;
    }
    
    /*
     * @dev getTotalVotes - Returns the Total Votes of all Voters
     * for a Functionality Request as per POWR Holdings per Vote
     * Vote(%) = ( Total Votes / TotalSupply ) * 100
     * Where TotalSupply of POWR is 1,000,000,000
     * @param _requestName - Name of the Functionality Request
     * @returns - Total Votes for the Functionality Request
     */
    function getTotalVotes(string _requestName)
        public view returns (uint256) {            
            return totalVotes[_requestName];
    }

    /*
     * @dev compareString - To compare equality of two Strings
     * @param a - First String
     * @param b - Second String
     * @returns - Successful or not (true/false)
     */
    function compareString(string a, string b) pure internal returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}