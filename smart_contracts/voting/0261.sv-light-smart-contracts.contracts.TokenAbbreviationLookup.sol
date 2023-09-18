pragma solidity 0.4.24;


import { hasAdmins } from "./SVCommon.sol";
import "../libs/MemArrApp.sol";


/**
 * Sort of does what it says on the box
 */
contract TokenAbbreviationLookup is hasAdmins {

    event RecordAdded(bytes32 abbreviation, bytes32 democHash, bool hidden);

    struct Record {
        bytes32 democHash;
        bool hidden;
    }

    struct EditRec {
        bytes32 abbreviation;
        uint timestamp;
    }

    mapping (bytes32 => Record) public lookup;

    EditRec[] public edits;

    function nEdits() external view returns (uint) {
        return edits.length;
    }

    function lookupAllSince(uint pastTs) external view returns (bytes32[] memory abrvs, bytes32[] memory democHashes, bool[] memory hiddens) {
        bytes32 abrv;
        for (uint i = 0; i < edits.length; i++) {
            if (edits[i].timestamp >= pastTs) {
                abrv = edits[i].abbreviation;
                Record storage r = lookup[abrv];
                abrvs = MemArrApp.appendBytes32(abrvs, abrv);
                democHashes = MemArrApp.appendBytes32(democHashes, r.democHash);
                hiddens = MemArrApp.appendBool(hiddens, r.hidden);
            }
        }
    }

    function addRecord(bytes32 abrv, bytes32 democHash, bool hidden) only_admin() external {
        lookup[abrv] = Record(democHash, hidden);
        edits.push(EditRec(abrv, now));
        emit RecordAdded(abrv, democHash, hidden);
    }

}
