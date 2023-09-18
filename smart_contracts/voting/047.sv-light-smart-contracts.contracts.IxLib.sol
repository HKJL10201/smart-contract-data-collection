pragma solidity 0.4.24;


/* This is a convenience library for accessing things through
 * the index.
 *
 * The reason for using this is to cut down on the number of functions
 * in the index (each of which comes with a few hundred byte overhead).
 *
 * For example, the index has many methods that proxy straight to the
 * backend or to payments. These can easily be moved into a library
 * b/c the gas costs will be near the same (or better).
 */


import { IxIface } from "./SVIndex.sol";
import { BBFarmIface } from "./BBFarm.sol";
import { IxPaymentsIface } from "./SVPayments.sol";


library IxLib {
    /**
     * Usage: `using IxLib for IxIface`
     * The idea is to (instead of adding methods that already use
     * available public info to the index) we can create `internal`
     * methods in the lib to do this instead (which means the code
     * is inserted into other contracts inline, without a `delegatecall`.
     *
     * For this reason it's crucial to have no methods in IxLib with the
     * same name as methods in IxIface
     */

    /* Global price and payments data */

    function getPayTo(IxIface ix) internal view returns (address) {
        return ix.getPayments().getPayTo();
    }

    /* Global Ix data */

    function getBBFarmFromBallotID(IxIface ix, uint256 ballotId) internal view returns (BBFarmIface) {
        bytes4 bbNamespace = bytes4(ballotId >> 48);
        uint8 bbFarmId = ix.getBBFarmID(bbNamespace);
        return ix.getBBFarm(bbFarmId);
    }

    /* Global backend data */

    function getGDemocsN(IxIface ix) internal view returns (uint256) {
        return ix.getBackend().getGDemocsN();
    }

    function getGDemoc(IxIface ix, uint256 n) internal view returns (bytes32) {
        return ix.getBackend().getGDemoc(n);
    }

    function getGErc20ToDemocs(IxIface ix, address erc20) internal view returns (bytes32[] democHashes) {
        return ix.getBackend().getGErc20ToDemocs(erc20);
    }

    /* Democ specific payment/account data */

    function accountInGoodStanding(IxIface ix, bytes32 democHash) internal view returns (bool) {
        return ix.getPayments().accountInGoodStanding(democHash);
    }

    function accountPremiumAndInGoodStanding(IxIface ix, bytes32 democHash) internal view returns (bool) {
        IxPaymentsIface payments = ix.getPayments();
        return payments.accountInGoodStanding(democHash) && payments.getPremiumStatus(democHash);
    }

    function payForDemocracy(IxIface ix, bytes32 democHash) internal {
        ix.getPayments().payForDemocracy.value(msg.value)(democHash);
    }

    /* Democ getters */

    function getDOwner(IxIface ix, bytes32 democHash) internal view returns (address) {
        return ix.getBackend().getDOwner(democHash);
    }

    function isDEditor(IxIface ix, bytes32 democHash, address editor) internal view returns (bool) {
        return ix.getBackend().isDEditor(democHash, editor);
    }

    function getDBallotsN(IxIface ix, bytes32 democHash) internal view returns (uint256) {
        return ix.getBackend().getDBallotsN(democHash);
    }

    function getDBallotID(IxIface ix, bytes32 democHash, uint256 n) internal view returns (uint256) {
        return ix.getBackend().getDBallotID(democHash, n);
    }

    function getDInfo(IxIface ix, bytes32 democHash) internal view returns (address erc20, address admin, uint256 _nBallots) {
        return ix.getBackend().getDInfo(democHash);
    }

    function getDErc20(IxIface ix, bytes32 democHash) internal view returns (address erc20) {
        return ix.getBackend().getDErc20(democHash);
    }

    function getDHash(IxIface ix, bytes13 prefix) internal view returns (bytes32) {
        return ix.getBackend().getDHash(prefix);
    }

    function getDCategoriesN(IxIface ix, bytes32 democHash) internal view returns (uint) {
        return ix.getBackend().getDCategoriesN(democHash);
    }

    function getDCategory(IxIface ix, bytes32 democHash, uint categoryId) internal view returns (bool, bytes32, bool, uint) {
        return ix.getBackend().getDCategory(democHash, categoryId);
    }

    function getDArbitraryData(IxIface ix, bytes32 democHash, bytes key) external view returns (bytes) {
        return ix.getBackend().getDArbitraryData(democHash, key);
    }
}
