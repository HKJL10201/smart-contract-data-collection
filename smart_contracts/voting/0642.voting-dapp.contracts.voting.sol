pragma solidity >= 0.4.0 < 0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title PollContract
 * @notice Following is the PollContract which is used to set up a single choice Poll.
 *          The owner of Contract initializes the Poll with PollName and options and duration in days for which poll is active.
 *          A user can vote once to one option in the duration when the poll is active.
 */
contract PollContract {
    /**
     * @dev owner is the owner of contract, the one who deploys the contract.
     */
    address public owner;

    /**
     * @dev pollName is name of Poll. For example, "What is your favorite sport ?" is pollName.
     */
    string public pollName;

    /**
     * @dev duration is the duration for which poll is active. It is represented in days.
     */
    uint256 public duration;

    /**
     * @dev startTime is the time when contract is deployed.
     */
    uint256 public startTime;

    /**
     * @dev struct Voter stores to whom voter Voted and if the user voted.
     */
    struct Voter {
        uint256 votedTo;
        bool voted;
    }

    /**
     * @dev struct Option stores number of votes received and name of Vote.
     */
    struct Option {
        string name;
        uint256 voteCount;
    }

    /**
     * @dev Array to store options in poll.
     */
    Option[] public options;

    /**
     * @dev Mapping to map details of Voter to address.
     */
    mapping(address => Voter) voter;

    /**
     * @notice Following event is emmited whenever user votes.
     */
    event Voted(address _address);

    /**
     * @notice Following Event is emmited whenever new Poll is started.
     */
    event PollStarted(address _address, string pollName, Option[] _options);

    /**
     * @notice Constructor initializes the contract with _pollName, _options and duration.
     * @param _pollName is the name of Poll and it is a string. For example, "What is your favourite colour".
     * @param _options is an array of strings which contains options for poll.
     * @param _duration is the number of days for which poll will be active.
     *
     * @dev Example for deploying contract :
     *      _pollName: "What is your favorite colour ?",
     *      _options: ["Red", "Blue", "black", "Green"],
     *      _duration: 1  (poll will be active for 1 day).
     */
    constructor(
        string memory _pollName,
        string[] memory _options,
        uint256 _duration
    ) public {
        pollName = _pollName;
        duration = _duration;
        owner = msg.sender;

        startTime = now;

        for (uint256 i = 0; i < _options.length; i++) {
            options.push(Option({name: _options[i], voteCount: 0}));
        }
        emit PollStarted(address(this), _pollName, options);
    }

    /**
     * @dev modifier to restrict onlyOwner to call a function.
     */
    modifier onlyOwner(address _address) {
        require(_address == owner);
        _;
    }

    /**
     * @dev modifier to restrict user to invoke function while poll is in active.
     */
    modifier pollActive() {
        require(
            now <= startTime + (duration * 1 days) && now >= startTime,
            "This Poll has ended or not started"
        );
        _;
    }

    /**
     * @dev modifier to prevent user from voting more than once.
     */
    modifier didVote() {
        require(voter[msg.sender].voted == false, "User has already voted");
        _;
    }

    /**
     * @notice function for user to cast a vote. A user can cast vote only once while poll is active.
     * @param voteTo index of option to which user wants to cast vote.
     *
     * @notice Note that indexing starts from zero.
     */
    function vote(uint256 voteTo) public didVote pollActive {
        options[voteTo].voteCount++;
        voter[msg.sender].voted = true;

        emit Voted(msg.sender);
    }

    /**
     * @notice Function to calculate option with maximum vote.
     * @return Option with maximum votes.
     */
    function result() public view returns (Option memory) {
        require(now > startTime+(duration*1 days), "cannot see results before voting time is over");
        uint256 maxVote = 0;
        uint256 index = 0;
        for (uint256 i = 0; i < options.length; i++) {
            if (options[i].voteCount > maxVote) {
                maxVote = options[i].voteCount;
                index = i;
            }
        }

        return (options[index]);
    }
}

/**
 * @title ProposePoll
 * @notice Following is the Factory Contract for PollContract. It deploys new PollContract
 *          and store there addresses.
 */
contract ProposePoll {
    /**
     * @dev All PollContract instances deployed from this contract are stored here.
     */
    PollContract[] public allPolls;

    /**
     * @dev This variable keep counts of number of instances of PollContract deployed from this contract.
     */
    uint256 contractCount;

    /**
     * @notice This mapping between address and array of PollContract can be used by user to get address of instances created
     *          by him.
     */
    mapping(address => PollContract[]) polls;

    constructor() public {
        contractCount = 0;
    }

    /**
     * @notice This is the funtion where a user can create an instance of PollContract.
     * @param pollName is the name of Poll and it is a string. For example, "What is your favourite colour".
     * @param options is an array of strings which contains options for poll.
     * @param duration is the number of days for which poll will be active.
     *
     * @dev Example for deploying contract :
     *      pollName: "What is your favorite colour ?",
     *      options: ["Red", "Blue", "black", "Green"],
     *      duration: 1  (poll will be active for 1 day).
     *
     * @return instance of PollContract.
     */
    function addNewPoll(
        string memory pollName,
        string[] memory options,
        uint256 duration
    ) public returns (PollContract) {
        PollContract pollContract = new PollContract(
            pollName,
            options,
            duration
        );

        polls[msg.sender].push(pollContract);
        allPolls.push(pollContract);
        contractCount++;

        return (pollContract);
    }

    /**
     * @notice Function to return Polls propesed by msg.sender. Using this fumction, user gets
     *          an array of instances deployed by him.
     */
    function getUserPolls() public view returns (PollContract[] memory) {
        return (polls[msg.sender]);
    }
}
