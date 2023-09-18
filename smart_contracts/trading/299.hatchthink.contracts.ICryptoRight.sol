pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;

interface ICryptoRight {

    struct IWork {
        address owner;
        string uri;
    }

    event Copyright(uint idea_id, address owner, string ref_uri);

    event OpenSource(uint idea_id, string ref_uri);

    event Transfer(uint idea_id, address new_owner);

    function copyrights(uint idea_id) external returns(IWork memory);

    function copyrightWork(string calldata ref_uri) external;

    function openSourceWork(string calldata ref_uri) external;

    function renounceCopyrightOwnership(uint idea_id) external;

    function transferCopyrightOwnership(uint idea_id, address new_owner) external;
}
