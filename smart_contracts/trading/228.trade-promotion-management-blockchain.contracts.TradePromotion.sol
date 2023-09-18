
pragma solidity ^0.4.24;

contract TradePromotion {

    struct Account {
        string name;
        uint256 trustPoints;
        uint256[] appliedPromotions;
    }

    mapping (address => Account) private accounts;

    event promotionTxnEvent (
        uint indexed _promoId
    );

    modifier onlyOwner(address _addr) {
        require(msg.sender == _addr, "You are not authorized");
        _;
    }

    function addAccount(address _addr, string _name, uint256 _tp) public {
        accounts[_addr].name = _name;
        accounts[_addr].trustPoints = _tp;
        emit promotionTxnEvent(0);
    }

    function getAccountName(address _addr) public  view returns (string){
        return accounts[_addr].name;
    }

    function getAccountTrustPoints(address _addr) public  view returns (uint256){
        return accounts[_addr].trustPoints;
    }

    function getAccountPromoHistory(address _addr) public  view returns (uint256[]){
        return accounts[_addr].appliedPromotions;
    }

    function isPromoAvailable (address _addr, uint256 _tpCriteria, uint256 _promoId ) public  view returns (bool) {

        for (uint i = 0; i < accounts[_addr].appliedPromotions.length; i++) {
            if (accounts[_addr].appliedPromotions[i] == _promoId) return false ;
        }
        return accounts[_addr].trustPoints > _tpCriteria && _promoId > 0;
    }

    function applyPromo (address _addr, uint256 _promoId, uint256 _tpCriteria, uint256 _tpCost ) public {
        
        require(isPromoAvailable(_addr, _tpCriteria, _promoId),"Promo cannot be applied as it fails to match criteria");

        accounts[_addr].appliedPromotions.push(_promoId);

        accounts[_addr].trustPoints = accounts[_addr].trustPoints - _tpCost;

        // trigger event
        emit promotionTxnEvent(_promoId);
    }


}