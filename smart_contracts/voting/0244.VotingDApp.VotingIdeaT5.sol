pragma solidity ^0.4.20;

import "./WorkbenchBase.sol";
import "./VotingDAppT5.sol";

contract VotingIdea is WorkbenchBase("VotingDAppT5", "VotingIdea")
{
    enum StateType { IdeaRegistered, IdeaListed, CurrentIdeaBalance}

    StateType public State;

    string public Description;
    string public Location;
    int public IdeaBalance;

    address public InstanceValidator;

    address public InstanceVotingAdmin;

    IdeaListing currentIdeaListing;
    address public CurrentIdeaAddress;

    function VotingIdea (string description, string location, address validator) public {
        InstanceVotingAdmin = msg.sender;

        // any validation needed???
//        if (partyA == partyB) {
//            revert();
//        }

        Description = description;
        Location = location;

        InstanceValidator = validator;

        CurrentIdeaAddress = address(this);

        State = StateType.IdeaRegistered;

        ContractCreated();
    }

    function UpdateIdeaBalance(int votingToken) public {
        IdeaBalance += votingToken;

        currentIdeaListing = new IdeaListing(Location, Description, CurrentIdeaAddress);

        State = StateType.CurrentIdeaBalance;
        ContractUpdated("UpdateIdeaBalance");
    }

    function ValidateIdea() public     {
        InstanceVotingAdmin = msg.sender;

        currentIdeaListing = new IdeaListing(Location, Description, CurrentIdeaAddress);

        State = StateType.IdeaListed;
        ContractUpdated("ValidateIdea");
    }
}