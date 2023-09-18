pragma solidity ^0.4.20;
import "./WorkbenchBase.sol";
import "./VotingIdeaT4.sol";
import "./VotingJudgeT4.sol";

contract IdeaListing is WorkbenchBase("VotingDAppT4", "IdeaListing")
{
    enum StateType { IdeaAvailable, IdeaVoted }

    StateType public State;

    string public Description;
    address public ParentIdeaContract;
    int public VotingToken;

    address public InstanceJudge;

    function IdeaListing (string description, address parentIdeaAddress) public {
        Description = description;
        ParentIdeaContract = parentIdeaAddress;

        State = StateType.IdeaAvailable;
        ContractCreated();
    }

    function VoteIdea(int votingToken) public     {
        InstanceJudge = msg.sender;

        VotingToken = votingToken;

        VotingIdea votingIdea = VotingIdea(ParentIdeaContract);
        VotingJudge votingJudge = VotingJudge(InstanceJudge);

        // check Judge Token Balance
        //if (!votingJudge.HasBalance(InstanceJudge, votingToken)) {
        //    revert();
        //}

        // indicate idea voted by updating idea and judge balances
        votingIdea.UpdateIdeaBalance(votingToken);
        //votingJudge.UpdateJudgeBalance(-votingToken);

        State = StateType.IdeaVoted;
        ContractUpdated("VoteIdea");
    }
}