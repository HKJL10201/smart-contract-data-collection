pragma solidity ^0.7.0;
pragma abicoder v2;

import "./VoteDappTokenV3.sol";
import "./VoteDappStorageV2.sol";

import "./SafeMath.sol";


//Notes:
//for qvoting, people could vote for another option, but would still have to pay more money for their next vote
//Poll is open upon creation in this contract



contract VoteDappQuadratic {

    using SafeMath for uint256;

    //stores voter data
    struct _voterData {
        bool retrievedMoney; //used to check if voter already called getYourMoney() for specific poll
        bool allowedToVote;
    }

    //stores option data
    struct Options {
        mapping(address => uint256) Payments; //how much people paid for an option
        uint256 amount; //amount of VOTES for the option
        uint256 amountPaid; //total amount paid for this option
    }
    
    //stores poll data
    struct pollData {
        address owner;
        address recipient; //who receives the funds after poll ends
        string description;
        bool open;
        bool privatePoll; //used as option to restrict which people can vote
        bool returnMoneyOnCompletion; //return everyones money instead of collecting winners money upon completion of poll
        string[] arrOptions; //an array of options
        mapping(string => Options) options; //mapping to store option data
        mapping(address => _voterData) voterData; //total payments in poll
        uint256 maxVotes; //maximum amount of votes for each voter
    }
    
    event pollCreated(
        string indexed _pollName,
        address _owner
    );
    
    event pollEnded(
        string indexed _pollName
    );
    
    event pollVoted(
        string indexed _pollName,
        string _option,
        address _voter
    );
    
    
    //or use mapping...
    mapping(string => pollData) public Polls;
    
    string [] public listofPolls; //allows people to look up Polls
    
    //TOKEN
    VoteDappToken token;
    
    VoteDappStorage nameStorage;
    
    modifier pollExists(string memory pollName) {
        require(Polls[pollName].owner != address(0), "Poll does not exist.");
        _;
    }

    constructor (address _token, address _storage) {
        token = VoteDappToken(_token);
        nameStorage = VoteDappStorage(_storage); //used to check if name exists across any of the "suite" of "poll contracts"
    }
    
    function createPoll(
        string memory pollName, string memory description, string[] memory toptions, uint256 maxVotes,
        bool returnMoneyOnCompletion, bool privatePoll, address[] memory allowedVoters, address recipient
        ) external {
        require(Polls[pollName].owner == address(0), "Another poll already has that name."); //makes sure name doesn't already exist
        
        require(maxVotes >= 1, "You must allow for one or more votes.");
        
        require(nameStorage.addName(pollName), "Name reservation failed.");
        
        if(privatePoll) {
            require(allowedVoters.length > 0, "Can't be private and allow no one");
            
            Polls[pollName].privatePoll = true;
            
            for(uint256 a = 0; a<allowedVoters.length; a++) {
                Polls[pollName].voterData[allowedVoters[a]].allowedToVote = true;
            }
            
        } else {
            require(allowedVoters.length == 0, "Can't be public and restrict voters.");
        }
        
        
        Polls[pollName].owner = msg.sender;
        
        Polls[pollName].recipient = recipient;
        
        if(keccak256(abi.encodePacked(description)) != keccak256(abi.encodePacked(""))) {
            Polls[pollName].description = description;
        }
        
        Polls[pollName].maxVotes = maxVotes;
        
        Polls[pollName].arrOptions = toptions;
        
        if(returnMoneyOnCompletion == true) {
            Polls[pollName].returnMoneyOnCompletion = true;
        }
        
        Polls[pollName].open = true;
        
        listofPolls.push(pollName); //pushes pollName to a list of all polls
        
        emit pollCreated(pollName, msg.sender);
    }
    
    function vote(string memory pollName, string memory option, uint256 votes) external {
        
        require(Polls[pollName].open, "Poll does not exist or poll is not open."); //checks if poll exists and if its open
        
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        for(uint256 x = 0; x<arrOptions.length; x++) {
            if (keccak256(abi.encodePacked(arrOptions[x])) == keccak256(abi.encodePacked(option))) {
                break;
            }
            if (x==arrOptions.length.sub(1)) {
                revert("Not an option");
            }
        }
        
        require(votes > 0, "Cannot have 0 votes.");
        
        if(Polls[pollName].privatePoll) {
            require(Polls[pollName].voterData[msg.sender].allowedToVote, "You are not allowed to vote.");
        }
        
        //get all the total votes in a poll made previously plus the votes being used now
        uint256 previousAmountPaid = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            previousAmountPaid = previousAmountPaid.add(Polls[pollName].options[arrOptions[a]].Payments[msg.sender]);
        }
        
        uint256 previousTotalVotes = findVotes(previousAmountPaid);
        uint256 v = previousTotalVotes.add(votes);
        require(v <= Polls[pollName].maxVotes, "You have specified too much votes than you are allowed.");
        
        //get the price for the new votes
        uint256 c = findCost(votes, previousTotalVotes);
        
        //transfer VOTT
        require(token.balanceOf(msg.sender) >= c, "You do not have enough VOTT coins."); //checks if sender has enough money
        require(token.allowance(msg.sender, address(this)) >= c, "You did not approve the contract's allowance."); //checks if spender is allowed to spend this amount
                                            //address(this) is the contracts address
        require(token.transferFrom(msg.sender, address(this), c), "Transaction failed.");
        
        //Polls[pollName].voterData[msg.sender].moneyPaid = Polls[pollName].voterData[msg.sender].moneyPaid.add(c); //sets the payments number to how much the person paid for so far
        
        Polls[pollName].options[option].Payments[msg.sender] = Polls[pollName].options[option].Payments[msg.sender].add(c); //sets the payments for the specific option
        
        Polls[pollName].options[option].amount = Polls[pollName].options[option].amount.add(votes); //sets the votes for the option
        
        Polls[pollName].options[option].amountPaid = Polls[pollName].options[option].amountPaid.add(c); //sets the votes for the option
        
        emit pollVoted(pollName, option, msg.sender);
    }
    
    function endPoll(string memory pollName) external pollExists(pollName) {
        
        require(Polls[pollName].open, "Poll already closed.");
        require(Polls[pollName].owner==msg.sender, "You are not the owner of this poll.");
        Polls[pollName].open = false;
        
        if(!Polls[pollName].returnMoneyOnCompletion) {
            string [] memory winners = requestWinner(pollName);
            uint256 totalAmountforPayment = 0;
            for(uint256 i = 0; i<winners.length; i++) {
                totalAmountforPayment = totalAmountforPayment.add(Polls[pollName].options[winners[i]].amountPaid);
                //if there are ties, the owner gets the money from all the options that tied
            }
            
            require(token.transfer(Polls[pollName].recipient, totalAmountforPayment), "Transaction failed."); 
            //tranfer all money to owner of the poll
            //if there are ties, the owner gets the money from all the options that tied
            
        }
        
        
        
        emit pollEnded(pollName);
        
    }
    
    function getYourMoney(string memory pollName) external pollExists(pollName) {
        
        require(!Polls[pollName].open, "You cannot charge back if poll is open."); //checks if poll exists and if its open
        
        require(!Polls[pollName].voterData[msg.sender].retrievedMoney);
        
        Polls[pollName].voterData[msg.sender].retrievedMoney = true;
        
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        uint256 c = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            c = c.add(Polls[pollName].options[arrOptions[a]].Payments[msg.sender]);
        }
        //c = all the money some paid in the poll
        
        if(!Polls[pollName].returnMoneyOnCompletion) {
            string [] memory winners = requestWinner(pollName);
            for(uint256 i = 0; i<winners.length; i++) {
                c = c.sub(Polls[pollName].options[winners[i]].Payments[msg.sender]);
                //sorts through all the winners and subtracts the amount that was put in by the voter for the winners
            }
        }
        require(token.transfer(msg.sender, c), "Transaction failed."); 
        
        
    }
    
    function checkGetYourMoney(string memory pollName) view external pollExists(pollName) returns (uint256) {
        
        require(!Polls[pollName].open, "Poll is open."); //checks if poll exists and if its open
        
        if(Polls[pollName].voterData[msg.sender].retrievedMoney) {
            return 0;
        }
        
        //c = all the money some paid in the poll
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        uint256 c = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            c = c.add(Polls[pollName].options[arrOptions[a]].Payments[msg.sender]);
        }
        
        if(!Polls[pollName].returnMoneyOnCompletion) {
            string [] memory winners = requestWinner(pollName);
            for(uint256 i = 0; i<winners.length; i++) {
                c = c.sub(Polls[pollName].options[winners[i]].Payments[msg.sender]);
                //sorts through all the winners and subtracts the amount that was put in by the voter for the winners
            }
        }

        return c;
    }
    
    
    //Quadratic Voting where your n'th vote costs $n
    function findCost(uint256 n, uint256 b) pure public returns (uint256) {
        uint256 c;
        for (uint256 i=n + b; i>b; i--) { //b is used if the person has already voted and wants to get more votes
            c = c.add(i);
        }
        return c;
    }
    
    function findVotes(uint256 c) pure public returns (uint256) {
        uint256 v;
        for(uint256 i = 0; i<=c; i++) {
            v=v.add(i);
            if (v==c) {
                return i;
            }
            
        }
        //consider adding a revert failed if for loop doesnt return anything
    }
    
    //view functions (for web3)
    
    function getPollOwner(string memory pollName) external view returns (address) {
        return Polls[pollName].owner;
    }
    
    function getPollDescription(string memory pollName) external view pollExists(pollName) returns (string memory) {
        return Polls[pollName].description;
    }
    
    //returns options for a poll
    function requestOptions(string memory pollName) view external pollExists(pollName) returns (string [] memory) {
        return Polls[pollName].arrOptions; //returns all elements in the array of people who voted for specific option
    }
    
    //returns how much VOTES this option has
    function requestOptionVotes(string memory pollName, string memory option) view external pollExists(pollName) returns (uint256) {
        return Polls[pollName].options[option].amount;
    }
    
    //returns how much someone paid for a specific option
    function trackSpecificPayments(string memory pollName, string memory option, address voter) view external pollExists(pollName) returns (uint256) {
        
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        for(uint256 x = 0; x<arrOptions.length; x++) {
            if (keccak256(abi.encodePacked(arrOptions[x])) == keccak256(abi.encodePacked(option))) {
                break;
            }
            if (x==arrOptions.length.sub(1)) {
                revert("Not an option");
            }
        }
        
        return Polls[pollName].options[option].Payments[voter];
    }
    //returns total amount paid in a poll for a specific voter
    function trackTotalPayments(string memory pollName, address voter) view external pollExists(pollName) returns (uint256) {
        
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        uint256 c = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            c = c.add(Polls[pollName].options[arrOptions[a]].Payments[voter]);
        }
        
        
        return c;
    }
    
    function isAllowedToVote(string memory pollName, address voter) view external pollExists(pollName) returns (bool) {
        
        if(!Polls[pollName].privatePoll) {
            return true;
        }
        
        return Polls[pollName].voterData[voter].allowedToVote;
    }
    
    function getPollList() view external returns (string [] memory) {
        return listofPolls;
    }
    
    //find out how much gas this costs
    function requestWinner(string memory pollName) view public pollExists(pollName) returns (string [] memory) {
        
        string [] memory winners = new string[] (Polls[pollName].arrOptions.length); //makes the array the side of the amount of options
        
        //amount of votes per option, votes for each option are stored 
        //in the same placement of the array as it placement in the array of options
        uint256[] memory votesPerOption = new uint256[] (Polls[pollName].arrOptions.length);
        
        for (uint256 i=0; i<Polls[pollName].arrOptions.length; i++) {
            
                                                        // Polls[pollName].arrOptions[i];
            votesPerOption[i] = Polls[pollName].options[Polls[pollName].arrOptions[i]].amount;
        }
        //largest amount of votes in a poll
        uint256 largestamountofvotes = 0;
        for (uint256 i=0; i<votesPerOption.length; i++) {
            if(largestamountofvotes < votesPerOption[i]) {
               largestamountofvotes = votesPerOption[i];
            }
        }
        
        //incase no one voted yet, return nothing
        if (largestamountofvotes == 0) {
            return winners;
        }
        
        
        uint256 e = 0; //used in order to place winning options in array
        
        //sorts through all the options and finds the one(s) that won (had the same number of votes as largestamountofvotes)
        for (uint256 i=0; i<Polls[pollName].arrOptions.length; i++) {
            if(largestamountofvotes == Polls[pollName].options[Polls[pollName].arrOptions[i]].amount) {
                winners[e] = Polls[pollName].arrOptions[i]; //adds option to an array and returns whole array (for ties)
                e = e.add(1); //increments for the next winner (if there is a tie of two or more)
            }
        }
        return winners;
    }
    
}
