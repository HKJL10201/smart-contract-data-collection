// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Mayor {
    // Structs, events, and modifiers

    // Store refund data
    struct Refund {
        uint soul;
        bool doblon;
    }

    // Data to manage the confirmation
    struct Conditions {
        uint32 quorum;
        uint32 envelopes_casted;
        uint32 envelopes_opened;
    }

    event NewMayor(address _candidate);
    event Sayonara(address _escrow);
    event EnvelopeCast(address _voter);
    event EnvelopeOpen(address _voter, uint _soul, bool _doblon);

    // Someone can vote as long as the quorum is not reached
    modifier canVote() {
        require(voting_condition.envelopes_casted < voting_condition.quorum,
                "Cannot vote now, voting quorum has been reached");
        _;
    }

    // Envelopes can be opened only after receiving the quorum
    modifier canOpen() {
        require(voting_condition.envelopes_casted == voting_condition.quorum,
                "Cannot open an envelope, voting quorum not reached yet");
        _;
    }

    // The outcome of the confirmation can be computed as soon as all the casted envelopes have been opened
    modifier canCheckOutcome() {
        require(voting_condition.envelopes_opened == voting_condition.quorum,
                "Cannot check the winner, need to open all the sent envelopes");
        _;
    }

    // State attributes
    // Initialization variables
    address payable public candidate;
    address payable public escrow;

    // Voting phase variables
    mapping(address => bytes32) envelopes;

    Conditions voting_condition;

    uint public naySoul;
    uint public yaySoul;

    // Refund phase variables
    mapping(address => Refund) souls;
    address payable[] voters;
    bool private flag = false;

    /// @notice The constructor only initializes internal variables
    /// @param _candidate (address) The address of the mayor candidate
    /// @param _escrow (address) The address of the escrow account
    /// @param _quorum (address) The number of voters required to finalize the confirmation
    constructor(address payable _candidate, address payable _escrow, uint32 _quorum) public {
        candidate = _candidate;
        escrow = _escrow;
        voting_condition = Conditions({quorum: _quorum, envelopes_casted: 0, envelopes_opened: 0});
    }

    /// @notice Store a received voting envelope
    /// @param _envelope The envelope represented as the keccak256 hash of (sigil, doblon, soul)
    function cast_envelope(bytes32 _envelope) canVote public {
        if(envelopes[msg.sender] == 0x0) // checking if already voted, no increment, else increment
            voting_condition.envelopes_casted++;

        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);
    }

    /// @notice Open an envelope and store the vote information
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _doblon (bool) The voting preference
    /// @dev The soul is sent as crypto
    /// @dev Need to recompute the hash to validate the envelope previously casted
    function open_envelope(uint _sigil, bool _doblon) canOpen public payable {
        require(envelopes[msg.sender] != 0x0, "The sender has not casted any votes");
        
        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = compute_envelope(_sigil, _doblon, msg.value);

        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one casted");
        souls[msg.sender] = Refund(msg.value, _doblon);
        voters.push(payable(msg.sender)); // Gas = 3

        if (_doblon == true)
            yaySoul += msg.value;
        else
            naySoul += msg.value;
        
        voting_condition.envelopes_opened++;
        emit EnvelopeOpen(msg.sender, msg.value, _doblon);
    }

    /// @notice Either confirm or kick out the candidate. Refund the electors who voted for the losing outcome
    // After all envelopes have been opened, the smart contract checks
    // whether the mayor is confirmed or not: in any case, the voters who expressed the “losing
    // vote” (nay in case of confirmation, yay in case of rejection) get their soul back as refund.
    function mayor_or_sayonara() canCheckOutcome  public {
        require(flag == false, "The function can be called only for a single time.");

        flag = true;
        if (yaySoul > naySoul) {
            uint winner_amount = 0;
            for (uint i = 0; i < voters.length; i++) {
                address payable voter_address = voters[i];
                Refund memory voter = souls[voter_address];
                if (voter.doblon == true)
                    winner_amount += voter.soul;
            }
            candidate.transfer(winner_amount);
            emit NewMayor(candidate);
        } else {
            for (uint i = 0; i < voters.length; i++) {
                address payable user_address = voters[i];
                Refund memory user = souls[user_address];
                if (user.doblon == false)
                    user_address.transfer(user.soul);
            }
            emit Sayonara(escrow);
        }
    }

    /// @notice Compute a voting envelope
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _doblon (bool) The voting preference
    /// @param _soul (uint) The soul associated to the vote
    function compute_envelope(uint _sigil, bool _doblon, uint _soul) public pure returns(bytes32) {
        return keccak256(abi.encode(_sigil, _doblon, _soul)); // 30 gas + 6 gas for each 256 bits of data being hashed
    }
}