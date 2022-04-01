pragma solidity ^0.4.18;

import "./TimeLockedWallet.sol";

contract TimeLockedWalletFactory {

    mapping(address => address[]) public walletsOfCreator;
    mapping(address => address[]) public walletsOfOwner;
    mapping(address => address[]) public walletsOfManager;

    event Instantiation(address sender, address wallet);

    function create(address _owner, address _manager, uint64 start, uint64 interval, uint64 _numInterval) public returns(bool) {
        address wallet = new TimeLockedWallet(_owner, msg.sender, _manager, start, interval, _numInterval);

        walletsOfCreator[msg.sender].push(wallet);
        walletsOfOwner[_owner].push(wallet);

        if(_manager != 0) {
            walletsOfManager[_manager].push(wallet);
        }

        emit Instantiation(msg.sender, wallet);
        return true;
    }

    function replaceOwner(address _owner, address _newOwner) public returns(bool) {
        uint n = remove(walletsOfOwner[_owner], msg.sender);
        require(n != 0);

        walletsOfOwner[_newOwner].push(msg.sender);

        return true;
    }

    function getOwnedCount(address owner) public view returns(uint){
        return walletsOfOwner[owner].length;
    }

    function getOwnedWallets(address owner) public view returns(address[]){
        return walletsOfOwner[owner];
    }

    function replaceCreator(address _creator, address _newCreator) public returns(bool) {
        uint n = remove(walletsOfCreator[_creator], msg.sender);
        require(n != 0);

        walletsOfCreator[_newCreator].push(msg.sender);

        return true;
    }

    function getCreatedCount(address creator) public view returns(uint){
        return walletsOfCreator[creator].length;
    }

    function getCreatedWallets(address creator) public view returns(address[]){
        return walletsOfCreator[creator];
    }

    function replaceManager(address _manager, address _newManager) public returns(bool){
        uint n = remove(walletsOfManager[_manager],msg.sender);
        require(n != 0);

        if(_manager != 0) {
            walletsOfManager[_newManager].push(msg.sender);
        }
        return true;
    }

    function getManagedCount(address _manager) public view returns(uint){
        return walletsOfManager[_manager].length;
    }

    function getManagedWallets(address _manager) public view returns(address[]){
        return walletsOfManager[_manager];
    }

    /**
     * internal functions
     */

    function remove(address[] storage list,address item) internal returns(uint affected){
        for(uint i = 0; i < list.length; i++){
            if(list[i] == item){
                list[i] = list[list.length-1];
                list.length--;
                affected++;
                break;
            }
        }
        return affected;
    }
}
