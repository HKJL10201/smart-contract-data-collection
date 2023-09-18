pragma solidity ^0.4.19;

import "./mortal.sol";
contract MyWallet is mortal
{
    event recievedFunds(address indexed_from,uint256 _amount);
    event proposalRecieved(address indexed _from,address _to,string _reason,uint proposal_id);
    event confirmedProposal(bool value);
    struct Proposal
    {
        address _from;
        address _to;
        uint256 value;
        string reason;
        bool sent;
    }
    mapping(uint => Proposal) m_proposals;
    uint proposal_counter;
    function spendMoneyOn(address _to,uint256 _value,string _reason) public returns(uint)
    {
        if(msg.sender==owner)
        {
           _to.transfer(_value);
           emit proposalRecieved(msg.sender,_to,_reason,0);
        }
        else
        {
            proposal_counter++;
            m_proposals[proposal_counter]=Proposal(msg.sender,_to,_value,_reason,false);
            emit proposalRecieved(msg.sender,_to,_reason,proposal_counter);
            return proposal_counter;
        }
    }

    function() payable public {
        if(msg.value>0)
        {
            emit recievedFunds(msg.sender,msg.value);
        }
    }
    function confirmProposal(uint proposal_id) onlyOwner public returns(bool)
    {
        Proposal storage proposal=m_proposals[proposal_id];
        if(proposal._from!=address(0))
        {
            if(proposal.sent!=true)
            {
                proposal.sent=true;
                if(proposal._to.send(proposal.value))
                {
                    emit confirmedProposal(true);
                    return true;
                }
                else
                {
                    proposal.sent=false;
                    emit confirmedProposal(false);
                    return false;
                }
            }
        }
    }
}
