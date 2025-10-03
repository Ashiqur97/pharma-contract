// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./PharmaTracCore.sol";

/**
 * @title DrugSupplyChain
 * @dev Contract for tracking drug transfers across the pharmaceutical supply chain
 */
contract DrugSupplyChain is Ownable {
    PharmaTracCore private core;
    
    struct TransferEvent {
        uint256 transferId;
        string batchId;
        address from;
        address to;
        uint256 timestamp;
        string location;
        string signature;
        bool isValid;
    }
    
    mapping(uint256 => TransferEvent) public transfers;
    mapping(string => uint256[]) public batchTransfers;
    
    uint256 private transferCounter;
    
    event TransferRecorded(
        uint256 indexed transferId,
        string indexed batchId,
        address indexed from,
        address to,
        uint256 timestamp,
        string location
    );
    
    event TransferInvalidated(
        uint256 indexed transferId,
        string reason
    );
    
    constructor(address _coreAddress) Ownable(msg.sender) {
        core = PharmaTracCore(_coreAddress);
        transferCounter = 0;
    }
    
    /**
     * @dev Modifier to check if sender has a valid role for transfers
     */
    modifier validTransferRole() {
        require(
            core.entities(msg.sender).role == PharmaTracCore.UserRole.MANUFACTURER ||
            core.entities(msg.sender).role == PharmaTracCore.UserRole.DISTRIBUTOR ||
            core.entities(msg.sender).role == PharmaTracCore.UserRole.PHARMACY,
            "SupplyChain: Unauthorized role for transfer"
        );
        require(core.entities(msg.sender).isActive, "SupplyChain: Entity not active");
        _;
    }
    
    /**
     * @dev Record a transfer of drug batch from one entity to another
     * @param _batchId ID of the drug batch
     * @param _to Recipient address
     * @param _location Optional location information
     * @param _signature Optional off-chain signature
     * @return transferId The ID of the recorded transfer
     */
    function recordTransfer(
        string memory _batchId,
        address _to,
        string memory _location,
        string memory _signature
    ) external validTransferRole returns (uint256) {
        require(_to != address(0), "SupplyChain: Invalid recipient address");
        require(bytes(_batchId).length > 0, "SupplyChain: Invalid batch ID");
        
        // Check if recipient is an active entity
        require(core.entities(_to).isActive, "SupplyChain: Recipient is not active");
        
        // Increment transfer counter
        transferCounter++;
        
        // Create transfer record
        transfers[transferCounter] = TransferEvent({
            transferId: transferCounter,
            batchId: _batchId,
            from: msg.sender,
            to: _to,
            timestamp: block.timestamp,
            location: _location,
            signature: _signature,
            isValid: true
        });
        
        // Add to batch transfer history
        batchTransfers[_batchId].push(transferCounter);
        
        // Emit transfer event
        emit TransferRecorded(
            transferCounter,
            _batchId,
            msg.sender,
            _to,
            block.timestamp,
            _location
        );
        
        return transferCounter;
    }
    
    /**
     * @dev Invalidate a transfer (can only be done by regulators or admin)
     * @param _transferId ID of the transfer to invalidate
     * @param _reason Reason for invalidation
     */
    function invalidateTransfer(
        uint256 _transferId,
        string memory _reason
    ) external {
        require(
            core.entities(msg.sender).role == PharmaTracCore.UserRole.REGULATOR ||
            core.entities(msg.sender).role == PharmaTracCore.UserRole.ADMIN,
            "SupplyChain: Only regulators or admin can invalidate transfers"
        );
        require(core.entities(msg.sender).isActive, "SupplyChain: Entity not active");
        
        require(transfers[_transferId].isValid, "SupplyChain: Transfer already invalidated or doesn't exist");
        
        transfers[_transferId].isValid = false;
        
        emit TransferInvalidated(_transferId, _reason);
    }
    
    /**
     * @dev Get transfer details
     * @param _transferId ID of the transfer
     * @return TransferEvent details
     */
    function getTransfer(uint256 _transferId) external view returns (TransferEvent memory) {
        return transfers[_transferId];
    }
    
    /**
     * @dev Get all transfer IDs for a specific batch
     * @param _batchId ID of the drug batch
     * @return uint256[] Array of transfer IDs
     */
    function getBatchTransferHistory(string memory _batchId) external view returns (uint256[] memory) {
        return batchTransfers[_batchId];
    }
    
    /**
     * @dev Get the current custodian of a batch based on the last valid transfer
     * @param _batchId ID of the drug batch
     * @return address Current custodian address
     */
    function getCurrentCustodian(string memory _batchId) external view returns (address) {
        uint256[] memory history = batchTransfers[_batchId];
        
        if (history.length == 0) {
            return address(0); // No transfers recorded
        }
        
        // Find the last valid transfer
        for (uint256 i = history.length; i > 0; i--) {
            uint256 transferId = history[i - 1];
            if (transfers[transferId].isValid) {
                return transfers[transferId].to;
            }
        }
        
        return address(0); // No valid transfers found
    }
    
    /**
     * @dev Verify if an entity is in the custody chain of a batch
     * @param _batchId ID of the drug batch
     * @param _entity Address of the entity to check
     * @return bool True if the entity is in the custody chain
     */
    function isInCustodyChain(string memory _batchId, address _entity) external view returns (bool) {
        uint256[] memory history = batchTransfers[_batchId];
        
        for (uint256 i = 0; i < history.length; i++) {
            TransferEvent memory transfer = transfers[history[i]];
            if (transfer.isValid && (transfer.from == _entity || transfer.to == _entity)) {
                return true;
            }
        }
        
        return false;
    }
}
