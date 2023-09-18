pragma solidity >=0.4.0 <0.6.0;
 


 contract   Environmental  {
          uint  i=0; 
      

      // PEOPLES 
       struct Buyer {
       address payable buyeraddress;
       bytes32  buyername;
        bytes32    buyingcompanydescription;
        bytes32 buyingcompanytype;
        bool status;
        uint buyingcompanycount;
       uint emissionproduced;
       uint amountpaidsofar;
       uint theentitiescount;
       
      mapping (address => Buyer[1000]) listofbuyers;
      mapping (bytes32 => Buyer[1000]) setofbuyers;

       }
       
        Buyer[] public thebuyingcompanystore; 
        Buyer buyingcompanyobject;
       
        
           //BIDS
        struct Seller {
       bytes32 sellername ;
       address payable selleraddress;
       bytes32 sellercompanytype;
       bytes32 description;
        uint sellingcapacity;
        uint sellingcapacityleft;
        bool status;
        uint sellingrate;
        uint capacitysupplied;
        uint amounttobepaid;
        uint amountpaid;
        uint sellingmomentcount;
        
    
      mapping (address => Seller[1000]) listofsellers;
      mapping (bytes32 => Seller[1000]) setofsellers;

       }
       
        Seller[] public sellerstore; 
        Seller sellersobject;

               struct EA {
       address  payable EAaddress;
       bytes32  EAname;
       bytes32  EAdescription;
      
       bool status;
       bytes32 carbonemmisionthreshold;
       bytes32 emissionrate;
       bytes32 role;
       bytes32 threshholdetdate;
       uint EAmomentcount;
        
    
    
      mapping (bytes32 => EA[1000]) setofEAs;
       mapping (address => EA[1000]) listofEAs;
       }
       
        EA[] public EAstore; 
        EA EAObject;
        
        
               struct IoT {
       address  IoTDeviceAddress;
       bytes32  IoTDeviceName;
       bytes32  IoTDeviceDescription;
       uint       emissionproduced;
       bytes32       date;

      
        
    
      mapping (address => IoT[1000]) setofIoTs;
      mapping (bytes32 => IoT[1000]) listofIoTs;

       }
       
        IoT[] public IoTStore; 
        IoT IoTObjects;
        
        




     function Register(address  _registrar,  address _companyaddress, bytes32 _companyname,bytes32 _companytype, bool _companystatus, bytes32 _description) public  returns(address  _registrarhere,  address _companyaddresshere, bytes32 _companynamehere,bytes32 _companytypehere, bool _companystatushere, bytes32 _descriptionhere)   {

 _registrarhere =_registrar; 
_companyaddresshere =_companyaddress; 
_companynamehere = _companyname;
 _companytypehere = _companytype;
 _companystatushere =_companystatus;
 _descriptionhere = _description;


       return (   _registrarhere,   _companyaddresshere,  _companynamehere, _companytypehere,  _companystatushere,  _descriptionhere);
         
         
     }


   

event EArequired (address _registrar, address _companyaddress, uint _emmissionthreshold,  bool status);
   function setRequirements(address _registrar, address _companyaddress, uint _emmissionthreshold,  bool _status ) public returns(address _registrarhere, address _companyaddresshere, uint _emmissionthresholdhere,  bool statushere)   {
        
     _registrarhere = _registrar;
         _companyaddresshere =_companyaddress; 
        _emmissionthresholdhere =_emmissionthreshold; 
         statushere = _status;
        
        emit EArequired(_registrarhere, _companyaddresshere,  _emmissionthresholdhere, statushere);
         return (  _registrarhere, _companyaddresshere,  _emmissionthresholdhere, statushere);
         
          
     }


}
