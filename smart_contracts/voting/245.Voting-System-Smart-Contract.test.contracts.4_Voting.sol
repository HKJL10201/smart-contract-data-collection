pragma solidity ^0.8.0;

contract Voting {
    address public chairman;
    string public title;
    mapping(address => Voter) voters;
    address[] public voters_array;
    bool is_ended;
    uint256 agree_counters;
    uint256 disagree_counters;
    uint256 start_time;
    uint256 end_time;
    uint256 public max_voters;
    uint256 max_candid_vote = 0;
    string max_candid;
    mapping(string => uint256) votes_num_of_candids;
    string[] public candids;
    struct Voter {
        bool can_vote;
        bool voted;
        bool vote;
    }

    constructor(
        string memory _title,
        uint256 _start_time,
        uint256 _end_time,
        uint256 _max_voters,
        string[] memory _candids
    ) {
        for (uint256 j = 0; j < _candids.length; j++) {
            votes_num_of_candids[_candids[j]] = 0;
        }
        start_time = _start_time;
        end_time = _end_time;
        max_voters = _max_voters;
        candids = _candids;
        chairman = msg.sender;
        title = _title;
        is_ended = false;
    }

    function extend(uint256 _end_time) public {
        require(msg.sender == chairman, "only chairman can extend the time!");
        require(block.timestamp <= end_time, "THE ELECTION HAS BEEN ENDED!");
        end_time = _end_time;
    }

    function is_repeated(address[] memory _voters) public view returns (bool) {
        for (uint256 i = 0; i < _voters.length; i++) {
            for (uint256 j = 0; j < voters_array.length; j++) {
                if (_voters[i] == voters_array[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function larger_than_max(address[] memory _voters)
        public
        view
        returns (bool)
    {
        if (voters_array.length + _voters.length > max_voters) {
            return true;
        }
        return false;
    }

    function is_cancelled() public view returns (bool) {
        uint sum=0;
        for (uint256 j = 0; j < candids.length; j++) {
            sum+=votes_num_of_candids[candids[j]];
        }
        if(sum<=max_voters/2){
            return true;
        }else{
            return false;
        }
    }

    function no_winner() public view returns (bool) {
        for (uint256 j = 0; j < candids.length; j++) {
            if ( keccak256(abi.encodePacked((candids[j]))) != keccak256(abi.encodePacked((max_candid))) ) {
                if (votes_num_of_candids[candids[j]] == max_candid_vote) {
                    return true;
                }
            }
        }
        return false;
    }


    function enter_voters(address[] memory _voters) public {
        require(msg.sender == chairman, "only chairman can enter voters!");
        require(block.timestamp <= end_time, "THE ELECTION HAS BEEN ENDED!");
        require(!is_repeated(_voters), "IS REPEATED!");
        require(!larger_than_max(_voters), "LARGER THAN MAX!");
        for (uint256 i = 0; i < _voters.length; i++) {
            voters_array.push(_voters[i]);
            give_voter_right(_voters[i]);
        }
    }

    function give_voter_right(address voter) public {
       // require(!is_ended, "this voting has been ended");
        require(msg.sender == chairman, "only chairman can give right to vote");
        require(block.timestamp <= end_time, "THE ELECTION HAS BEEN ENDED!");
        require(!voters[voter].voted, "the voter already voted");
        voters[voter].can_vote = true;
    }

    function vote(string memory _vote) public {
        //require(!is_ended, "this voting has been ended");
        require(
            block.timestamp >= start_time,
            "THE ELECTION HAS NOT BEEN STARTED YET!"
        );
        require(block.timestamp <= end_time, "THE ELECTION HAS BEEN ENDED!");
        Voter storage sender = voters[msg.sender];
        require(sender.can_vote, "He/She has no right to vote");
        require(!sender.voted, "Already voted");

        sender.voted = true;
        votes_num_of_candids[_vote]++;
        //sender.vote = _vote;
        /*
        if (_vote) {
            agree_counters++;
        } else {
            disagree_counters++;
        }
        */
    }

    /*
    function end_of_voting() public{
        require(
            msg.sender==chairman,
            "only chairman can end voting"
        );
        is_ended=true;
    }*/
    function result() public returns (string memory) {
        //require(is_ended, "this voting is not over yet!");
        require(
            block.timestamp >= start_time,
            "THE ELECTION HAS NOT BEEN STARTED YET!"
        );
        require(block.timestamp > end_time, "THE ELECTION HAS NOT BEEN ENDED!");
        max_candid = candids[0];
        for (uint256 j = 1; j < candids.length; j++) {
            if (votes_num_of_candids[candids[j]] > max_candid_vote) {
                max_candid_vote = votes_num_of_candids[candids[j]];
                max_candid = candids[j];
            }
        }
        //bool is_ca=is_cancelled;
        require(!is_cancelled(),"is cancelled!");
        require(!no_winner(),"NO WINNER!");
        return max_candid;
    }
}
