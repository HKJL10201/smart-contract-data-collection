// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../openzeppelin/contracts/access/Ownable.sol";
//this is a contract
contract IOT is Ownable{

    mapping(string => address) public modelVendors; //vendor of models
    mapping (address  => string) public vendorIP;//IPs of vendors
    mapping (address  => string) public distributerIP;//IPS of distributers
    mapping(address  => uint256) public distributerBalance;//Balance of distributer
    mapping(bytes32 => string) private iotDeviceModel;// model of iot device

    //Firmware data
    struct Firmware{
        string model;
        string version;
        bytes32 hash;
        string[] urls;
        uint256 reward;
        uint256 time;
    }

    //device data
    struct Device{
        string model;
        bytes32 deviveAddress;
        address distributer;
        string version;
        bytes32 hash;
        bool updated;
    }

    mapping(string =>Device[]) modelDevices; //Devices of model
    mapping(string =>Firmware[]) modelFirmware;//Firmware of models

    // main function
    constructor() Ownable(){

    }

    //Only owner of smart contract will call this function to register vendor of the model
    function registerVendor(address vendorAddress, string memory model) onlyOwner public {
        modelVendors[model] = vendorAddress;
    }
    function getBalance()public view returns(uint256){
        return distributerBalance[msg.sender];
    }
    function deviceInfo(address iotAddress) public view returns(Device memory){
        bytes32 iotAddr = ethMessageHash(toAsciiString(iotAddress));
        Device[] memory devices = modelDevices[iotDeviceModel[iotAddr]];
        for(uint256 i =0; i < devices.length;i++){
            if(devices[i].deviveAddress == iotAddr){
                return devices[i];
            }
        }
        return devices[0];

    }
    //this function will return the vendor of the given model
    function getModelVendor(string memory model) public view returns(address){
        return modelVendors[model];
    }

    //Only Vendor will call this function to register Devices of the given model
    function registerDevices(string memory model,bytes32[] memory devicesAddresses, uint256 count) public returns(bool){
        require(msg.sender == modelVendors[model],"sender is not a vendor or not registered as vendor");
        for(uint256 i=0; i < count; i++){
            bytes32 hash = bytes32(0);
            bytes32 devAddr = devicesAddresses[i];
            address zeroAddr = address(0);
            Device memory device = Device(model, devAddr, zeroAddr, "0", hash, true);
            device.model = model;
            modelDevices[model].push(device);
            iotDeviceModel[devAddr] = model;
        }
        // emit event
        return true;
    }

    //this function will return the deveice of the given model
    function getDevices(string memory model)public view returns(Device[] memory) {
        Device[] memory device = modelDevices[model];
        return device;
    }

    function getFirmware(string memory model)public view returns(Firmware[] memory) {
        Firmware[] memory firmware = modelFirmware[model];
        return firmware;
    }

    //Only vendor will call this function to set firmware of the given model
    function updateVendor(string memory model, string memory version, bytes32 hash, string memory ip, uint256 reward, uint256 time) public returns(bool){
        require(msg.sender == modelVendors[model],"sender is not a vendor or not registered as vendor");
        // string[] memory tempurls;
        Firmware memory firmware = Firmware(model, version, hash, new string[](0), reward, time);
        firmware.model = model;
        firmware.version = version;
        firmware.hash = hash;
        firmware.reward = reward;
        firmware.time = time;
        modelFirmware[model].push(firmware);
        vendorIP[msg.sender] = ip;
        for(uint256 i = 0; i < modelDevices[model].length;i++){
            modelDevices[model][i].updated = false;
        }
        // emit Event
        return true;
    }


    function registURL(string memory model, string memory version, string memory ip, bytes memory sign, string memory message) public returns(bool){
        bytes32 hash = ethMessageHash(message);
        address recoveredAddress = recover(hash, sign);
        require(recoveredAddress == modelVendors[model], "invalid Address");
        distributerIP[msg.sender] = ip;
        // Firmware[] memory firmwares = modelFirmware[model];
        for(uint256 i = 0; i<modelFirmware[model].length;i++){
            if(keccak256(abi.encodePacked(modelFirmware[model][i].version)) == keccak256(abi.encodePacked(version))){
                // require(false,"versions matched");
                modelFirmware[model][i].urls.push(ip);
            }
        }
        return true;
    }

    function reportUpdate(string memory model, string memory version, bytes32 iotAddr, uint256 time, bytes memory sign, string memory message)public returns(bool){
        bytes32 hash = ethMessageHash(message);
        address recoveredAddress = recover(hash, sign);
        bytes32 recaddr = ethMessageHash(toAsciiString(recoveredAddress));
        require(recaddr == iotAddr, "invalid Address");
        require(keccak256(abi.encodePacked(iotDeviceModel[iotAddr])) == keccak256(abi.encodePacked(model)),"model not matched");
        for(uint256 i = 0; i < modelDevices[model].length;i++){
            if(modelDevices[model][i].deviveAddress == iotAddr){
                require(!modelDevices[model][i].updated,"Device  is already updated!");
                for(uint256 j = 0;j < modelFirmware[model].length;j++){
                    if(keccak256(abi.encodePacked(modelFirmware[model][i].version)) == keccak256(abi.encodePacked(version))){
                        require(block.timestamp - time <= modelFirmware[model][i].time, "Time excided");
                        distributerBalance[msg.sender] = modelFirmware[model][i].reward/modelDevices[model].length;
                        modelDevices[model][i].distributer = msg.sender;
                        modelDevices[model][i].version = version;
                        modelDevices[model][i].hash = modelFirmware[model][i].hash;
                        modelDevices[model][i].updated = true;
                        return true;
                    }
                }
            }
        }
        return false;

    }
    //this function will verify the signatures provided by distributer
    function verify(bytes memory sig, string memory mess, address ownerAddr) public pure returns (bool) {
        bytes32 message = ethMessageHash(mess);

        // bytes memory sig = hex"344c2206b8fcbbd8e3c08d53a13884a1769054006a3174db92b56e8d59004a835daee16adf367041efd112ded4873706dda8f77cab1a3ab5d3c209c2ea83458400";
        address addr = ownerAddr;

        return recover(message, sig) == addr;
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:" and hash the result
    */
    function ethMessageHash(string memory message) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(message));
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
    function toAsciiString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    function addressToHash(address addr)public pure returns(bytes32){
        // return toAsciiString(addr);
        // return keccak256(abi.encodePacked(addr));
        return ethMessageHash(toAsciiString(addr));
    }




}
