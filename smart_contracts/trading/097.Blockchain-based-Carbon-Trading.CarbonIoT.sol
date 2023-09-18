pragma solidity >=0.4.0 <0.6.0;
 


 contract   CarbonIoT  {
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
        
        



 event registerevent( address _IoTaddress, bytes32 _IoTname, bytes32 _IoTdescription);
     function Register( address _IoTaddress, bytes32 _IoTname, bytes32 _IoTdescription) public  returns(address IoTaddress, bytes32 IoTname, bytes32 IoTdescription)   {

  IoTaddress =  _IoTaddress; 
  IoTname =_IoTname;
  IoTdescription = _IoTdescription;

         emit registerevent( IoTaddress,  IoTname,  IoTdescription);

       return (  IoTaddress,  IoTname,  IoTdescription);
         
         
     }


   

event SubmitEmissionsEvent (address _buyeraddress, address _iotdeviceaddress ,  uint _carbonemmissions, bytes32 _date);
   function SubmitEmissions(address _buyeraddress, address _iotdeviceaddress ,  uint _carbonemmissions, bytes32 _date ) public returns(address buyeraddresshere, address iotdeviceaddresshere ,  uint carbonemmissionshere, bytes32 datehere)   {
        
        
        buyeraddresshere  = _buyeraddress; 
        iotdeviceaddresshere= _iotdeviceaddress ; 
        carbonemmissionshere =_carbonemmissions ;
         datehere =_date ;
        
        
        emit SubmitEmissionsEvent( buyeraddresshere,  iotdeviceaddresshere ,  carbonemmissionshere,datehere);
         return (buyeraddresshere, iotdeviceaddresshere ,   carbonemmissionshere, datehere);
         
          
     }
     
     

}
