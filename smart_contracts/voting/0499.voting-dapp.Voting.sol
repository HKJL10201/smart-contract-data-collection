pragma solidity ^0.4.18;

contract Voting {

    mapping (bytes32 => uint8) public votesReceived;
    bytes32[] public machineList;

    function Voting(bytes32[] machineNames) public {
        machineList = machineNames;
    }

    function totalVotesFor(bytes32 machine) view public returns (uint8) {
        require(validMachine(machine));
        return votesReceived[machine];
    }

    function voteForMachine(bytes32 machine) public {
        require(validMachine(machine));
        votesReceived[machine]  += 1;
    }

    function validMachine(bytes32 machine) view public returns (bool) {
        for(uint i = 0; i < machineList.length; i++) {
            if (machineList[i] == machine) {
                return true;
            }
        }
        return false;
    }
}