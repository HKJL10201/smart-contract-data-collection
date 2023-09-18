pragma solidity^0.4.18;

import "./Mortal.sol";

contract MultiSigWallet is Mortal {
    // @notice: indexed keyword lets us filter events with those params
    event receivedFunds(address indexed _from, uint256 _amount);
    event proposalReceived(address indexed _from, address indexed _to, string _reason, uint _idx);

    struct Proposal {
        address _from;
        address _to;
        uint256 _value;
        string _reason;
        bool sent;
    }

    uint proposal_counter;

    mapping(uint256 => Proposal) m_proposals;

    function wasProposalApproved(uint256 proposal_id) onlyowner public view returns (bool) {
      if (m_proposals[proposal_id]._from != address(0)) {
        return m_proposals[proposal_id].sent;
      }
    }

    function spendMoneyOn(address _to, uint256 _value, string _reason) public returns (uint256) {
        if (owner == msg.sender) {
            require(_to.send(_value));
        } else {
            proposal_counter++;
            m_proposals[proposal_counter] = Proposal(msg.sender, _to, _value, _reason, false);
            proposalReceived(msg.sender, _to, _reason, proposal_counter);
            return proposal_counter;
        }
    }

    function confirmProposal(uint proposal_id) onlyowner public returns (bool) {
        Proposal storage proposal =  m_proposals[proposal_id];

        // if it's not 0 address, we can count on it being set
        if (proposal._from != address(0)) {
            if (proposal.sent != true) {
                if (proposal._to.send(proposal._value)) {
                    proposal.sent = true;
                    return true;
                } else {
                  proposal.sent = false;
                  return false;
                }
            }
        }
    }

    function () public payable {
        if (msg.value > 0) {
            receivedFunds(msg.sender, msg.value);
        }
    }
}
