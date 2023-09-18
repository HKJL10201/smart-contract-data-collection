pragma solidity ^0.4.23;

import "./BlockableTransfer.sol";

contract GenericModification is BlockableTransfer {
    Modification[] public modifications;

    struct Modification {
        bytes4 signature;
        bytes32[] payload;
        uint256 windowEnd;
        bool isValid;
        uint yesTotal;
        uint noTotal;
        mapping(address => uint) yesVotesOf;
        mapping(address => uint) noVotesOf;
        bool hasBeenApproved;
    }

    event ModificationCreated(
        bytes4 indexed signature,
        bytes32[] payload,
        uint256 indexed windowEnd,
        uint256 indexed id,
        bytes32 detailsHash
    );

    function createModification(bytes4 _sig, bytes32[] _payload, bytes32 _hash)
    public returns(uint256){
        uint256 _id = modifications.length++;
        Modification storage m = modifications[_id];
        m.signature = _sig;
        m.payload = _payload;
        m.windowEnd = now + windowSize;
        emit ModificationCreated(_sig, _payload, m.windowEnd, _id, _hash);
        return _id;
    }

    function unblockTransfer() public {
        for(uint i=0; i < inVote[msg.sender].length; i++){
            Modification storage m = modifications[i];
            m.noTotal -= m.noVotesOf[msg.sender];
            m.noVotesOf[msg.sender] = 0;
            m.yesTotal -= m.yesVotesOf[msg.sender];
            m.yesVotesOf[msg.sender] = 0;
        }
        delete inVote[msg.sender];
    }

    function accountVotes(uint256 _id, bool _approve) public {
        Modification storage m = modifications[_id];
        if(_approve){
            m.yesTotal -= m.yesVotesOf[msg.sender];
            m.noTotal -= m.noVotesOf[msg.sender];
            m.noVotesOf[msg.sender] = 0;
            m.yesVotesOf[msg.sender] = balances[msg.sender];
            m.yesTotal += balances[msg.sender];
        } else {
            m.noTotal -= m.noVotesOf[msg.sender];
            m.yesTotal -= m.yesVotesOf[msg.sender];
            m.yesVotesOf[msg.sender] = 0;
            m.noVotesOf[msg.sender] = balances[msg.sender];
            m.noTotal += balances[msg.sender];
        }
    }

    function confirmModification(uint256 _id) public {
        Modification storage m = modifications[_id];
        require(now >= m.windowEnd);
        require(m.isValid);
        require(!m.hasBeenApproved);
        m.hasBeenApproved = true;
        callModification(m.signature, m.payload);
    }

    function callModification(bytes4 sig, bytes32[] payload) internal {
        assembly {
            let offset := 0x04
            let len := add(offset, mul(mload(payload), 0x20))
            let data := add(payload, 0x20)

            let x := mload(0x40)
            mstore(x,sig)

            for {} lt(offset, len) {
                offset := add(offset, 0x20)
                data := add(data, 0x20)
            }{
                mstore(add(x,offset),mload(data))
            }

            let success := call(gas, address, 0, x, msize, x, 0x20)
            mstore(0x40,add(x,msize))
        }
    }
}
