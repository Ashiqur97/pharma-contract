// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Entity.sol";

contract DrugBatch {
    enum BatchStatus { Active, Recalled, Expired, Quarantined }
    
    struct Batch {
        string productCode;
        address manufacturer;
        uint256 manufactureDate;
        uint256 expiryDate;
        string metadataURI;
        BatchStatus status;
    }
    
    mapping(uint256 => Batch) public batches;
    uint256 public batchCounter;
    Entity public entityContract;
    
    event BatchCreated(
        uint256 indexed batchId,
        string productCode,
        address indexed manufacturer,
        uint256 manufactureDate,
        uint256 expiryDate
    );
    
    event BatchStatusChanged(
        uint256 indexed batchId,
        BatchStatus newStatus,
        address updatedBy
    );
    
    modifier onlyManufacturer() {
        require(
            entityContract.getEntityRole(msg.sender) == Entity.Role.Manufacturer,
            "Only manufacturers can create batches"
        );
        _;
    }
    
    modifier onlyRegulator() {
        require(
            entityContract.getEntityRole(msg.sender) == Entity.Role.Regulator,
            "Only regulators can update batch status"
        );
        _;
    }
    
    modifier onlyActiveEntity() {
        // Fix: Destructure the tuple to access the active status
        (, , bool active, , ) = entityContract.entities(msg.sender);
        require(active, "Entity is not active");
        _;
    }
    
    constructor(address _entityAddress) {
        entityContract = Entity(_entityAddress);
    }
    
    function createBatch(
        string memory productCode,
        uint256 manufactureDate,
        uint256 expiryDate,
        string memory metadataURI
    ) external onlyManufacturer onlyActiveEntity {
        require(manufactureDate < expiryDate, "Invalid dates");
        require(manufactureDate <= block.timestamp, "Future manufacture date");
        
        batchCounter++;
        batches[batchCounter] = Batch({
            productCode: productCode,
            manufacturer: msg.sender,
            manufactureDate: manufactureDate,
            expiryDate: expiryDate,
            metadataURI: metadataURI,
            status: BatchStatus.Active
        });
        
        emit BatchCreated(
            batchCounter,
            productCode,
            msg.sender,
            manufactureDate,
            expiryDate
        );
    }
    
    function updateBatchStatus(
        uint256 batchId,
        BatchStatus newStatus
    ) external onlyRegulator onlyActiveEntity {
        require(batchId > 0 && batchId <= batchCounter, "Invalid batch ID");
        
        batches[batchId].status = newStatus;
        emit BatchStatusChanged(batchId, newStatus, msg.sender);
    }
    
    function getBatchStatus(uint256 batchId) external view returns (BatchStatus) {
        require(batchId > 0 && batchId <= batchCounter, "Invalid batch ID");
        return batches[batchId].status;
    }
    
    function isBatchExpired(uint256 batchId) external view returns (bool) {
        require(batchId > 0 && batchId <= batchCounter, "Invalid batch ID");
        return block.timestamp > batches[batchId].expiryDate;
    }
}
