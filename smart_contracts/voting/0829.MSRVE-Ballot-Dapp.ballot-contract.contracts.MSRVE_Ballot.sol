pragma solidity ^0.5.11;

contract MSRVE_Ballot {

    struct Voter {
        uint weight;
        bool voted;
        uint256[] vote; //ranked vote
        uint256[] curList; //updated temp list of calculating final votes
        uint256 preference; //your first prefrnc
        address delegate;
    }

    address admin;
    address[] voterList;
    uint256 numProposals; //candidates to be voted for
    uint256[] runningCount;
    bool[] invalidCandidates; //to Remove Loosers
    mapping(address => Voter) voters;

    uint public voteCount; //how many ppl have voted
    uint public abstainCount; //number of people abstained

    uint256 public winner;
    bool calc;

    enum Phase {Regs, Vote, Done}

    Phase public state;

    modifier validPhase(Phase reqPhase) {require(state == reqPhase, "Phase is invalid. Contact admin."); _;}

    modifier onlyAdmin() {require(msg.sender == admin, "YOU. SHALL. NOT. PASS!"); _;}

    modifier canVote() {require(voters[msg.sender].voted == false, "No voting for you kiddo!"); _;}

    constructor (uint8 num) public  {

        admin = msg.sender;
        voters[admin].weight = 1;
        state = Phase.Regs;
        numProposals = num;
        runningCount.length = num;
        invalidCandidates.length = num;
        voteCount = 0;
        abstainCount = 0;
        calc = false;
    }

    function changeState(Phase x) public onlyAdmin{
        state = x;
    }

    function register() public validPhase(Phase.Regs) {

        require (voters[msg.sender].weight == 0, "Already registered!");   // So that func can run once per user.
        voters[msg.sender].weight = 1;
    }

    function vote(uint256[] memory inputArray) public canVote validPhase(Phase.Vote) {

        require(voters[msg.sender].weight > 0, "Register first!");
        //running count of given index should be incremented by weight(for now 1)
        runningCount[inputArray[inputArray.length-1]] += voters[msg.sender].weight;

        voters[msg.sender].preference = inputArray[inputArray.length-1];
        voters[msg.sender].vote = inputArray; //initial vote prefrnc of voter
        voters[msg.sender].curList = inputArray;
        voters[msg.sender].curList.pop();
        voters[msg.sender].voted = true;
        voterList.push(msg.sender);

        voteCount += voters[msg.sender].weight;

    }

    function delegatedTo(address To) public canVote validPhase(Phase.Vote) {

        require(To != msg.sender, "Don't delegate to self.");

        address to = To;

        Voter storage sender = voters[msg.sender]; // assigns reference
        //chain reaction
        while (voters[to].delegate != address(0) && voters[to].delegate != msg.sender)
            to = voters[to].delegate;
        //no round robin
        if (to == msg.sender)
            revert("Delegation DCG");

        sender.voted = true;
        sender.delegate = to;
        Voter storage dTo = voters[to];

        if (!dTo.voted)
            dTo.weight += sender.weight;
        else
            revert("New person already voted!");
    }

    function abstain() public canVote validPhase(Phase.Vote) {

        voters[msg.sender].voted = true;
        abstainCount++;
    }

    // function calcWinner() public validPhase(Phase.Done) returns (uint256 ) {
    function calcWinner() public onlyAdmin validPhase(Phase.Done) {

        require(voterList.length > 0, "No votes!");
        require(!calc, "Winner already calculated!");

        // if(calc)
        //     return winner;

        for(uint8 recur = 0; recur < numProposals-1; recur += 1){
            // Loop should have a solution in numProposals-1 iterations.
            // While loop here could cause infinite loop.

            uint256 max = 0; //max votes right now in the array- for current leading candidate
            uint256 min = 2**10; //min votes right now- for knockout candidate
            uint256 win = numProposals; //one with max
            uint256 lose = 0; //one with min

            for(uint8 i = 0; i < numProposals; i += 1){
                if(max<runningCount[i]) {
                    max = runningCount[i];
                    win = i;
                }
                if(min>runningCount[i] && !invalidCandidates[i]) {
                    min = runningCount[i];
                    lose = i;
                }
            }

            if(max > voteCount / 2) {
                winner = win;
                calc = true;
                return;
            }
            else {
                invalidCandidates[lose] = true;
                runningCount[lose] = 0;
                for(uint8 j = 0; j < voterList.length; j += 1) {
                    //if your candidate is now out we need your next preference
                    if(voters[voterList[j]].preference == lose){
                        // recalc
                        voters[voterList[j]].preference = voters[voterList[j]].curList[voters[voterList[j]].curList.length-1];
                        voters[voterList[j]].curList.pop();
                        runningCount[voters[voterList[j]].preference] += 1;
                    }
                }
            }


        }
        // return winner;
    }

    function getWinner() public view validPhase(Phase.Done) returns (uint256) {
        require(calc, "Winner not calculated!");
        return winner;
    }
}
