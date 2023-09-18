// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract ServiceMarketplace {
  enum State {
    Purchased,
    Activated,
    Deactivated
  }
  struct Service {
    uint id; // 32
    uint price; // 32
    bytes32 proof; // 32
    address owner; // 20
    State state; // 1
  }

  bool public isStopped = false;

  // mapping of serviceHash to Service data
  mapping(bytes32 => Service) private ownedServices;
  // mapping of serviceID to serviceHash
  mapping(uint => bytes32) private ownedServiceHash;
  // number of all services + id of the service
  uint private totalOwnedServices;
  
  address payable private owner;
  
  constructor() {
    setContractOwner(msg.sender);
  }

  /// Service has invalid state!
  error InvalidState();

  /// Service is not created!
  error ServiceIsNotCreated();

  /// Service has already a Owner!
  error ServiceHasOwner();
  
  /// Sender is not service owner!
  error SenderIsNotServiceOwner();

  /// Only owner has an access!
  error OnlyOwner();

  modifier onlyOwner() {
    if (msg.sender != getContractOwner()) {
      revert OnlyOwner();
    }
    _;
  }

  modifier onlyWhenNotStoped {
    require(!isStopped);
    _;
  }

  modifier onlyWhenStopped {
    require(isStopped);
    _;
  }

  receive() external payable {}

  function withdraw(uint amount) 
    external
    onlyOwner
  {
   (bool success, ) = owner.call{value: amount}("");
   require(success, "Transfer Failed");
  }

  function emergencyWithdraw() 
    external
    onlyWhenStopped
    onlyOwner
  {
   (bool success, ) = owner.call{value: address(this).balance}("");
   require(success, "Transfer Failed");
  }

  function selfDestruct()
    external
    onlyWhenStopped
    onlyOwner
    {
      selfdestruct(owner);
    }

  function stopContract() 
    external 
    onlyOwner 
  {
    isStopped = true;
  }

  function resumeContract() 
    external 
    onlyOwner 
  {
    isStopped = false;
  }

  function purchaseService(
    bytes16 serviceId, // 0x00000000000000000000000000003130
    bytes32 proof // 0x0000000000000000000000000000313000000000000000000000000000003130
  )
    external
    payable
    onlyWhenNotStoped
  {
    bytes32 serviceHash = keccak256(abi.encodePacked(serviceId, msg.sender));
    if (hasServiceOwnership(serviceHash)) {
      revert ServiceHasOwner();
    }
    uint id = totalOwnedServices++;
    ownedServiceHash[id] = serviceHash;
    ownedServices[serviceHash] = Service({
      id: id,
      price: msg.value,
      proof: proof,
      owner: msg.sender,
      state: State.Purchased
    });
  }

  function repurchaseService(bytes32 serviceHash) 
    external
    payable
    onlyWhenNotStoped
  {
    if (!isServiceCreated(serviceHash)) {
      revert ServiceIsNotCreated();
    }
    
    if (!hasServiceOwnership(serviceHash)) {
      revert SenderIsNotServiceOwner();
    }

    Service storage service = ownedServices[serviceHash];

    if (service.state != State.Deactivated) {
      revert InvalidState();
    } 
    
    service.state = State.Purchased;
    service.price = msg.value;
  }

  function activateService(bytes32 serviceHash)
    external
    onlyWhenNotStoped
    onlyOwner
  {

    if (!isServiceCreated(serviceHash)) {
      revert ServiceIsNotCreated();
    }

    Service storage service = ownedServices[serviceHash];

    if (service.state != State.Purchased) {
      revert InvalidState();
    }

    service.state = State.Activated;
  }

  function deactivateService(bytes32 serviceHash)
    external
    onlyWhenNotStoped
    onlyOwner
  {

    if (!isServiceCreated(serviceHash)) {
      revert ServiceIsNotCreated();
    }

    Service storage service = ownedServices[serviceHash];

    if (service.state != State.Purchased) {
      revert InvalidState();
    }

    (bool success, ) = service.owner.call{value: service.price}("");
    require(success, "transfer failed");

    service.state = State.Deactivated;
    service.price = 0;
  }

  function transferOwnership(address newOwner)
    external
    onlyOwner
  {
    setContractOwner(newOwner);
  }

  function getServiceCount()
    external
    view
    returns (uint)
  {
    return totalOwnedServices;
  }
  function getServiceHashAtIndex(uint index)
    external
    view
    returns (bytes32)
  {
    return ownedServiceHash[index];
  }
  function getServiceByHash(bytes32 serviceHash)
    external
    view
    returns (Service memory)
  {
    return ownedServices[serviceHash];
  }

  function getContractOwner()
    public
    view
    returns (address)
  {
    return owner;
  }

  function setContractOwner(address newOwner) private {
    owner = payable(newOwner);
  }

 function isServiceCreated(bytes32 serviceHash)
   private
   view
   returns (bool) 
  {
    return ownedServices[serviceHash].owner != 0x0000000000000000000000000000000000000000;
  }
  
  function hasServiceOwnership(bytes32 serviceHash)
    private
    view
    returns (bool)
  {
    return ownedServices[serviceHash].owner == msg.sender;
  }
}