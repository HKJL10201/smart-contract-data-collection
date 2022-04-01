pragma solidity ^0.5.1;

contract Vote_Token
{

    // primary variable declarations

    uint256 public totalVotes;  //total vote tokens distributed

    uint256 public totalVotesCasted;    // to store the total number of votes casted

    string public name;// to store the name of the vote token distributed

    string public symbol;// to store the name of the vote token distributed


    //structure of a vote token

    struct Vote {
        uint256 _id;
        bool _spent;
        string _party;
        string _constituency;
        uint256 _time;
    }


    //modifier for making function usable by only admin

    modifier onlyOwner(){
        require(admin == msg.sender,"Only owner can do this");
        _;
    }


    //Event emitted when a vote token is spent

    event VoteEvent (
        bytes32 _voterid,
        string indexed _party,
        string indexed _constituency
    );


    //Event emitted when the voting starts

    event VotingStartEvent(
        uint256 _totalVotes
    );


    //Event emitted when a new party is registered

    event PartyRegistryEvent(
            string indexed _constituency,
            string indexed _party
        );


    //Event emitted when the voting process ends

    event VotingEndEvent(
            uint256 _totalVotesCasted
        );

    //Event emitted when the registering of users start

    event RegisteringStartEvent(
            string _name,
            string _symbol
    );



    //enum that contains the state of the voting process

    enum State {Registering, Voting, End }

    State public state;


    //mapping to map voter id to vote

    mapping (bytes32 => Vote) public vote;


    //mapping to map constituency and party to votes

    mapping (string => mapping(string => uint256)) vote_count;

    //to store whether party is registered in the constituency or not
    mapping (string => mapping(string => uint)) party_registery;

    //to store whether constituecy exist or not
    mapping (string => uint) constituency_registery;

    // to store address of the admin who deployed the constract

    address public admin;


    // to initiliaze the value upon contract deployment

    constructor(string memory _name) public{
        admin = msg.sender;
        name = _name;
        state = State.Registering;
        totalVotes = 0;
        symbol = "VOTE";

        emit RegisteringStartEvent(
            name,symbol
        );
    }


    // function to register a party from a constituency

    function registerParty(string memory _constituency, string memory _party)
    public
    onlyOwner {
        require(state == State.Registering,'Registration of parties is only allowed in registration phase');

        vote_count[_constituency][_party] = 0;
        party_registery[_constituency][_party] = 1;
        constituency_registery[_constituency] = 1;

        emit PartyRegistryEvent(
            _constituency,
            _party
        );
    }


    // function called by admin to upgrade the state to voting

    function startVoting()
    public
    onlyOwner {
        require(state == State.Registering,'Voting will start only if registration was active before');
        state = State.Voting;
        totalVotesCasted = 0;
        emit VotingStartEvent(
            totalVotes
        );
    }


    //function called by admin to upgrade the end the voting process

    function endVoting()
    public
    onlyOwner{
        require(state == State.Voting,'Voting will end only after it has started');
        state = State.End;
        emit VotingEndEvent(
            totalVotesCasted
        );
    }


    //function called by any account to register a user for vote

    function register(bytes memory x,string memory _constituency)
    public
    returns (bool success)
    {

        require(state == State.Registering, 'Registration closed ');

        require(constituency_registery[_constituency] == 1,'This constituency is not registered');

        bytes32 _voterid = sha256(x);

        require(vote[_voterid]._id == 0,'Voter already registered');

        totalVotes = totalVotes + 1;

        Vote memory vote_voter = Vote(totalVotes,false,"",_constituency,block.timestamp);

        vote[_voterid] = vote_voter;

        return true;
    }


    //internal function to increment the count of votes a party get in a constituency

    function voteincrement(string memory _party,string memory _constituency)
    internal
    {
        vote_count[_constituency][_party] = vote_count[_constituency][_party] + 1;
    }


    //function to spend the vote tokens

    function spend(bytes memory _voter,string memory _party)
    public
    returns(bool success)
    {
        bytes32 _voterid = sha256(_voter);

        require(party_registery[vote[_voterid]._constituency][_party] == 1,'Party not registered for this constituency');

        require(vote[_voterid]._id >= 1,'The voter is not registered');

        require(vote[_voterid]._spent == false,'This voter token has already been used');

        vote[_voterid]._spent = true;

        totalVotesCasted = totalVotesCasted + 1;

        emit VoteEvent(_voterid,_party,vote[_voterid]._constituency);

        voteincrement(_party,vote[_voterid]._constituency);

        return true;

    }

    //function to revert all the changes

    function destroy()
    public
    onlyOwner
    {
        selfdestruct(msg.sender);

        admin = msg.sender;
        name = "Vote Token";
        state = State.Registering;
        totalVotes = 0;
        symbol = "VOTE";

        emit RegisteringStartEvent(
            name,symbol
        );
    }
}