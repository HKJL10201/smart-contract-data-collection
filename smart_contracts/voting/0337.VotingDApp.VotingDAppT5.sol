pragma solidity ^0.4.20;
import "./WorkbenchBase.sol";
import "./VotingIdeaT5.sol";
import "./VotingJudgeT5.sol";

contract IdeaListing is WorkbenchBase("VotingDAppT5", "IdeaListing")
{
    enum StateType { IdeaAvailable, IdeaVoted }

    StateType public State;

    string public Location;
    string public Description;
    address public ParentIdeaContract;
    int public VotingToken;

    address public InstanceJudge;

    function IdeaListing (string location, string description, address parentIdeaAddress) public {
        Location = location;
        Description = description;
        ParentIdeaContract = parentIdeaAddress;

        State = StateType.IdeaAvailable;
        ContractCreated();
    }

    function VoteIdea(int votingToken) public     {
        InstanceJudge = msg.sender;

        VotingToken = votingToken;

        // ensure token is > 0
        if (VotingToken <= 0) {
            revert();
        }

        VotingIdea votingIdea = VotingIdea(ParentIdeaContract);
        VotingJudge votingJudge = VotingJudge(InstanceJudge);

        // check Judge Location match
        //if (!votingJudge.CheckLocation(Location)) {
        //    revert();
        //}

        // check Judge Token Balance
        //if (!votingJudge.HasBalance(votingToken)) {
        //    revert();
        //}

        // indicate idea voted by updating idea and judge balances
        votingIdea.UpdateIdeaBalance(votingToken);
        //votingJudge.UpdateJudgeBalance(-votingToken);

        State = StateType.IdeaVoted;
        ContractUpdated("VoteIdea");
    }
}