pragma solidity ^0.4.20;

import "./WorkbenchBase.sol";
import "./VotingDAppT4.sol";

contract VotingJudge is WorkbenchBase("VotingDAppT4", "VotingJudge")
{
    enum StateType { JudgeRegistered, CurrentJudgeBalance}

    StateType public State;

    address public InstanceJudge;
    string public Location;
    int public JudgeBalance;

    address public InstanceVotingAdmin;

    function VotingJudge (address judge, string location, int judgeBalance) public {
        InstanceVotingAdmin = msg.sender;

        // ensure only 1 contract created per judge???
//        if (partyA == partyB) {
//            revert();
//        }

        InstanceJudge = judge;
        Location = location;
        JudgeBalance = judgeBalance;

        State = StateType.JudgeRegistered;

        ContractCreated();
    }

    function HasBalance(address judge, int votingToken) public returns (bool) 
    {
        if (judge == InstanceJudge) {
            return (JudgeBalance >= votingToken);
        }

        return false;
    }

    function UpdateJudgeBalance(int votingToken) public 
    {
        JudgeBalance += votingToken;

        State = StateType.CurrentJudgeBalance;
        ContractUpdated("UpdateJudgeBalance");
    }

}
