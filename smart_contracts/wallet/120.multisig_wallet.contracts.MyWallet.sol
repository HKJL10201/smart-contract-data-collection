pragma solidity ^0.4.0;

import "./mortal.sol";

// inherit from `mortal` contract
contract MyWallet is mortal {
    event receivedFunds(address _from, uint256 _amount);
    event proposalReceived(address indexed _from, address indexed _to, string _reason);
    event sendMoneyPlain(address _from, address _to);

    struct Proposal {
        address _from;
        address _to;
        uint256 _value;
        string _reason;
        bool sent;
    }

    uint proposal_counter;

    // create an array with index (integer) named `m_proposals`
    // example, m_proposals[0] is the first element inside this mapping
    mapping(uint => Proposal) m_proposals;

    function spendMoney(address _to, uint256 _value, string _reason) returns (uint256) {
        if (owner == msg.sender) {
            bool sent = _to.send(_value);
            if (!sent) {
                throw;
            } else {
                sendMoneyPlain(msg.sender, _to);
            }
        } else {
            proposal_counter++;
            m_proposals[proposal_counter] = Proposal(msg.sender, _to, _value, _reason, false);
            proposalReceived(msg.sender, _to, _reason);
            return proposal_counter;
        }
    }

    function confirmProposal(uint proposal_id) onlyowner returns (bool) {
        Proposal proposal = m_proposals[proposal_id];
        // if the address is not nil
        if (proposal._from != address(0)) {
            if (proposal.sent != true) {
                proposal.sent = true;
                if (proposal._to.send(proposal._value)) {
                    return true;
                } else {
                    proposal.sent = false;
                    return false;
                }
            }
        }
    }

    function() payable {
        if (msg.value > 0) {
            receivedFunds(msg.sender, msg.value);
        }
    }

    function getOwner() returns (address) {
        return owner;
    }

    function getLatestProposalId() returns (uint) {
        return proposal_counter;
    }
}
