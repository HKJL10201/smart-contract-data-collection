pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/drafts/Counters.sol";
import "../Resources/ICryptoRight.sol";

contract CryptoRight is ICryptoRight {
    using Counters for Counters.Counter;

    Counters.Counter idea_ids;

    struct Work {
        address owner;
        string uri;
    }

    mapping(uint256 => Work) public ideas;

    event Copyright(uint256 idea_id, address owner, string reference_uri);

    event OpenSource(uint256 idea_id, string reference_uri);

    event Transfer(uint256 idea_id, address new_owner);

    modifier onlyIdeaOwner(uint256 idea_id) {
        require(
            ideas[idea_id].owner == msg.sender,
            "You do not have permission to alter this copyright!"
        );
        _;
    }

    function copyrightWork(string memory reference_uri) public {
        idea_ids.increment();
        uint256 id = idea_ids.current();

        ideas[id] = Work(msg.sender, reference_uri);

        emit Copyright(id, msg.sender, reference_uri);
    }

    function openSourceWork(string memory reference_uri) public {
        idea_ids.increment();
        uint256 id = idea_ids.current();

        ideas[id].uri = reference_uri;

        emit OpenSource(id, reference_uri);
    }

    function transferIdeaOwnership(uint256 idea_id, address new_owner)
        public
        onlyIdeaOwner(idea_id)
    {
        // Re-maps idea_id to a new copyright owner.
        ideas[idea_id].owner = new_owner;

        emit Transfer(idea_id, new_owner);
    }

    function renounceCopyrightOwnership(uint256 idea_id)
        public
        onlyIdeaOwner(idea_id)
    {
        // Re-maps a given idea_id to the 0x0000000000000000000000000000000000000000
        transferIdeaOwnership(idea_id, address(0));

        emit OpenSource(idea_id, ideas[idea_id].uri);
    }
}
