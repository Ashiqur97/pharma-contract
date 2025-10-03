// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Entity.sol";

contract Compliance {
    enum ComplianceStatus { Approved, Pending, Rejected }
    
    struct ComplianceRecord {
        uint256 batchId;
        address auditor;
        string reportURI;
        uint256 timestamp;
        ComplianceStatus status;
    }
    
    mapping(uint256 => ComplianceRecord) public complianceRecords;
    mapping(uint256 => bool) public hasComplianceRecord;
    Entity public entityContract;
    
    event ComplianceRecorded(
        uint256 indexed batchId,
        address indexed auditor,
        string reportURI,
        ComplianceStatus status
    );
    
    event ComplianceStatusUpdated(
        uint256 indexed batchId,
        ComplianceStatus newStatus,
        address updatedBy
    );
    
    modifier onlyRegulator() {
        require(
            entityContract.getEntityRole(msg.sender) == Entity.Role.Regulator,
            "Compliance: Only regulators can manage compliance records"
        );
        _;
    }
    
    modifier onlyActiveEntity() {
        (, , bool active, , ) = entityContract.entities(msg.sender);
        require(active, "Compliance: Entity is not active");
        _;
    }
    
    modifier batchHasComplianceRecord(uint256 batchId) {
        require(hasComplianceRecord[batchId], "Compliance: No compliance record exists for this batch");
        _;
    }
    
    constructor(address _entityAddress) {
        entityContract = Entity(_entityAddress);
    }
    
    function recordCompliance(
        uint256 batchId,
        string memory reportURI,
        ComplianceStatus status
    ) external onlyRegulator onlyActiveEntity {
        require(batchId > 0, "Compliance: Invalid batch ID");
        
        complianceRecords[batchId] = ComplianceRecord({
            batchId: batchId,
            auditor: msg.sender,
            reportURI: reportURI,
            timestamp: block.timestamp,
            status: status
        });
        
        hasComplianceRecord[batchId] = true;
        
        emit ComplianceRecorded(
            batchId,
            msg.sender,
            reportURI,
            status
        );
    }
    
    function updateComplianceStatus(
        uint256 batchId,
        ComplianceStatus newStatus
    ) external onlyRegulator onlyActiveEntity batchHasComplianceRecord(batchId) {
        complianceRecords[batchId].status = newStatus;
        complianceRecords[batchId].timestamp = block.timestamp;
        
        emit ComplianceStatusUpdated(
            batchId,
            newStatus,
            msg.sender
        );
    }
    
    function getComplianceRecord(uint256 batchId) 
        external 
        view 
        batchHasComplianceRecord(batchId) 
        returns (ComplianceRecord memory) 
    {
        return complianceRecords[batchId];
    }
    
    function getComplianceStatus(uint256 batchId) 
        external 
        view 
        batchHasComplianceRecord(batchId) 
        returns (ComplianceStatus) 
    {
        return complianceRecords[batchId].status;
    }
}
