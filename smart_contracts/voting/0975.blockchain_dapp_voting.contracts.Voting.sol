pragma solidity 0.4.20;

contract Voting {

    // struct to store the option informations 
    struct Option {
        uint id;
        string name;
        uint voteCount;
    }

    // mapping for voted voters to ensure no second vote
    mapping(address => bool) public voters;
    
    // mapping for voted voters to see which option they voted for
    mapping(address=> uint) public votedFor;
    
    // mapping for index to option
    mapping(uint => Option) public options;

    // number of options
    uint public optionCount;

    event voteEvent (
        uint indexed _optionId
    );

    // initalize 5 options
    function Voting () public {
        addOption("Option 1");
        addOption("Option 2");
        addOption("Option 3");
        addOption("Option 4");
        addOption("Option 5");
    }

    // 
    function addOption (string _name) private {
        optionCount ++;
        options[optionCount] = Option(optionCount, _name, 0);
    }

    function vote (uint _optionId) public {
        // check no double voting
        require(!voters[msg.sender]);

        // check valid Id
        require(_optionId > 0 && _optionId <= optionCount);
        
        // add voter to votes mapping
        voters[msg.sender] = true;
        
        // add a vote to the option
        options[_optionId].voteCount ++;

        // add a mapping to indicate which one voted for
        votedFor[msg.sender] = _optionId;

        voteEvent(_optionId);
        
    }
}
