// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SULToken.sol";

uint constant voterSoul = 100;

contract Mayor {
    
    // STRUCTS, EVENTS and MODIFIERS
    struct Candidate {
        uint soul;
        uint votes;
    }
    
    // Store refund data
    struct Refund {
        uint soul;
        address candidate;
    }
    
    // Data to manage the confirmation
    struct Conditions {
        uint32 quorum;
        uint32 envelopes_casted;
        uint32 envelopes_opened;
        bool outcome_announced;
        address winner;
    }
    
    event NewMayor(address _candidate);
    event Tie(address _escrow);
    event EnvelopeCast(address _voter);
    event EnvelopeOpen(address _voter, uint _soul, address _candidate);
    event Registered(address _voter);

    // Someone can register to receive the SOUL only one time
    modifier canRegister() {
        require(!registered[msg.sender], "The voter already received the soul");
        require(voterSoul < sul.balanceOf(address(this)), "Not enough tokens in the contract balance");
        _;
    }
    
    // Someone can vote as long as the quorum is not reached
    modifier canVote() {
        require(voting_condition.envelopes_casted < voting_condition.quorum, "Cannot vote now, voting quorum has been reached");
        require(registered[msg.sender], "The voter should first register to receive soul");
        _;   
    }
    
    // Envelopes can be opened only after receiving the quorum
    modifier canOpen() {
        require(voting_condition.envelopes_casted == voting_condition.quorum, "Cannot open an envelope, voting quorum not reached yet");
        _;
    }
    
    // The outcome of the confirmation can be computed only one time as soon as all the casted envelopes have been opened
    modifier canCheckOutcome() {
        require(voting_condition.envelopes_opened == voting_condition.quorum, "Cannot check the winner, need to open all the sent envelopes");
        require(voting_condition.outcome_announced == false, "Cannot check the winners, it was already checked");
        _;
    }

    // STATE ATTRIBUTES
    SULToken private sul;
        
    // Candidates
    address[] public candidates;
    mapping(address => Candidate) public candidates_state;

    // Escrow
    address payable public escrow;

    // Voters
    address[] voters;
    mapping(address => bool) registered;
    mapping(address => bytes32) envelopes;
    
    // Results and refund variables
    Conditions public voting_condition;
    mapping(address => Refund) souls;

    /// @notice The constructor only initializes internal variables
    /// @param _candidates (array) The addresses of the mayor candidates
    /// @param _escrow (address) The address of the escrow account
    /// @param _quorum (address) The number of voters required to finalize the confirmation
    constructor(address[] memory _candidates, address payable _escrow, uint32 _quorum, address _SULtoken) {
        require(_candidates.length > 0, "The candidates must be at least one");

        // Init ERC20 SUL token
        sul = SULToken(_SULtoken);

        // Init voting variables
        for (uint i = 0; i < _candidates.length; i++) {
            candidates_state[_candidates[i]] = Candidate({soul: 0, votes: 0});
            candidates.push(_candidates[i]);
        }
        escrow = _escrow;
        voting_condition = Conditions({quorum: _quorum, envelopes_casted: 0, envelopes_opened: 0, outcome_announced: false, winner: address(0)});
    }

    // @notice Register the voter by sending soul tokens in order to cast the envelope
    function register() canRegister external {
        sul.transfer(msg.sender, voterSoul);
        registered[msg.sender] = true;
        emit Registered(msg.sender);
    }


    /// @notice Store a received voting envelope
    /// @param _envelope The envelope represented as the keccak256 hash of (sigil, candidate, soul) 
    function cast_envelope(bytes32 _envelope) canVote external {
        if (envelopes[msg.sender] == 0x0) // => NEW, update on 17/05/2021
            voting_condition.envelopes_casted++;

        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);
    }
    
    
    /// @notice Open an envelope and store the vote information
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _candidate (address) The voting preference
    /// @dev The soul is sent as ERC20 token
    /// @dev Need to recompute the hash to validate the envelope previously casted
    function open_envelope(uint _sigil, address _candidate) canOpen external payable {
        require(envelopes[msg.sender] != 0x0, "The sender has not casted any votes");
        require(souls[msg.sender].soul == 0, "The sender has already opened the envelope");
        
        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = compute_envelope(_sigil, _candidate, msg.value);
        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one casted");

        // Payment
        require(sul.allowance(msg.sender, address(this)) == msg.value, "The value must be the same of the envelope");
        require(sul.transferFrom(msg.sender, address(this), msg.value));

        // Refund 
        souls[msg.sender] = Refund(msg.value, _candidate);
        voters.push(msg.sender);

        // Count souls used for the vote of the Valadilène citizen
        candidates_state[_candidate].votes += 1;
        candidates_state[_candidate].soul += msg.value;
        voting_condition.envelopes_opened++;
            
        emit EnvelopeOpen(msg.sender, msg.value, _candidate);
    }
    
    
    /// @notice Either confirm or kick out the candidate. Refund the electors who voted for the losing outcome
    function mayor_or_sayonara() canCheckOutcome external {
        voting_condition.outcome_announced = true;

        // Check winner
       (address payable probable_winner, uint draw) = find_candidate_with_max_soul();

        if (draw == 0) {
            // Pay the mayor
            sul.transfer(probable_winner, candidates_state[probable_winner].soul);
            voting_condition.winner = probable_winner;
            emit NewMayor(probable_winner);

            // Refund voters that lost
            for (uint i = 0; i < voters.length; i++) {
                address voter = voters[i];

                if (souls[voter].candidate != probable_winner) {
                    address payable loser = payable(voter);
                    sul.transfer(loser, souls[voter].soul);
                }
            }
        } else {
            // Pay the escrow
            uint total_soul = 0;
            for (uint i = 0; i < candidates.length; i++) {
                address addr = candidates[i];
                total_soul += candidates_state[addr].soul;
            }

            sul.transfer(escrow, total_soul);            
            emit Tie(escrow);
        }

    }

    function find_candidate_with_max_soul() private view returns (address payable, uint) {
        // Check winner
        address probable_winner;
        uint max_soul = 0;
        uint max_votes = 0;
        uint draw = 0;

        // Find the candidate with the maximum number of souls
        for (uint i = 0; i < candidates.length; i++) {
            address addr = candidates[i];

            if (candidates_state[addr].soul > max_soul) {
                max_soul = candidates_state[addr].soul;
                max_votes = candidates_state[addr].votes;
                probable_winner = addr;
                draw = 0;
            } else if (candidates_state[addr].soul == max_soul) {
                    max_votes = candidates_state[addr].votes;
                if (candidates_state[addr].votes > max_votes) {
                    max_soul = candidates_state[addr].soul;
                    max_votes = candidates_state[addr].votes;
                    probable_winner = addr;
                    draw = 0;
                } else {
                    draw += 1;
                }
            }
        }

        return (payable(probable_winner), draw);
    }
 

    /// @notice Compute a voting envelope
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _candidate (address) The voting preference
    /// @param _soul (uint) The soul associated to the vote
    function compute_envelope(uint _sigil, address _candidate, uint _soul) public pure returns(bytes32) {
        return keccak256(abi.encode(_sigil, _candidate, _soul));
    }

    /// @notice Return the number of candidates
    function candidates_number() external view returns (uint) {
        return candidates.length;
    }

}