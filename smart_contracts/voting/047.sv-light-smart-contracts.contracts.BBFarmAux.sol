pragma experimental ABIEncoderV2;
pragma solidity 0.4.24;

import "./BBFarm.sol";
import "../libs/MemArrApp.sol";

contract BBFarmAux {
    /* util functions - technically don't need to be in this contract (could
     * be run externally) - but easier to put here for the moment */

    // This is designed for v2 BBFarms

    function getVotes(BBFarmIface bbFarm, uint ballotId) external view
        returns ( bytes32[] memory votes
                , address[] memory voters
                , bytes[] memory extras) {

        uint nVotesCast;
        (, nVotesCast,,,,,,,,) = bbFarm.getDetails(ballotId, address(0));

        address voter;
        bytes32 vote;
        bytes memory extra;
        for (uint i = 0; i < nVotesCast; i++) {
            (vote, voter, extra) = bbFarm.getVote(ballotId, i);
            votes = MemArrApp.appendBytes32(votes, vote);
            voters = MemArrApp.appendAddress(voters, voter);
            extras = MemArrApp.appendBytes(extras, extra);
        }
    }

    function getVotesFrom(BBFarmIface bbFarm, uint ballotId, address providedVoter) external view
        returns ( uint256[] memory ids
                , bytes32[] memory votes
                , bytes[] memory extras) {

        uint nVotesCast;
        bool hasVoted;
        (hasVoted, nVotesCast,,,,,,,,) = bbFarm.getDetails(ballotId, providedVoter);

        if (!hasVoted) {
            // return empty arrays - if they voter hasn't voted no point looping through
            // everything...
            return (ids, votes, extras);
        }

        address voter;
        bytes32 vote;
        bytes memory extra;
        for (uint i = 0; i < nVotesCast; i++) {
            (vote, voter, extra) = bbFarm.getVote(ballotId, i);
            if (voter == providedVoter) {
                ids = MemArrApp.appendUint256(ids, i);
                votes = MemArrApp.appendBytes32(votes, vote);
                extras = MemArrApp.appendBytes(extras, extra);
            }
        }
    }
}
