// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title Prescurity, a healt smart contract to create digital medical prescriptions
/// @author Anthony @azerpas, Yann @Xihiems, Martin @MartinLenaerts
/// @notice This contract helps the Doctor, Pharmacist and patient to interact
contract Prescurity {

    /**
     * @notice _owner is the smart contract original deployer
     * He is responsible for adding Doctors and Pharmacists
     */
    address private _owner;

    /**
     * @notice doctor current id inside the blockchain, incremented at each addition
     */
    uint private _doctorId;

    /**
     * @notice pharmacy current id inside the blockchain, incremented at each addition
     */
    uint private _pharmacyId;

    /**
     * @notice prescription current id inside the blockchain, incremented at each addition
     */
    uint private _prescriptionId;

    struct Patient {
        uint numero_secu;
        address patientAddress;
        uint[] prescriptionsIds;
        bool isValue;
    }

    struct Doctor {
        uint id;
        string speciality;
        string name;
        address payable doctorAddress;
        uint[] prescriptionsIds;
        bool isValue;
    }

    struct Pharmacy {
        uint id;
        string name;
        address pharmacyAddress;
        bool isValue;
    }
    
    struct Prescription {
        uint id;
        uint patientId;
        uint doctorId;
        string medicine;
        string disease;
        string frequency;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint dueToDoctor;
        bool claimed;
        bool paid;
    } 

    /// @notice initialize the smart contract by setting the owner to the deployer
    constructor() public {
        _setOwner(msg.sender);
        _setDoctorId(1);
        _setPharmacyId(1);
        _setPrescriptionId(1);
    }

    enum authentification {
        anon,
        patient,
        doctor,
        pharmacy
    }

    mapping (uint => Patient) patientNumSecuMap;
    mapping(address => Patient) patientAddressMap;
    mapping (address => authentification) patientAuthentification;
    mapping (uint => Doctor) doctorIdMap;
    mapping (address => Doctor) doctorAddressMap;
    mapping (address => authentification) doctorAuthentification;
    mapping (uint => Pharmacy) pharmacyIdMap;
    mapping (address => Pharmacy) pharmacyAddressMap;
    mapping (address => authentification) pharmacyAuthentification;
    mapping (uint => Prescription) prescriptionIdMap;

    /**
     * @notice Validator that check if the message sender is a patient
     */
    modifier patientOnly() {
        if (patientAuthentification[msg.sender] == authentification.patient) {
            _;
        } else {
            revert("Sorry, this function is reserved to the patient");
        }
    }

    /**
     * @notice Validator that check if the message sender is a doctor
     */
    modifier doctorOnly() {
        if (doctorAuthentification[msg.sender] == authentification.doctor) {
            _;
        } else {
            revert("Sorry, this function is reserved to the doctor");
        }
    }
    
    /**
     * @notice Validator that check if the message sender is a pharmacy
     */
    modifier pharmacyOnly(){
        if (pharmacyAuthentification[msg.sender] == authentification.pharmacy) {
            _;
        } else {
            revert("Sorry, this function is reserved to the pharmacy");
        }
    }
    
    /**
     * @notice Validator that check if the message sender is a owner
     */
    modifier ownerOnly(){
        if (getOwner() == msg.sender) {
            _;
        } else {
            revert("Sorry, this function is reserved to the owner of the smart contract");
        }
    }

    /**
     * @notice Convert a integer to a string
     * @param _i the integer to convert
     * @return _uintAsString the uint as a string
     */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @notice Concatenate two strings
     * @param a first string
     * @param b second string
     * @return the concatenated string
     */
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /**
     * @notice Get the owner of the smart contract
     * @return owner address
     */
    function getOwner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Get the current doctor id
     * @return id as uint
     */
    function getDoctorId() internal returns (uint) {
        return _doctorId++;
    }

    /**
     * @notice Get the current prescription id
     * @return id as uint
     */
    function getPrescriptionId() internal returns (uint) {
        return _prescriptionId++;
    }

    /**
     * @notice Get the user type of the message sender
     * @return user_type as a string: doctor | pharmacy | patient | owner | none
     */
    function getUserType() view public returns (string memory) {
        if (doctorAuthentification[msg.sender] == authentification.doctor) {
            return "doctor";
        }
        if (pharmacyAuthentification[msg.sender] == authentification.pharmacy) {
            return "pharmacy";
        }
        if (patientAuthentification[msg.sender] == authentification.patient) {
            return "patient";
        }
        if(msg.sender == getOwner()){
            return "owner";
        }
        return "none";
    }

    /**
     * @notice Attribute the status "doctor" to an ethereum (EC20) address
     * @param addr the user ethereum address
     * @param name the user name
     * @param speciality the doctor speciality
     */
    function addDoctor(address payable addr, string calldata name, string calldata speciality) external ownerOnly {
        require(doctorAuthentification[addr] != authentification.doctor, "This address is already defined as a doctor");
        require(pharmacyAuthentification[addr] != authentification.pharmacy, "This address is already defined as a doctor");
        uint id = getDoctorId();
        doctorIdMap[id].id = id;
        doctorIdMap[id].speciality = speciality;
        doctorIdMap[id].name = name;
        doctorIdMap[id].doctorAddress = addr;
        doctorIdMap[id].isValue = true;
        doctorAddressMap[addr].id = id;
        doctorAuthentification[addr] = authentification.doctor;
    }

    /**
     * @notice Attribute the status "pharmacy" to an ethereum (EC20) address
     * @param addr the user ethereum address
     * @param name the user name
     */
    function addPharmacy(address addr, string calldata name) external ownerOnly {
        require(pharmacyAuthentification[addr] != authentification.pharmacy, "This address is already defined as a doctor");
        require(doctorAuthentification[addr] != authentification.doctor, "This address is already defined as a doctor");
        uint id = getDoctorId();
        pharmacyIdMap[id].id = id;
        pharmacyIdMap[id].name = name;
        pharmacyIdMap[id].pharmacyAddress = addr;
        pharmacyIdMap[id].isValue = true;
        pharmacyAddressMap[addr].id = id;
        pharmacyAuthentification[addr] = authentification.pharmacy;
    }

    /**
     * @notice Attribute the status "pharmacy" to an ethereum (EC20) address
     * @param numero_secu the patient "numéro de sécurité sociale"
     * @param addr the user ethereum address
     * @dev problème: une personne mal-intentionée pourrait lier un numéro de sécu ne lui appartenant pas à une addresse quelconque 
     */
    function addPatient(uint numero_secu, address addr) external {
        require(!patientNumSecuMap[numero_secu].isValue, "This num secu is already defined as a patient");
        patientNumSecuMap[numero_secu].numero_secu = numero_secu;
        patientNumSecuMap[numero_secu].isValue = true;
        patientNumSecuMap[numero_secu].patientAddress = addr;
        patientAddressMap[addr].numero_secu = numero_secu;
        patientAuthentification[addr] = authentification.patient;
    }

    /**
     * @notice Add a prescription in the smart contract
     * @param amountAskedByDoctor price set by the doctor for the consultation and eventually the medecine
     * @param numero_secu the patient "numéro de sécurité sociale"
     * @param medicine the medicine prescribed
     * @param disease the disease
     * @param frequency the frequency for the medicine
     * @dev problème: une personne mal-intentionée pourrait lier un numéro de sécu ne lui appartenant pas à une addresse quelconque 
     */
    function addPrescription(uint amountAskedByDoctor, uint numero_secu, string calldata medicine, string calldata disease, string calldata frequency) external doctorOnly {
        //require(msg.value == amountAskedByDoctor, append("Please match the asked value by the doctor: ",uint2str(amountAskedByDoctor)));
        uint doctorId = doctorAddressMap[msg.sender].id;
        // We first fetch the doctor id from the msg.sender then get the doctor object mapped by the ID. 
        Doctor storage doctor = doctorIdMap[doctorId];
        Patient storage patient = patientNumSecuMap[numero_secu];
        uint prescriptionId = getPrescriptionId();
        patient.prescriptionsIds.push(prescriptionId);
        doctor.prescriptionsIds.push(prescriptionId);
        prescriptionIdMap[prescriptionId].id = prescriptionId;
        prescriptionIdMap[prescriptionId].claimed = false;
        prescriptionIdMap[prescriptionId].paid = false;
        prescriptionIdMap[prescriptionId].patientId = numero_secu;
        prescriptionIdMap[prescriptionId].doctorId = doctor.id;
        prescriptionIdMap[prescriptionId].medicine = medicine;
        prescriptionIdMap[prescriptionId].frequency = frequency;
        prescriptionIdMap[prescriptionId].disease = disease;
        prescriptionIdMap[prescriptionId].dueToDoctor = amountAskedByDoctor;
        prescriptionIdMap[prescriptionId].startTimestamp = block.timestamp;
        prescriptionIdMap[prescriptionId].endTimestamp = block.timestamp + 93 days;
        emit Consultation(prescriptionIdMap[prescriptionId], patient, doctor, amountAskedByDoctor);
    }

    /**
     * @notice Pay the prescription as a patient
     * @param prescriptionId the prescription id
     */
    function payPrescription(uint prescriptionId) payable external patientOnly {
        require(address(this).balance >= msg.value, "Balance is not enough");
        require(!prescriptionIdMap[prescriptionId].paid, "Prescription should not be paid");
        Prescription storage prescription = prescriptionIdMap[prescriptionId];
        Doctor storage doctor = doctorIdMap[prescription.doctorId];
        address payable doctorAddr = doctor.doctorAddress;
        doctorAddr.transfer(msg.value);
        emit DoctorPaid(msg.value, doctor.doctorAddress, msg.sender, prescription.doctorId);
        prescriptionIdMap[prescriptionId].paid = true;
    }

    /**
     * @notice Claim the prescription as a Pharmacy before delivering the medicine
     * @param prescriptionId the prescription id
     */
    function claimPrescription(uint prescriptionId) external pharmacyOnly {
        require(prescriptionIdMap[prescriptionId].claimed == false, "This presciption is already claimed");
        Prescription storage prescription = prescriptionIdMap[prescriptionId];
        Patient storage patient = patientNumSecuMap[prescription.patientId];
        prescriptionIdMap[prescriptionId].claimed = true;
        emit PharmaClaimed(prescription, msg.sender, patient);
    }

    /**
     * @notice Get the latest prescriptions of a patient
     * @param numSecuPatient the patient "numéro de sécurité sociale"
     * @return A list of Prescription objects
     * @dev We need to restrict this function to specific actors
     */
    function showPrescriptionPatient(uint numSecuPatient) view public returns(Prescription[] memory){
        require(numSecuPatient > 100000000000000 && numSecuPatient < 999999999999999, "Numero de securite require 15 numbers");

        Patient storage patient = patientNumSecuMap[numSecuPatient];
        uint len=5;
        
        if(patient.prescriptionsIds.length < len){
            len = patient.prescriptionsIds.length;
        }
        Prescription[] memory prescriptions = new Prescription[](len);
        for(uint i=0; i < len; i++){

            Prescription storage prescription = prescriptionIdMap[patient.prescriptionsIds[len-1-i]];
            prescriptions[i] = prescription;
        }
        return prescriptions;
    }

    /**
     * @notice Fetch the last "amountOfPrescriptions" a doctor has created.
     * @param amountOfPrescriptions the amount of prescriptions to get
     * @return A list of Prescription objects
     */
    function getLastDoctorPrescriptions(uint amountOfPrescriptions) view public doctorOnly returns(Prescription[] memory){
        require(amountOfPrescriptions > 0 && amountOfPrescriptions < 25, "Please input an amount of prescriptions between 0 and 25");
        uint doctorId = doctorAddressMap[msg.sender].id;
        Doctor storage doctor = doctorIdMap[doctorId];

        uint len = amountOfPrescriptions;
        if(doctor.prescriptionsIds.length < len){
            len = doctor.prescriptionsIds.length;
        }
        Prescription[] memory prescriptions = new Prescription[](len);
        for(uint i=0; i < len; i++){

            Prescription storage prescription = prescriptionIdMap[doctor.prescriptionsIds[len-1-i]];
            prescriptions[i] = prescription;
        }
        return prescriptions;
    }

    /**
     * @notice Get a specific Prescription object
     * @param idprescription the prescription id
     * @return A Prescription object
     */
    function getPrescription(uint idprescription) view public doctorOnly returns(Prescription memory) {
        return prescriptionIdMap[idprescription];
    }

    /**
     * @notice Set a new owner
     * @param new_owner the new owner address
     */
    function _setOwner(address new_owner) private {
        address old_owner = _owner;
        _owner = new_owner;
        emit DefineOwnership(old_owner, new_owner);
    }

    /**
     * @notice Get a doctor
     * @param iddoctor the doctor id
     * @return Doctor object
     */
    function getDoctor(uint iddoctor) view public returns(Doctor memory) {
        Doctor storage doctor= doctorIdMap[iddoctor];
        return doctor;
    }

    /**
     * @notice Get a patient
     * @param numPatient the patient "numéro de sécurité sociale"
     * @return Doctor object
     */
    function getPatient(uint numPatient) view public returns(Patient memory) {
        Patient storage patient = patientNumSecuMap[numPatient];
        return patient;
    }

    /**
     * @dev deprecated
     */
    function getPatientAddress(address patientaddress) view public returns(Patient memory) {
        Patient storage patient = patientAddressMap[patientaddress];
        return patient;
    }

    /**
     * @notice Set a new doctor id
     * @param index the index
     */
    function _setDoctorId(uint index) private {
        _doctorId = index;
    }

    /**
     * @notice Set a new pharmacy id
     * @param index the index
     */
    function _setPharmacyId(uint index) private {
        _pharmacyId = index;
    }

    /**
     * @notice Set a new prescription id
     * @param index the index
     */
    function _setPrescriptionId(uint index) private {
        _prescriptionId = index;
    }
    
    /**
     * @notice Events are triggered to return values in the front-end and logging purposes
     */
    event prescriptionsShow(Prescription[] prescription);
    event PharmaClaimed(Prescription prescription,address indexed pharmaaddress,Patient patient);
    event DefineOwnership(address indexed old_owner, address indexed new_owner);
    event Consultation(Prescription prescription, Patient patient, Doctor doctor, uint amount);
    event DoctorPaid(uint amount, address indexed doctorAddress, address indexed patientAddress, uint doctorId);
    event RetrieveMedicaments(Patient patient, Pharmacy pharmacy, Prescription prescription);
}