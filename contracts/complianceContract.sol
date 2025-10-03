// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PharmaTracCore.sol";

contract Emergency {
    enum ResolutionStatus { Open, InProgress, Resolved }
    
    struct EmergencyRecall {
        uint256 batchId;
        address triggeredBy;
        string reason;
        uint256 timestamp;
        ResolutionStatus resolutionStatus;
    }
    
    mapping(uint256 => EmergencyRecall) public emergencyRecalls;
    mapping(uint256 => bool) public hasEmergencyRecall;
    Entity public entityContract;
    
    event RecallInitiated(
        uint256 indexed batchId,
        address indexed triggeredBy,
        string reason,
        ResolutionStatus resolutionStatus
    );
    
    event RecallStatusUpdated(
        uint256 indexed batchId,
        ResolutionStatus newStatus,
        address updatedBy
    );
    
    modifier onlyAuthorizedEntity() {
        Entity.Role role = entityContract.getEntityRole(msg.sender);
        require(
            role == Entity.Role.Regulator || role == Entity.Role.Manufacturer,
            "Emergency: Only regulators or manufacturers can initiate recalls"
        );
        _;
    }
    
    modifier onlyRegulator() {
        require(
            entityContract.getEntityRole(msg.sender) == Entity.Role.Regulator,
            "Emergency: Only regulators can update recall status"
        );
        _;
    }
    
    modifier onlyActiveEntity() {
        (, , bool active, , ) = entityContract.entities(msg.sender);
        require(active, "Emergency: Entity is not active");
        _;
    }
    
    modifier batchHasEmergencyRecall(uint256 batchId) {
        require(hasEmergencyRecall[batchId], "Emergency: No emergency recall exists for this batch");
        _;
    }
    
    constructor(address _entityAddress) {
        entityContract = Entity(_entityAddress);
    }
    
    function initiateRecall(
        uint256 batchId,
        string memory reason
    ) external onlyAuthorizedEntity onlyActiveEntity {
        require(batchId > 0, "Emergency: Invalid batch ID");
        require(!hasEmergencyRecall[batchId], "Emergency: Recall already initiated for this batch");
        
        emergencyRecalls[batchId] = EmergencyRecall({
            batchId: batchId,
            triggeredBy: msg.sender,
            reason: reason,
            timestamp: block.timestamp,
            resolutionStatus: ResolutionStatus.Open
        });
        
        hasEmergencyRecall[batchId] = true;
        
        emit RecallInitiated(
            batchId,
            msg.sender,
            reason,
            ResolutionStatus.Open
        );
    }
    
    function updateRecallStatus(
        uint256 batchId,
        ResolutionStatus newStatus
    ) external onlyRegulator onlyActiveEntity batchHasEmergencyRecall(batchId) {
        emergencyRecalls[batchId].resolutionStatus = newStatus;
        
        emit RecallStatusUpdated(
            batchId,
            newStatus,
            msg.sender
        );
    }
    
    function getEmergencyRecall(uint256 batchId) 
        external 
        view 
        batchHasEmergencyRecall(batchId) 
        returns (EmergencyRecall memory) 
    {
        return emergencyRecalls[batchId];
    }
    
    function getRecallStatus(uint256 batchId) 
        external 
        view 
        batchHasEmergencyRecall(batchId) 
        returns (ResolutionStatus) 
    {
        return emergencyRecalls[batchId].resolutionStatus;
    }
}
