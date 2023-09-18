pragma solidity ^0.7.0;
pragma abicoder v2;

import "./VoteDappTokenV3.sol";
import "./VoteDappStorageV2.sol";

import "./SafeMath.sol";


//Notes:
//if someone were to make their vote cost zero, then anybody could put as much votes as maxVotes allows
//Poll is open upon creation in this contract

contract VoteDappRegular {
    
    using SafeMath for uint256;
    
    //stores voter data
    struct _voterData {
        bool retrievedMoney; //used to check if voter already called getYourMoney() for specific poll
        bool allowedToVote;
    }
    
    //stores option data
    struct Options {
        uint256 votes; //amount of votes recieved for the option
        mapping(address => uint256) Votes; //how much one person voted for an option, used for people to get their money back
                                           //if the option they voted for did not win
    }
    
    //stores pollData
    struct pollData {
        address owner; //owner and creator of the poll
        address recipient; //who gets the funds after poll is over (if votes cost money)
        string description; //description of the poll (is set by creator/owner of poll)
        bool open; //used to close and open poll
        bool privatePoll; //used as option to restrict which people can vote
        bool returnMoneyOnCompletion; //return everyones money instead of collecting winners money upon completion of poll
        string[] arrOptions; //an array of available options for the poll
        mapping(string => Options) options; //a mapping in order to store data for each option
        
        mapping(address => _voterData) voterData; //used to track how much votes someone submited for the whole poll and whether they retrieved
                                                  //money from an ended poll
        uint256 cost; //cost for each vote
        uint256 maxVotes; //maximum amount of votes for each voter
        
    }
    
    event pollCreated(
        string indexed _pollName,
        address _owner
    );
    
    event pollEnded(
        string indexed _pollName
    );
    
    //shows when a person voted
    event pollVoted(
        string indexed _pollName,
        string _option,
        address _voter
    );

    //storage
    mapping(string => pollData) public Polls; //used to store all poll data
    
    string [] public listofPolls; //allows people to grab an array of polls and look different ones up (web3)

    //token contract, used for paying for votes with custom VOTT token
    VoteDappToken token;
    
    VoteDappStorage nameStorage;
    
    modifier pollExists(string memory pollName) {
        require(Polls[pollName].owner != address(0), "Poll does not exist.");
        _;
    }
    
    constructor (address _token, address _storage) {
        token = VoteDappToken(_token); //stores token addres to interact with token contract
        nameStorage = VoteDappStorage(_storage); //used to check if name exists across any of the "suite" of "poll contracts"
    }
    
    function createPoll(
        string memory pollName, string memory description, string[] memory toptions, uint256 maxVotes, uint256 votecost,
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
        
        if(keccak256(abi.encodePacked(description)) != keccak256(abi.encodePacked(""))) {
            Polls[pollName].description = description;
        }
        
        Polls[pollName].maxVotes = maxVotes;
        
        Polls[pollName].arrOptions = toptions;
        
        if(votecost > 0) {
            Polls[pollName].cost = votecost;
            if(returnMoneyOnCompletion == true) {
                Polls[pollName].returnMoneyOnCompletion = true;
            } else {
                Polls[pollName].recipient = recipient;
            }
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

        //gathers the total amount of votes someone already used plus the amount they want to use now,
        //and makes sure they do not go over the vote limit
        
        uint256 v = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            v = v.add(Polls[pollName].options[arrOptions[a]].Votes[msg.sender]);
        }
        
        v = v.add(votes);
        require(v <= Polls[pollName].maxVotes, "You have specified too much votes than you are allowed.");
        
        //used to transact VOTT from voter to this contract
        if (Polls[pollName].cost > 0) {
            
            uint256 c = Polls[pollName].cost.mul(votes);
            
            //checks if sender has enough money
            require(token.balanceOf(msg.sender) >= c, "You do not have enough VOTT coins."); 
            
            //checks if spender is allowed to spend this amount
            require(token.allowance(msg.sender, address(this)) >= c, "You did not approve the contract's allowance."); 
                                            //address(this) is the contracts address
            //transfers VOTT                                
            require(token.transferFrom(msg.sender, address(this), c), "Transaction failed."); 
        }
        //adds the amount of votes used for the specific option to the Vote mapping in the option data for the voters address
        //used for getYourMoney
        Polls[pollName].options[option].Votes[msg.sender] = Polls[pollName].options[option].Votes[msg.sender].add(votes);
        
        //adds amount of votes to vote counter in option data (used to count total votes)
        Polls[pollName].options[option].votes = Polls[pollName].options[option].votes.add(votes);
        
        //trigger event
        emit pollVoted(pollName, option, msg.sender);
    
    }
    
    function endPoll(string memory pollName) external pollExists(pollName) {
        
        require(Polls[pollName].open, "Poll already closed.");
        require(Polls[pollName].owner==msg.sender, "You are not the owner of this poll.");
        
        //closes poll
        Polls[pollName].open = false;
        
        //used to transact VOTT from voter to this contract
        if (Polls[pollName].cost > 0 && Polls[pollName].returnMoneyOnCompletion == false) {
            //get the winners for this poll
            string [] memory winners = requestWinner(pollName);
            
            uint256 totalWinnerVotes = 0;
            
            //for each winner, take the amount of votes, get their VOTT cost and transfer VOTT tokens to the owner of the poll
            for(uint256 i = 0; i<winners.length; i++) {
                
                //get total votes for the winners
                totalWinnerVotes = totalWinnerVotes.add(Polls[pollName].options[winners[i]].votes); 
                
            }
            
            address recipient = Polls[pollName].recipient;
          
            require(token.transfer(recipient, totalWinnerVotes.mul(Polls[pollName].cost)), "Transaction failed."); 
            
        } 
        
        emit pollEnded(pollName);
        
    }
    
    //used for specific voter to get their money back if the options they chose did not win
    function getYourMoney(string memory pollName) external pollExists(pollName) {
        
        require(!Polls[pollName].open, "You cannot charge back if poll is open."); //checks if poll exists and if its open
        
        require(Polls[pollName].cost > 0, "Not a pay to vote poll.");
        
        require(!Polls[pollName].voterData[msg.sender].retrievedMoney, "You already charged back.");
        
        Polls[pollName].voterData[msg.sender].retrievedMoney = true;
        
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        //total votes for the specific voter
        uint256 v = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            v = v.add(Polls[pollName].options[arrOptions[a]].Votes[msg.sender]);
        }
        
        //get the winners
        string [] memory winners = requestWinner(pollName);
        
        if(!Polls[pollName].returnMoneyOnCompletion) {
            //for each winner, subtract the votes submitted by the voter
            for(uint256 i = 0; i<winners.length; i++) {
                v = v.sub(Polls[pollName].options[winners[i]].Votes[msg.sender]);
                //sorts through all the winners and subtracts the votes that were put in for the winners
            }
        }
        
        //pay back all the VOTT the voter spent for the votes he submitted in which the option did not win
        require(token.transfer(msg.sender, v.mul(Polls[pollName].cost)), "Transaction failed."); 
        
        
    }
    
    //view functions (for web3)
    
    function getPollOwner(string memory pollName) external view returns (address) {
        return Polls[pollName].owner;
    }
    
    function getPollDescription(string memory pollName) external view pollExists(pollName) returns (string memory) {
        return Polls[pollName].description;
    }
    
    //used to check how much money a voter can retrieve from a poll
    function checkGetYourMoney(string memory pollName) external view pollExists(pollName) returns (uint256) {
        require(!Polls[pollName].open, "Poll is not closed."); //checks if poll exists and if its open
        
        if (Polls[pollName].voterData[msg.sender].retrievedMoney || Polls[pollName].cost == 0) {
            return 0;
        }
        
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        //total votes for the specific voter
        uint256 v = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            v = v.add(Polls[pollName].options[arrOptions[a]].Votes[msg.sender]);
        }
        
        //get the winners
        string [] memory winners = requestWinner(pollName);
        
        if(!Polls[pollName].returnMoneyOnCompletion) {
            //for each winner, subtract the votes submitted by the voter
            for(uint256 i = 0; i<winners.length; i++) {
                v = v.sub(Polls[pollName].options[winners[i]].Votes[msg.sender]);
                //sorts through all the winners and subtracts the votes that were put in for the winners
            }
        }
        
        return v;
        
    }
    
    //request the amount of votes a certain option received
    function requestOptionVotes(string memory pollName, string memory option) view external pollExists(pollName) returns (uint256) {
        
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        for(uint256 x = 0; x<arrOptions.length; x++) {
            if (keccak256(abi.encodePacked(arrOptions[x])) == keccak256(abi.encodePacked(option))) {
                break;
            }
            if (x==arrOptions.length.sub(1)) {
                revert("Not an option");
            }
        }
        
        return Polls[pollName].options[option].votes;
    }
    //request all the options for a poll
    function requestOptions(string memory pollName) view external pollExists(pollName) returns (string [] memory) {
        
        return Polls[pollName].arrOptions;
    }
    //track the amount of votes for a specific user
    function trackTotalVotes(string memory pollName, address voter) view external pollExists(pollName) returns (uint256) {
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        //total votes for the specific voter
        uint256 v = 0;
        
        for(uint256 a = 0; a<arrOptions.length; a++) {
            v = v.add(Polls[pollName].options[arrOptions[a]].Votes[voter]);
        }
        
        return v;
        
    }
    //request the amount of votes a person voted for a specific option
    function trackSpecificVotes(string memory pollName, string memory option, address voter) view external pollExists(pollName) returns (uint256) {
        string [] memory arrOptions = Polls[pollName].arrOptions;
        
        for(uint256 x = 0; x<arrOptions.length; x++) {
            if (keccak256(abi.encodePacked(arrOptions[x])) == keccak256(abi.encodePacked(option))) {
                break;
            }
            if (x==arrOptions.length.sub(1)) {
                revert("Not an option");
            }
        }
        
        return Polls[pollName].options[option].Votes[voter];
        
    }
    
    function isAllowedToVote(string memory pollName, address voter) view external pollExists(pollName) returns (bool) {
        
        if(!Polls[pollName].privatePoll) {
            return true;
        }
        
        return Polls[pollName].voterData[voter].allowedToVote;
    }
    
    //get total list of all polls
    function getPollList() view external returns (string [] memory) {
        return listofPolls;
    }
    
    //find out how much gas this costs
    //get the winner of an ongoing poll or ended poll
    function requestWinner(string memory pollName) view public pollExists(pollName) returns (string [] memory) {
        
        //amount of votes per option, votes for each option are stored 
        //in the same placement of the array as it placement in the array of options
        uint256[] memory votesPerOption = new uint256[] (Polls[pollName].arrOptions.length);
        
        for (uint256 i=0; i<votesPerOption.length; i++) {
                                                        // Polls[pollName].arrOptions[i];
            votesPerOption[i] = Polls[pollName].options[Polls[pollName].arrOptions[i]].votes;
        }
        
        //used to find the largest amount of votes for an option in the poll
        uint256 largestamountofvotes = 0;
        //sorts through all values in the array and finds the largest one
        for (uint256 i=0; i<votesPerOption.length; i++) {
            if(largestamountofvotes < votesPerOption[i]) {
               largestamountofvotes = votesPerOption[i];
            }
        }
        //an array used to store all the winners
        string [] memory winners = new string[] (Polls[pollName].arrOptions.length); //makes the array the size of the amount of options
        //incase no one voted yet (largestamountofvotes == 0), return nothing
        if (largestamountofvotes == 0) {
            return winners;
        }
        
        
        uint256 e = 0; //used in order to place winning options in winners array
        //sorts through all the options and finds the one(s) that won (had the same number of votes as largestamountofvotes)
        for (uint256 i=0; i<votesPerOption.length; i++) {
            if(largestamountofvotes == Polls[pollName].options[Polls[pollName].arrOptions[i]].votes) {
                winners[e] = Polls[pollName].arrOptions[i]; //adds option to an array and returns whole array (for ties)
                e = e.add(1); //increments for the next winner (if there is a tie of two or more)
            }
        }
        return winners;
    }

}
