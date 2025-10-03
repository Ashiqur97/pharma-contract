// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./PharmaTracCore.sol";

/**
 * @title Emergency
 * @dev Contract for handling emergency situations like recalls in the pharmaceutical supply chain
 */
contract Emergency is Ownable {
    PharmaTracCore private core;
    
    enum RecallStatus {
        ACTIVE,
        RESOLVED,
        CANCELLED
    }
    
    struct EmergencyRecall {
        uint256 recallId;
        string batchId;
        address triggeredBy;
        string reason;
        uint256 timestamp;
        RecallStatus status;
        string resolutionDetails;
    }
    
    mapping(uint256 => EmergencyRecall) public recalls;
    mapping(string => uint256[]) public batchRecalls;
    mapping(string => bool) public quarantinedBatches;
    
    uint256 private recallCounter;
    
    event BatchFlagged(
        uint256 indexed recallId,
        string indexed batchId,
        address indexed triggeredBy,
        string reason,
        uint256 timestamp
    );
    
    event RecallStatusChanged(
        uint256 indexed recallId,
        RecallStatus status,
        string details
    );
    
    event BatchQuarantined(
        string indexed batchId,
        address indexed triggeredBy,
        string reason
    );
    
    event BatchReleased(
        string indexed batchId,
        address indexed triggeredBy,
        string reason
    );
    
    constructor(address _coreAddress) Ownable(msg.sender) {
        core = PharmaTracCore(_coreAddress);
        recallCounter = 0;
    }
    
    /**
     * @dev Modifier to check if sender is a regulator or manufacturer
     */
    modifier onlyRegulatorOrManufacturer() {
        require(
            core.entities(msg.sender).role == PharmaTracCore.UserRole.REGULATOR ||
            core.entities(msg.sender).role == PharmaTracCore.UserRole.MANUFACTURER,
            "Emergency: Only regulators or manufacturers can perform this action"
        );
        require(core.entities(msg.sender).isActive, "Emergency: Entity not active");
        _;
    }
    
    /**
     * @dev Modifier to check if sender is a regulator
     */
    modifier onlyRegulator() {
        require(
            core.entities(msg.sender).role == PharmaTracCore.UserRole.REGULATOR,
            "Emergency: Only regulators can perform this action"
        );
        require(core.entities(msg.sender).isActive, "Emergency: Entity not active");
        _;
    }
    
    /**
     * @dev Initiate a recall for a drug batch
     * @param _batchId ID of the drug batch to recall
     * @param _reason Reason for the recall
     * @return recallId The ID of the created recall
     */
    function initiateRecall(
        string memory _batchId,
        string memory _reason
    ) external onlyRegulatorOrManufacturer returns (uint256) {
        require(bytes(_batchId).length > 0, "Emergency: Invalid batch ID");
        require(bytes(_reason).length > 0, "Emergency: Reason must be provided");
        
        // Increment recall counter
        recallCounter++;
        
        // Create recall record
        recalls[recallCounter] = EmergencyRecall({
            recallId: recallCounter,
            batchId: _batchId,
            triggeredBy: msg.sender,
            reason: _reason,
            timestamp: block.timestamp,
            status: RecallStatus.ACTIVE,
            resolutionDetails: ""
        });
        
        // Add to batch recall history
        batchRecalls[_batchId].push(recallCounter);
        
        // Automatically quarantine the batch
        quarantinedBatches[_batchId] = true;
        
        // Emit events
        emit BatchFlagged(
            recallCounter,
            _batchId,
            msg.sender,
            _reason,
            block.timestamp
        );
        
        emit BatchQuarantined(
            _batchId,
            msg.sender,
            _reason
        );
        
        return recallCounter;
    }
    
    /**
     * @dev Update the status of a recall
     * @param _recallId ID of the recall
     * @param _status New status
     * @param _details Details about the status change
     */
    function updateRecallStatus(
        uint256 _recallId,
        RecallStatus _status,
        string memory _details
    ) external onlyRegulator {
        require(recalls[_recallId].recallId != 0, "Emergency: Recall does not exist");
        require(recalls[_recallId].status != _status, "Emergency: Status already set");
        
        EmergencyRecall storage recall = recalls[_recallId];
        recall.status = _status;
        recall.resolutionDetails = _details;
        
        // If resolved or cancelled, release the batch from quarantine
        if (_status == RecallStatus.RESOLVED || _status == RecallStatus.CANCELLED) {
            quarantinedBatches[recall.batchId] = false;
            
            emit BatchReleased(
                recall.batchId,
                msg.sender,
                _details
            );
        }
        
        emit RecallStatusChanged(_recallId, _status, _details);
    }
    
    /**
     * @dev Quarantine a batch without initiating a full recall
     * @param _batchId ID of the drug batch to quarantine
     * @param _reason Reason for quarantine
     */
    function quarantineBatch(
        string memory _batchId,
        string memory _reason
    ) external onlyRegulator {
        require(bytes(_batchId).length > 0, "Emergency: Invalid batch ID");
        require(!quarantinedBatches[_batchId], "Emergency: Batch already quarantined");
        
        quarantinedBatches[_batchId] = true;
        
        emit BatchQuarantined(_batchId, msg.sender, _reason);
    }
    
    /**
     * @dev Release a batch from quarantine
     * @param _batchId ID of the drug batch to release
     * @param _reason Reason for release
     */
    function releaseBatch(
        string memory _batchId,
        string memory _reason
    ) external onlyRegulator {
        require(bytes(_batchId).length > 0, "Emergency: Invalid batch ID");
        require(quarantinedBatches[_batchId], "Emergency: Batch not quarantined");
        
        quarantinedBatches[_batchId] = false;
        
        emit BatchReleased(_batchId, msg.sender, _reason);
    }
    
    /**
     * @dev Check if a batch is under recall or quarantine
     * @param _batchId ID of the drug batch
     * @return bool True if the batch is under recall or quarantine
     */
    function isBatchFlagged(string memory _batchId) external view returns (bool) {
        // Check if batch is quarantined
        if (quarantinedBatches[_batchId]) {
            return true;
        }
        
        // Check if batch has any active recalls
        uint256[] memory recallIds = batchRecalls[_batchId];
        for (uint256 i = 0; i < recallIds.length; i++) {
            if (recalls[recallIds[i]].status == RecallStatus.ACTIVE) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * @dev Get all recall IDs for a specific batch
     * @param _batchId ID of the drug batch
     * @return uint256[] Array of recall IDs
     */
    function getBatchRecallHistory(string memory _batchId) external view returns (uint256[] memory) {
        return batchRecalls[_batchId];
    }
    
    /**
     * @dev Get recall details
     * @param _recallId ID of the recall
     * @return EmergencyRecall details
     */
    function getRecall(uint256 _recallId) external view returns (EmergencyRecall memory) {
        return recalls[_recallId];
    }
}
