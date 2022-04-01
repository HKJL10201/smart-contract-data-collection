pragma solidity >=0.8.0 <0.9.0;

contract Voting {
    
    struct Choice {
        bool isReal;
        uint votedAmount;
        int listPointer;
        string name;
    }
    
    int public next = -1;
    
    mapping(string => Choice) public choices;
    Choice[] public choicesList;
    
    struct Voter {
        bool voted;
        bool isReal;
        address delegate; 
        uint votsHoliding;
    }
    
    mapping (address => Voter) voters;
    

    constructor() {
        populateChoices();        
    }

    function populateChoices() public {
        choices["One"] = Choice(true, 0, ++next, "One");
        choicesList.push(choices["One"]);
        choices["Two"] = Choice(true, 0, ++next, "Two");
        choicesList.push(choices["Two"]);
        choices["Three"] = Choice(true, 0, ++next, "Three");
        choicesList.push(choices["Three"]);
        choices["Four"] = Choice(true, 0, ++next, "Four");
        choicesList.push(choices["Four"]);
    }

    function getChoicesCount() public returns(uint) {
        return choicesList.length;
    }
    
    function vote(string memory choiceName) public {
        require(voters[msg.sender].voted == false, "This voter already voted");
        require(choices[choiceName].isReal == true, "No such choice exists");
        if(!voters[msg.sender].isReal) {
            initNewVoter(msg.sender);
        }
        //Adding votes to the proper choice in data structures
        choices[choiceName].votedAmount = choices[choiceName].votedAmount 
                + voters[msg.sender].votsHoliding;
        uint n = uint(choices[choiceName].listPointer);
        choicesList[n].votedAmount = choicesList[n].votedAmount 
                    + voters[msg.sender].votsHoliding;
        
        //Editing voter after voting
        voters[msg.sender].votsHoliding = 0;
        voters[msg.sender].voted = true;
        voters[msg.sender].delegate = address(0x0);
    }
    
    function getVoter(address adr) public view returns(bool voted, bool isReal, 
                            address delegate, uint votesHolding ) {
        return (voters[adr].voted, voters[adr].isReal, voters[adr].delegate,
                                voters[adr].votsHoliding);                            
    }
    
    function delegateVote(address delegate) public {
        require(voters[msg.sender].voted == false, "You already voted");
        
        if(!voters[msg.sender].isReal) {
            initNewVoter(msg.sender);
        }
        if(!voters[delegate].isReal) {
            initNewVoter(delegate);
        }
        voters[delegate].votsHoliding++;
        
        //Edit voter after delegation        
        voters[msg.sender].delegate = delegate;
        voters[msg.sender].votsHoliding = 0;
        voters[msg.sender].voted = true;
        
    }
    
    function initNewVoter(address adr) internal {
         voters[adr].isReal = true;
         voters[adr].voted = false;
         voters[adr].votsHoliding = 1;
    }
    
    
    function getVotedAmount(string memory choice) public view returns(uint) {
        require(choices[choice].isReal == true, "No such choice exists");
        return choices[choice].votedAmount;
    }
    
    function getChoice(string memory name) public view returns (bool, uint, 
                            int , string memory){
        return (choicesList[uint(choices[name].listPointer)].isReal,
                    choicesList[uint(choices[name].listPointer)].votedAmount,
                    choicesList[uint(choices[name].listPointer)].listPointer, 
                    choicesList[uint(choices[name].listPointer)].name);
    } 
    
    function getVotesHolding(address adr) public view returns(uint) {
        if(voters[adr].isReal) {
            return voters[adr].votsHoliding;    
        } else {
            return 1;
        }
    }
    
   
    
    function getChoiceNameFromList(uint index) public view returns(string memory name) {
        require(choicesList[index].isReal == true, "No such choice exist in list");
        return choicesList[index].name;
    }
}