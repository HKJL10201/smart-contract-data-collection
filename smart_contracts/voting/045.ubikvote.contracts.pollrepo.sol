pragma solidity ^0.5;
pragma experimental ABIEncoderV2;

/** 
Please do not use in any kind of production. 
This is unoptimized and contains dangerous experimental features. 
This is Proof of Concept stuff only.
*/

contract PollRepo {
    mapping (address => bool) admins;
    
    struct Option {
        string slug;
        string description;
    }
    
    mapping (string => Option[]) pollOptions;
    
    struct Poll {
        string label;
        string description;
        bool visible;
        bool finalized;
        mapping (address => bool) voted;
        mapping (string => uint256) votes;
    }
    
    Poll[] public polls;
    mapping (string => uint256) pollIndex;
    
    constructor() public {
        admins[msg.sender] = true;
    }
    
    function isAdmin(address addr) view public returns (bool) {
        return admins[addr];
    }
    
    function addAdmin(address addr) public onlyAdmin {
        admins[addr] = true;
    }
    
    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Only the administrator can make changes");
        _;
    }
    
    function pollCount() public view returns (uint256) {
        return polls.length;
    }
    
    function getPollByName(string memory name) internal view returns (Poll memory) {
        return polls[pollIndex[name]];
    }
    
    function initPoll(string memory name, string memory description) onlyAdmin public {
        require(pollIndex[name] == 0, "This poll must not exist");
        pollIndex[name] = polls.length;
        polls.push(Poll(name, description, false, false));
    }
    
    function startPoll(string memory name) onlyAdmin public {
        polls[pollIndex[name]].visible = true;
    }
    
    function finalizePoll(string memory name) onlyAdmin public {
        polls[pollIndex[name]].finalized = true;   
    }
    
    function hidePoll(string memory name) onlyAdmin public {
        polls[pollIndex[name]].visible = true;
    }
    
    function addOption(string memory pollName, string memory optionSlug, string memory optionDescription) onlyAdmin public {
        require(pollIndex[pollName] > 0, "This poll must not exist");
        pollOptions[pollName].push(Option(optionSlug, optionDescription));
    }
    
    function getNumOptions(string memory name) public view returns (uint256) {
        return pollOptions[name].length;
    }
    
    function getOptionForPoll(string memory name, uint256 optionIndex) public view returns (Option memory) {
        return pollOptions[name][optionIndex];
    }
    
    function vote(string memory pollName, string memory optionSlug) public {
        require (polls[pollIndex[pollName]].voted[msg.sender] != true, "Must not have voted");
        polls[pollIndex[pollName]].voted[msg.sender] = true;
        polls[pollIndex[pollName]].votes[optionSlug] += 1;
    }
    
    function getNumVotes(string memory pollName, string memory optionSlug) public view returns (uint256) {
        return polls[pollIndex[pollName]].votes[optionSlug];
    }

}