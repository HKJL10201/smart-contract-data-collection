// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

//contract deployed at 0x3da4d3aa5166c03231Eef55a8dBEff2EaacCdF90 by Bob
/**
* @title A blockchain voting smart contract 
* 
* @notice Members need to register first with 0.1 ether for 4 weeks or buy more time afterwards.   
* Members can be promoted by to admin status by another admin. 
* Admins can be demoted by an admin.
* Admins can make proposals and warn members (if more than 2 warnings a member is blacklisted). 
* All members can vote for proposals (0 -> Blank, 1 -> Yes, 2 -> No)
* 
@dev All function calls are currently implemented without side effects
*/
contract Voting {
    
    // Variables of state
    
    /// @dev address who collects ethers from registration fees
    address payable superAdmin;
    
    /// @dev struct Member
    struct Member{
         bool isAdmin; // false if the member is not an admin, true is an admin
         uint warnings; // 0 at registration, can be increased
         bool isBlacklisted; //false at registration and as long as warnings <= 2, true if warnings >2
         uint delayRegistration; // till when is the member registered following his payment
    }
    
    /// @dev struct Proposal
    struct Proposal{
        uint id; // id of proposal
        string question; // proposal question
        string description; // proposal description
        uint counterForVotes; // counter of votes `Yes`
        uint counterAgainstVotes; // counter of votes `No`
        uint counterBlankVotes; // counter of votes `Blank`
        uint delay; // till when the proposal is active (proposal active for 1 week )
        mapping (address => bool) didVote; // mapping to check that an address can not vote twice for same proposal id
    }
    
    /// @dev mapping from an address to a Member
    mapping (address => Member) public members;
    
    /// @dev mapping from an id of proposal to a Proposal
    mapping (uint => Proposal) public proposals;
    
    /// @dev counter for proposal id incremeneted by each proposal creation
    uint private counterIdProposal;
    
    /// @dev instructions to vote
    /// @notice instructions to vote : 0 -> Blank, 1 -> Yes, 2 -> No, other -> Invalid vote
    string public howToVote = "0 -> Blank, 1 -> Yes, 2 -> No";
    
    /// @dev vote options: Yes, No, Blank using enum type
    enum Option { Blank, Yes, No } // variables de type Option prennent valeurs: 0 -> Option.Blank, 1 -> Option.Yes, 2 -> Option.No
    
    /// @dev event for EVM log when payment for registration
    event Registration(
        address indexed _buyer,
        uint256 _amount_wei,
        uint256 _amount_delay
        );
        
    // Constructor
    /// @dev address _addr who collects ethers from registration fees initialized by constructor is the first member and admin for life (100 years)
    constructor(address payable _addr) public{
        superAdmin = _addr;
        members[_addr].isAdmin = true;
        members[_addr].delayRegistration = block.timestamp + 5200 weeks;
    }

    //Modifiers
    
    /// @dev modifier to check if admin
    modifier onlyAdmin (){
            require (members[msg.sender].isAdmin == true, "only admin can call this function");
            _;
        }
    
    /// @dev modifier to check if member is up-to-date with registration payments   
    modifier onlyActiveMembers (){
            require (members[msg.sender].delayRegistration >= block.timestamp, "only members who have paid the registration till present can call this function");
            _;
        }
    
    /// @dev modifier to check if member is not blacklisted       
    modifier onlyWhitelistedMembers (){
            require (members[msg.sender].isBlacklisted == false, "only members not blacklisted can call this function");
            _;
        }
    
    /// @dev modifier to check if member (even behind with his payments, if delayRegistration value was increased in the past from 0)     
    modifier onlyMembers (){
            require (members[msg.sender].delayRegistration > 0, "only members can call this function");
            _;
        }
    
    // Functions
    
    /// @dev only an admin, up-to-date with his payments and not blacklisted can create a proposal. The id is given by counterIdProposal variable and delay 1 week from creation date 
    /// @notice a proposal is active for one week  
    /// @param _question : short question of the proposal
    /// @param _question : question of the proposal  
    function propose(string memory _question, string memory _description) public onlyAdmin onlyActiveMembers onlyWhitelistedMembers{
        counterIdProposal++;
        uint count = counterIdProposal;
        proposals [count] = Proposal(count, _question, _description, 0, 0, 0, block.timestamp + 1 weeks );
        
    }
    
    /// @dev only a member up-to-date with his payments and not blacklisted can vote for an active proposal and only once. 
    /// @notice a proposal active for one week, check voting instructions with howToVote  
    /// @param _id : proposal id
    /// @param _voteOption : option for voting
    function vote (uint _id, Option _voteOption ) public onlyActiveMembers onlyWhitelistedMembers{
        //verifier si votant n'est pas blacklisted et pas deja vote pour cette proposition
        require (proposals[_id].delay > block.timestamp, "proposal not active any more");
        require (proposals[_id].didVote[msg.sender] == false, "member already voted for this proposal");
        if (_voteOption == Option.Blank) {
            proposals[_id].counterBlankVotes++;
        } else if(_voteOption == Option.Yes) {
            proposals[_id].counterForVotes++;
        } else if(_voteOption == Option.No) {
            proposals[_id].counterAgainstVotes++;
        } else revert("Invalid vote");
        proposals[_id].didVote[msg.sender] = true;
    }

    /// @dev only an admin, up-to-date with his payments and not blacklisted can warn a member (even an another admin, but not the superAdmin). 
    /// @notice after 2 warnings member is blacklisted and cannot vote anymore  
    /// @param _addr : address of the member to be warned
    function warn (address _addr) public onlyAdmin onlyActiveMembers onlyWhitelistedMembers{
        /// @dev address owner cannot be blacklisted
        require (_addr != superAdmin, "superAdmin cannot be warned");
        members[_addr].warnings +=1;
        if (members[_addr].warnings > 2){ members[_addr].isBlacklisted = true;}
    }

    /// @dev only an admin, up-to-date with his payments and not blacklisted can whitelist a member. Warnings counter restarts at 0 and isBlacklisted property set to false. 
    /// @param _addr : address of the member to be whitelisted   
    function whitelist (address _addr) public onlyAdmin onlyActiveMembers onlyWhitelistedMembers{
        members[_addr].warnings = 0;
        members[_addr].isBlacklisted = false;
    }

    /// @dev only an admin, up-to-date with his payments and not blacklisted can promote a member to admin status (if the member is up-to-date with his payments). 
    /// @param _addr : address of the member to be set admin
    function setAdmin (address _addr) public onlyAdmin onlyActiveMembers onlyWhitelistedMembers{
        require (members[_addr].delayRegistration >= block.timestamp, " member to be set admin is behind with registration payment");
        members[_addr].isAdmin = true;
        }

    /// @dev only an admin, up-to-date with his payments and not blacklisted can demote a member from admin status. 
    /// @param _addr : address of the member to be demoted from admin
    function unsetAdmin (address _addr) public onlyAdmin onlyActiveMembers onlyWhitelistedMembers{
        members[_addr].isAdmin = false;
        }
    
    // only for non-members
    /// @dev Register a new member, after checking that value is at least 0.1 ether (if more that duration is proportiional with value. The ethers are transfered to superAdmin adress. An event is sent to EVM log.
    /// @notice Enter a value for registration : : for each 0.1 ether 4 extra weeks. Members please use buy function.    
    function register() public payable{
        require (members[msg.sender].delayRegistration == 0, "only for non members");
        require (msg. value >= 10**17, "not enough ethers");
        uint nbOf4WeekPeriods  = msg.value / 10 ** 17;
        uint validity = block.timestamp + nbOf4WeekPeriods * 4 weeks;
        members[msg.sender] = Member(false, 0, false, validity );
        superAdmin.transfer(msg.value);
        emit Registration( msg.sender, msg.value, validity);
    }
    
    // only for members (even inactive)
    /// @dev Buy more registration time for an already member, after checking that value is at least 0.1 ether (if more that duration is proportional with value. The ethers are transfered to superAdmin adress. An event is sent to EVM log.
    /// @notice Enter a value for registration : : for each 0.1 ethers 4 extra weeks. Non-members please use register function.  
    function buy() public payable onlyMembers onlyWhitelistedMembers{
        require (msg. value >= 10**17, "not enough ethers");
        uint nbOf4WeekPeriods  = msg.value / 10 ** 17;
        uint validity = block.timestamp + nbOf4WeekPeriods * 4 weeks;
        if (members[msg.sender].delayRegistration < block.timestamp){
            members[msg.sender].delayRegistration = validity;
        } else {
            members[msg.sender].delayRegistration += nbOf4WeekPeriods * 4 weeks;
        }
        superAdmin.transfer(msg.value);
        emit Registration( msg.sender, msg.value, members[msg.sender].delayRegistration);
        }
}
