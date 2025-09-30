// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Drug} from "./drugContract.sol";
import {DrugSupplyChain} from "./supplychaincontract.sol";
import {Compliance} from "./complianceContract.sol";
import {Emergency} from "./emergencyContract.sol";

contract PharmaTracCore is Ownable {
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
    }

    mapping(address => Entity) public entities;
    mapping(address => bool) public authorizedContracts;

    Drug public drugContract;
    DrugSupplyChain public supplychaincontract;
    Compliance public complianceContract;
    Emergency public emergencyContract;

    event EntityRegistered(
        address indexed entityAddress,
        string name,
        UserRole role
    );
    event EntityUpdated(
        address indexed entityAdress,
        string name,
        UserRole role
    );
    event EntityDeactivated(address indexed entityAddress);
    event ContractAuthorized(address indexed contractAddress);
    event contractUnAuthorized(address indexed contractAddress);

    modifier onlyActive() {
        require(
            entities[msg.sender].isActive,
            "PharmaTrac: Entity is not Active"
        );
        _;
    }

    modifier onlyRole(UserRole _role) {
        require(
            entities[msg.sender].role == _role,
            "PharmaTract: Unauthorized"
        );
        _;
    }

    modifier onlyAuthorizedContracts() {
        require(authorizedContracts[msg.sender], "authorized is not contract");
        _;
    }

    uint256 private entitiesId;

    constructor() Ownable(msg.sender) {
        entitiesId++;
    }

    function registerEntity(
        address _entityAddress,
        string memory _name,
        UserRole _role
    ) external onlyOwner {
        require(
            _entityAddress != address(0),
            "PharmaTracCore: Invalid address"
        );
        require(
            !entities[_entityAddress].isActive,
            "PharmaTracCore: Entity already registered"
        );

        entities[_entityAddress] = Entity({
            entityAddress: _entityAddress,
            name: _name,
            role: _role,
            isActive: true,
            registeredAt: block.timestamp
        });

        emit EntityRegistered(_entityAddress, _name, _role);
    }

    function updateEntity(
        address _entityAddress,
        string memory _name,
        UserRole _role
    ) external onlyOwner {
        require(
            entities[_entityAddress].isActive,
            "PharmaTracCore: Entity not registered"
        );

        entities[_entityAddress].name = _name;
        entities[_entityAddress].role = _role;

        emit EntityUpdated(_entityAddress, _name, _role);
    }

    function deactivateEntity(address _entityAddress) external onlyOwner {
        require(
            entities[_entityAddress].isActive,
            "PharmaTracCore: Entity not registered"
        );

        entities[_entityAddress].isActive = false;

        emit EntityDeactivated(_entityAddress);
    }

    function authorizeContract(address _contractAddress) external onlyOwner {
        require(
            _contractAddress != address(0),
            "PharmaTracCore: Invalid address"
        );
        require(
            !authorizedContracts[_contractAddress],
            "PharmaTracCore: Contract already authorized"
        );

        authorizedContracts[_contractAddress] = true;
        emit ContractAuthorized(_contractAddress);
    }

    function unauthorizeContract(address _contractAddress) external onlyOwner {
        require(
            authorizedContracts[_contractAddress],
            "PharmaTracCore: Contract not authorized"
        );

        authorizedContracts[_contractAddress] = false;
        emit contractUnAuthorized(_contractAddress);
    }

    function setDrugContract(address _drugContract) external onlyOwner {
        drugContract = Drug(_drugContract);
    }

    function setSupplyChainContract(
        address _supplyChainContract
    ) external onlyOwner {
        supplychaincontract = DrugSupplyChain(_supplyChainContract);
    }

    function setComplianceContract(
        address _complianceContract
    ) external onlyOwner {
        complianceContract = Compliance(_complianceContract);
    }

    function setEmergencyContract(
        address _emergencyContract
    ) external onlyOwner {
        emergencyContract = Emergency(_emergencyContract);
    }

    function getEntity(
        address _entityAddress
    ) external view returns (Entity memory) {
        return entities[_entityAddress];
    }
}
