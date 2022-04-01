pragma solidity ^0.4.24;

// Voter contract class
contract Voter {
    // ---- enum and struct declaration ----
    enum CitizenState { notpermitted, waiting, redeemed, voted } // Represent citizen status

    struct CitizenData {
        CitizenState state;
        bytes32 key;
    } // Represent citizen data

    // ---- Public variable, can access with autogen getter ----
    uint public totalCitizens; // total citizen in the system
    uint public totalCandidates; // total candidate in the system
    uint[4] public citizenStateCount; // count citizen for each state

    // ---- Private variable for internal use ----
    mapping (uint=>CitizenData) private citizenList; // List of citizen id and their citizen data
    mapping (uint=>uint) private candidateList; // List of candidate id and their vote counter

    // ---- Event declaration ----
    event Redeem(uint indexed citId, bytes32 key);
    event Vote(uint indexed citId, bytes32 key, uint canId);

    // ---- Constructor initialize contract when deployed ----
    constructor(uint[] citizens, uint[] candidates) public {
        // Init counter
        totalCitizens = citizens.length;
        totalCandidates = candidates.length;
        citizenStateCount[uint256(CitizenState.waiting)] = totalCitizens;

        // Init citizenList
        for (uint32 i = 0; i < totalCitizens; i++) {
            citizenList[citizens[i]] = CitizenData(CitizenState.waiting, "");
        }

        // Init candidateList
        for (i = 0; i < totalCandidates; i++) {
            candidateList[candidates[i]] = 0;
        }
    }

    // ---- Manipulating function ----

    // Redeem token for specific citizen id and set their secret key for voing
    function redeemToken(uint citId, bytes32 key) public returns(bool success) {
        // Check permission
        if (citizenList[citId].state != CitizenState.waiting) return false;

        // Update citizen state and key
        citizenList[citId].state = CitizenState.redeemed;
        citizenList[citId].key = key;

        // Update counter
        citizenStateCount[uint256(CitizenState.waiting)]--;
        citizenStateCount[uint256(CitizenState.redeemed)]++;

        emit Redeem(citId, citizenList[citId].key);

        return true;
    }

    // Using citizen id and their corresponding secret key to vote for specific candidate id
    function vote(uint citId, bytes32 key, uint canId) public returns(bool success) {
        // Check permission and key
        if (citizenList[citId].state != CitizenState.redeemed || citizenList[citId].key != key) return false;

        // Increment candidate vote and update citizen state
        candidateList[canId]++;
        citizenList[citId].state = CitizenState.voted;

        // Update counter
        citizenStateCount[uint256(CitizenState.redeemed)]--;
        citizenStateCount[uint256(CitizenState.voted)]++;

        emit Vote(citId, citizenList[citId].key, canId);

        return true;
    }

    // ---- View function ----

    // Get specific candidate vote count
    function getCandidateVote(uint citId) public view returns(uint) {
        return candidateList[citId];
    }
}