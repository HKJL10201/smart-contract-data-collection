//a basic asset tracking functionality in the blockchain.
//from: https://dzone.com/articles/implementing-a-simple-smart-contract-for-asset-tra

pragma solidity ^0.4.24;
import "./ownable.sol";
contract AssetTracker is Ownable{


/*
For different real-world events in the supply chain, such as asset creation or asset transfer, we define counterparts in the smart contract.

*/
  event AssetCreate(address account, uint uuid, string manufacturer);
  event RejectCreate(address account, uint uuid, string message);
  event AssetTransfer(address from, address to, uint uuid);
  event RejectTransfer(address from, address to, uint uuid, string message);
  event AssetDelete(uint id);
struct Asset {
    string name;
    string description;
    bool initialized;
    string manufacturer;
    address ownerAddress;
    uint cost;
    uint assetId;
}
uint8 public totalLandsCounter=0; //total no of lands via this contract at any time
mapping(uint  => Asset) private assetStore;//da intero a un Asset
//assetStore[uuid] = Asset(name, description, true, manufacturer);
mapping(address => mapping(uint => bool)) private walletStore;

mapping (address => Asset[]) public ownedLands;
mapping (address => uint) public ownerAssetCount;


/*
The first function that we would need is the create an asset function.
It takes all the information needed to specify the asset and checks if the asset already exists.
In this case, we trigger a formerly declared event – RejectCreate().
If we have a new asset at hand, we store the data in the asset store and create the relation
between the message sender's wallet and the asset's uuid

*/

//owner shall add lands via this function
function createAsset(string _name, string _description, string _manufacturer, uint _cost) public{

  //verificare se funziona
    // if(assetStore[uuid].initialized) {
    //     emit RejectCreate(msg.sender, uuid, "Asset with this UUID already exists.");
    //     return;
    // }

    Asset memory myAsset = Asset({
             name:_name,
             description:_description,
             initialized: true,
             manufacturer:_manufacturer,
             ownerAddress:msg.sender,
             cost:_cost,
             assetId: totalLandsCounter
    });


    ownedLands[msg.sender].push(myAsset); //tutti gli asset per ogni owner

    assetStore[totalLandsCounter] = myAsset;
    walletStore[msg.sender][totalLandsCounter] = true;
    ownerAssetCount[msg.sender]++;
    emit AssetCreate(msg.sender, totalLandsCounter, _manufacturer);
    totalLandsCounter = totalLandsCounter + 1;

}



function deleteAsset(uint _id) public returns(bool success){
       require(totalLandsCounter>0);
       for(uint256 i =0; i< totalLandsCounter; i++){
          if(assetStore[i].assetId == _id){
             assetStore[i] = assetStore[totalLandsCounter-1]; // pushing last into current arrray index which we gonna delete
             delete assetStore[totalLandsCounter-1]; // now deleteing last index
             totalLandsCounter--; //total count decrease
             //assetStore.length--; // array length decrease
             //emit event
             emit AssetDelete(_id);
             return true;
          }
      }
      return false;
  }


/*
In order to transfer the asset, we create a function that takes the address of the target wallet along with the asset's id.
We check two pre-conditions:
- the asset actually exists and
- the transaction initiator is actually in possession of the asset.

*/
function transferAsset(address _to, uint _uuid) public returns (bool){
  if(!assetStore[_uuid].initialized) {
        emit RejectTransfer(msg.sender, _to, _uuid, "No asset with this UUID exists");
        return;
  }

  if(!walletStore[msg.sender][_uuid]) {
        emit RejectTransfer(msg.sender, _to, _uuid, "Sender does not own this asset.");
        return;
  }

    //find out the particular land ID in owner's collection
  for(uint i=0; i < (ownedLands[msg.sender].length);i++){
        //if given land ID is indeed in owner's collection
        if (ownedLands[msg.sender][i].assetId == _uuid)
        {
            //copy land in new owner's collection
            Asset memory myAsset = Asset({
                cost: ownedLands[msg.sender][i].cost,
                name:ownedLands[msg.sender][i].name,
                description:ownedLands[msg.sender][i].description,
                initialized: true,
                manufacturer:ownedLands[msg.sender][i].manufacturer,
                ownerAddress:_to,
                assetId: _uuid
            });

            ownedLands[_to].push(myAsset);
            ownedLands[msg.sender][i]=myAsset;   //sovrascrivo?? Metodo migliore quale è?

            delete ownedLands[msg.sender][i];    //remove asset from current ownerAddress


            walletStore[msg.sender][_uuid] = false;
            walletStore[_to][_uuid] = true;

            //inform the world
            emit AssetTransfer(msg.sender, _to, _uuid);

            return true;
        }
    }

    //if we still did not return, return false
    return false;
}


/*
We would also like to have access to the asset properties by just giving the uuid
*/
  function getAssetByUUID(uint _uuid) public view returns (string, string, string, uint,address) {
      return (assetStore[_uuid].name, assetStore[_uuid].description, assetStore[_uuid].manufacturer, assetStore[_uuid].cost,assetStore[_uuid].ownerAddress );
  }

/*
Furthermore, we would like to have a simple way to prove the ownership of an asset
*/
function isOwnerOf(address _owner, uint _uuid) public constant returns (bool) {
    if(walletStore[_owner][_uuid]) {
        return true;
    }
    return false;
}


function getAsset(address _landHolder, uint _index) view  public returns (string, string, uint, string, address, uint){

    return (ownedLands[_landHolder][_index].name,
            ownedLands[_landHolder][_index].description,
            ownedLands[_landHolder][_index].cost,
            ownedLands[_landHolder][_index].manufacturer,
            ownedLands[_landHolder][_index].ownerAddress,
            ownedLands[_landHolder][_index].assetId
          );
}

function getNoOfAssets(address _landHolder) public view returns (uint){
   return ownedLands[_landHolder].length;

}


function getNoOfAssetsTotal() view public returns (uint8){
  //  return ownedLands[_landHolder].length;
   return totalLandsCounter;
}

}
