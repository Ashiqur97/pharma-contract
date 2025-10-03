// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RoleBasedAccessControl
 * @dev Contract for managing role-based access control in the pharmaceutical supply chain
 */
contract RoleBasedAccessControl is Ownable {
    enum UserRole {
        MANUFACTURER,
        DISTRIBUTOR,
        PHARMACY,
        REGULATOR,
        ADMIN
    }

    struct Entity {
        address entityAddress;
        string name;
        UserRole role;
        bool isActive;
        uint256 registeredAt;
        string metadataURI; // Optional URI for KYC or license documents
    }

    mapping(address => Entity) public entities;
    mapping(UserRole => mapping(address => bool)) private roleAssignments;
    
    event EntityRegistered(
        address indexed entityAddress,
        string name,
        UserRole role
    );
    event EntityUpdated(
        address indexed entityAddress,
        string name,
        UserRole role
    );
    event EntityDeactivated(address indexed entityAddress);
    event RoleAssigned(address indexed entityAddress, UserRole role);
    event RoleRevoked(address indexed entityAddress, UserRole role);

    constructor() Ownable(msg.sender) {
        // Register the contract deployer as ADMIN
        _registerEntity(msg.sender, "System Admin", UserRole.ADMIN, "");
    }

    /**
     * @dev Modifier to check if an entity is active
     */
    modifier onlyActive() {
        require(
            entities[msg.sender].isActive,
            "RBAC: Entity is not active"
        );
        _;
    }

    /**
     * @dev Modifier to check if an entity has a specific role
     */
    modifier onlyRole(UserRole _role) {
        require(
            entities[msg.sender].role == _role,
            "RBAC: Unauthorized role"
        );
        _;
    }

    /**
     * @dev Register a new entity with a role
     * @param _entityAddress Address of the entity
     * @param _name Name of the entity
     * @param _role Role of the entity
     * @param _metadataURI Optional URI for additional entity information
     */
    function registerEntity(
        address _entityAddress,
        string memory _name,
        UserRole _role,
        string memory _metadataURI
    ) external onlyOwner {
        _registerEntity(_entityAddress, _name, _role, _metadataURI);
    }

    /**
     * @dev Internal function to register an entity
     */
    function _registerEntity(
        address _entityAddress,
        string memory _name,
        UserRole _role,
        string memory _metadataURI
    ) internal {
        require(
            _entityAddress != address(0),
            "RBAC: Invalid address"
        );
        require(
            !entities[_entityAddress].isActive,
            "RBAC: Entity already registered"
        );

        entities[_entityAddress] = Entity({
            entityAddress: _entityAddress,
            name: _name,
            role: _role,
            isActive: true,
            registeredAt: block.timestamp,
            metadataURI: _metadataURI
        });

        roleAssignments[_role][_entityAddress] = true;

        emit EntityRegistered(_entityAddress, _name, _role);
        emit RoleAssigned(_entityAddress, _role);
    }

    /**
     * @dev Update an existing entity's information
     * @param _entityAddress Address of the entity to update
     * @param _name New name for the entity
     * @param _metadataURI New metadata URI
     */
    function updateEntity(
        address _entityAddress,
        string memory _name,
        string memory _metadataURI
    ) external onlyOwner {
        require(
            entities[_entityAddress].isActive,
            "RBAC: Entity not registered or inactive"
        );

        Entity storage entity = entities[_entityAddress];
        entity.name = _name;
        entity.metadataURI = _metadataURI;

        emit EntityUpdated(_entityAddress, _name, entity.role);
    }

    /**
     * @dev Change an entity's role
     * @param _entityAddress Address of the entity
     * @param _newRole New role to assign
     */
    function changeRole(
        address _entityAddress,
        UserRole _newRole
    ) external onlyOwner {
        require(
            entities[_entityAddress].isActive,
            "RBAC: Entity not registered or inactive"
        );

        Entity storage entity = entities[_entityAddress];
        UserRole oldRole = entity.role;
        
        // Remove old role assignment
        roleAssignments[oldRole][_entityAddress] = false;
        
        // Assign new role
        entity.role = _newRole;
        roleAssignments[_newRole][_entityAddress] = true;

        emit RoleRevoked(_entityAddress, oldRole);
        emit RoleAssigned(_entityAddress, _newRole);
        emit EntityUpdated(_entityAddress, entity.name, _newRole);
    }

    /**
     * @dev Deactivate an entity
     * @param _entityAddress Address of the entity to deactivate
     */
    function deactivateEntity(address _entityAddress) external onlyOwner {
        require(
            entities[_entityAddress].isActive,
            "RBAC: Entity not registered or already inactive"
        );

        Entity storage entity = entities[_entityAddress];
        entity.isActive = false;

        // Remove role assignment
        roleAssignments[entity.role][_entityAddress] = false;

        emit EntityDeactivated(_entityAddress);
    }

    /**
     * @dev Check if an address has a specific role
     * @param _entityAddress Address to check
     * @param _role Role to verify
     * @return bool True if the address has the role
     */
    function hasRole(address _entityAddress, UserRole _role) public view returns (bool) {
        return roleAssignments[_role][_entityAddress] && entities[_entityAddress].isActive;
    }

    /**
     * @dev Get entity information
     * @param _entityAddress Address of the entity
     * @return Entity information
     */
    function getEntity(address _entityAddress) external view returns (Entity memory) {
        return entities[_entityAddress];
    }

    /**
     * @dev Check if an entity is active
     * @param _entityAddress Address of the entity
     * @return bool True if the entity is active
     */
    function isEntityActive(address _entityAddress) external view returns (bool) {
        return entities[_entityAddress].isActive;
    }
}                                                                                      