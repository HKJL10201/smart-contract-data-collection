//a basic asset tracking functionality in the blockchain.
//from: https://dzone.com/articles/implementing-a-simple-smart-contract-for-asset-tra

pragma solidity ^0.4.24;

contract AssetTracker {


/*
For different real-world events in the supply chain, such as asset creation or asset transfer, we define counterparts in the smart contract.

*/
  event AssetCreate(address account, string uuid, string manufacturer);
  event RejectCreate(address account, string uuid, string message);
  event AssetTransfer(address from, address to, string uuid);
  event RejectTransfer(address from, address to, string uuid, string message);

struct Asset {
    string name;
    string description;
    string manufacturer;
    bool initialized;
}

mapping(string  => Asset) private assetStore;
//assetStore[uuid] = Asset(name, description, true, manufacturer);
mapping(address => mapping(string => bool)) private walletStore;



/*
The first function that we would need is the create an asset function.
It takes all the information needed to specify the asset and checks if the asset already exists.
In this case, we trigger a formerly declared event – RejectCreate().
If we have a new asset at hand, we store the data in the asset store and create the relation
between the message sender's wallet and the asset's uuid

*/


function createAsset(string name, string description, string uuid, string manufacturer) {
    if(assetStore[uuid].initialized) {
        RejectCreate(msg.sender, uuid, "Asset with this UUID already exists.");
        return;
      }
      assetStore[uuid] = Asset(name, description, true, manufacturer);
      walletStore[msg.sender][uuid] = true;    //This is used later on to make the assignment of an asset to a wallet
      AssetCreate(msg.sender, uuid, manufacturer);
}



/*
In order to transfer the asset, we create a function that takes the address of the target wallet along with the asset's id.
We check two pre-conditions:
- the asset actually exists and
- the transaction initiator is actually in possession of the asset.

*/
function transferAsset(address to, string uuid) {
    if(!assetStore[uuid].initialized) {
        RejectTransfer(msg.sender, to, uuid, "No asset with this UUID exists");
        return;
    }
    if(!walletStore[msg.sender][uuid]) {
        RejectTransfer(msg.sender, to, uuid, "Sender does not own this asset.");
        return;
    }
    walletStore[msg.sender][uuid] = false;
    walletStore[to][uuid] = true;
    AssetTransfer(msg.sender, to, uuid);
}


/*
We would also like to have access to the asset properties by just giving the uuid
*/
  function getAssetByUUID(string uuid) constant returns (string, string, string) {
      return (assetStore[uuid].name, assetStore[uuid].description, assetStore[uuid].manufacturer);
  }

/*
Furthermore, we would like to have a simple way to prove the ownership of an asset
*/


  function isOwnerOf(address owner, string uuid) constant returns (bool) {
    if(walletStore[owner][uuid]) {
        return true;
    }
    return false;
}



}
