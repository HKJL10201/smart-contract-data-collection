pragma solidity ^0.4.18;

contract Poll {

    struct Choice {
        string description;
        uint voteCount;
    }

    uint public q;
    address public creator;
    Choice[] public choices;
    uint topChoiceIndex;
    mapping(address => bool) public voters;
    mapping(address => bool) hasVoted;
    uint numVoted;
    bytes choiceNames;

    function Poll(uint quorum) public {
        creator = msg.sender;
        q = quorum;
    }
    
    function setQuorum(uint quorum) public restricted {
        q = quorum;
    }

    function addFriend(address friendAddress) public restricted {
        voters[friendAddress] = true;
    }

    function vote(uint choiceIndex) public {
        require(numVoted < q);
        Choice storage selectedChoice = choices[choiceIndex];
        Choice storage topChoice = choices[topChoiceIndex];
        require(voters[msg.sender]); // User has been added to voters by Creator
        require(!hasVoted[msg.sender]); // User has not yet voted for this particular vote
        hasVoted[msg.sender] = true;
        selectedChoice.voteCount++;
        numVoted++;
        if (selectedChoice.voteCount > topChoice.voteCount) {
            topChoiceIndex = choiceIndex;
        }
    }

    function addChoice(string description) public restricted {
        Choice memory newChoice = Choice({
            description: description,
            voteCount: 0
        });
        choices.push(newChoice);
        /*
        NOTE: This next line enables the printing of all choices in a list; however currently there is no way to do this which isnt incredibly gas-expensive. If you wish to deploy this I recommend you comment this line out.
        */
        addToChoiceName(description);
    }

    function addToChoiceName(string description) private {
        bytes memory desBytes = bytes(description);
        for (uint i=0; i < desBytes.length; i++) {
            choiceNames.push(desBytes[i]);
        }
        choiceNames.push(0x2c);
        choiceNames.push(0x20);

    }

    function listChoices() public view returns (string){
        return string(choiceNames);
    }

    function getChoiceDescription(uint index) public view returns (string) {
        Choice memory choice = choices[index];
        return choice.description;
    }
    function getChoiceVotes(uint index) public view returns (uint) {
        Choice memory choice = choices[index];
        return choice.voteCount;
    }

    function getResult() public view returns (string) {
        require(q <= numVoted);
        Choice memory result = choices[topChoiceIndex];
        return result.description;
    }

    function destroy() public restricted {
        require(msg.sender == creator);
        selfdestruct(creator);
    }


    modifier restricted() {
        // 2. Only the contract creator is able to add n choices via deployed contract
        require(msg.sender==creator);
        _;
    }

}


/*
Yet to implement:

3. The contract creator is able to select m friends to vote for n 

May need to make an array friendslist; then have it so that you can select/deselect people for pols

How would you extend the functionality of the smart contract? The description should appear
as comments in the contract source code. (2 marks)
• List out function definition, variables declaration, and pseudo-code
• Explain why

*/
