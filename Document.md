# PharmaTracCore – Supply Chain Smart Contract Specification

## 1. Purpose

PharmaTracCore provides a decentralized registry and coordination hub for a pharmaceutical supply chain system. It ensures trust, transparency, and compliance by recording participants, drug batches, supply movements, audits, and emergency recalls on the blockchain.

The contract’s primary purpose is to:

* Maintain an on-chain registry of supply chain participants.
* Authorize specialized sub-contracts for different functions (Drug, SupplyChain, Compliance, Emergency).
* Enforce role-based access control.
* Record immutable events to create an auditable trail.

---

## 2. Scope

The system covers the end-to-end pharmaceutical supply chain, including:

1. **Manufacturing** – batch creation and registration.
2. **Distribution** – shipment and custody transfers.
3. **Pharmacy** – dispensing to end consumers.
4. **Regulation** – oversight, compliance verification, and audits.
5. **Emergency Handling** – recalls, quarantines, and alerts.

---

## 3. Stakeholders & Roles

* **System Owner / Admin**

  * Deployer and ultimate authority.
  * Registers entities, authorizes contracts, sets system parameters.

* **Manufacturer**

  * Creates drug batches and initiates supply chain events.
  * Responsible for providing accurate product data.

* **Distributor**

  * Transfers drugs between custody points.
  * Ensures correct handling and traceability.

* **Pharmacy**

  * Receives drugs from distributors.
  * Dispenses products to patients/customers.

* **Regulator**

  * Conducts audits, verifies compliance, and flags irregularities.
  * Can trigger recalls through the Emergency system.

* **Authorized Sub-Contracts**

  * `Drug` – Manages drug batch records.
  * `SupplyChain` – Tracks shipment/transfer events.
  * `Compliance` – Records certifications, audits, and approvals.
  * `Emergency` – Handles recalls and quarantine processes.

---

## 4. Core Features

### 4.1 Entity Management

* Entities (organizations or individuals) are registered with their blockchain address, role, and metadata.
* Entity lifecycle: **Register → Update → Deactivate**.
* Entities must be active to participate in supply chain activities.

### 4.2 Contract Authorization

* External sub-contracts must be explicitly authorized by the core.
* Authorized contracts can interact with the registry and enforce rules.
* Owner may revoke authorization if contracts are compromised or outdated.

### 4.3 Role-Based Access Control

* Manufacturers, distributors, pharmacies, and regulators are assigned distinct roles.
* Functions and permissions are restricted based on roles.
* Only active entities with the correct role can execute role-specific functions.

### 4.4 Drug Batch Management (via `Drug` contract)

* Each drug batch is uniquely identified with batch details, production date, expiry date, and metadata URI.
* Manufacturers create batches.
* Regulator can mark status as **Active, Recalled, Quarantined, Expired**.

### 4.5 Supply Chain Tracking (via `SupplyChain` contract)

* Records transfer events of batches across participants.
* Tracks sender, receiver, timestamp, and optional location/metadata.
* Creates an immutable custody trail from production to end dispensing.

### 4.6 Compliance Auditing (via `Compliance` contract)

* Regulators attach compliance certificates or audit reports to batches.
* Certificates may be URIs (IPFS/Arweave) or cryptographic proofs.
* Allows third-party auditors to prove verification of supply chain standards.

### 4.7 Emergency Handling (via `Emergency` contract)

* Regulators and manufacturers can initiate recalls.
* Recalls mark affected batches, preventing pharmacies from dispensing.
* Emergency events are publicly visible to ensure quick responses.

---

## 5. Data Model

### 5.1 Entity

* Address (unique identifier).
* Name (string).
* Role (enum: Manufacturer, Distributor, Pharmacy, Regulator, Admin).
* Active/Inactive status.
* Registration timestamp.
* Optional metadata URI (KYC or license documents).

### 5.2 Drug Batch

* Batch ID.
* Product Name / Code.
* Manufacturer.
* Manufacture date.
* Expiry date.
* Metadata URI (lab reports, composition).
* Status (Active, Recalled, Expired, Quarantined).

### 5.3 Transfer Event

* Transfer ID.
* Batch ID.
* From (entity address).
* To (entity address).
* Timestamp.
* Location (optional).
* Off-chain signature (optional).

### 5.4 Compliance Record

* Batch ID.
* Auditor / Regulator.
* Report or Certificate URI.
* Timestamp.
* Status (Approved, Pending, Rejected).

### 5.5 Emergency Recall

* Batch ID.
* Triggered by (manufacturer/regulator).
* Reason for recall.
* Timestamp.
* Resolution status.

---

## 6. Events (for auditability)

* **EntityRegistered** – when a new entity is added.
* **EntityUpdated** – when entity details are modified.
* **EntityDeactivated** – when an entity is disabled.
* **ContractAuthorized / ContractUnauthorized** – when sub-contracts are managed.
* **BatchCreated** – when a new drug batch is created.
* **BatchStatusChanged** – when a batch is recalled, expired, or quarantined.
* **TransferRecorded** – when ownership of a batch is transferred.
* **AuditRecorded** – when a compliance audit is attached.
* **BatchFlagged** – when a recall is initiated.

---

## 7. Access Control Matrix

| Action                | Admin | Manufacturer | Distributor | Pharmacy | Regulator |
| --------------------- | ----- | ------------ | ----------- | -------- | --------- |
| Register Entity       | ✅     | ❌            | ❌           | ❌        | ❌         |
| Create Drug Batch     | ❌     | ✅            | ❌           | ❌        | ❌         |
| Transfer Drug Batch   | ❌     | ✅            | ✅           | ✅        | ❌         |
| Dispense Drug         | ❌     | ❌            | ❌           | ✅        | ❌         |
| Audit / Certify Batch | ❌     | ❌            | ❌           | ❌        | ✅         |
| Initiate Recall       | ❌     | ✅            | ❌           | ❌        | ✅         |

---

## 8. Security Considerations

* **Multisig for Admin:** The admin role should be held by a multi-signature wallet.
* **Access Control:** Enforced strictly by role-based modifiers.
* **No Personal Data On-Chain:** Store only references (hashes, URIs) to sensitive documents.
* **Immutability:** Once an event is recorded, it cannot be altered.
* **Emergency Mechanisms:** Ability to pause or recall batches.
* **Audit Trails:** All major actions emit events to ensure transparency.

---

## 9. Compliance & Regulatory Alignment

* Designed to align with Good Manufacturing Practice (GMP) and Good Distribution Practice (GDP).
* Provides regulators with immutable records of transactions.
* Allows linking of compliance certificates and regulatory approvals.
* Ensures full traceability from manufacturing to dispensation.

---

## 10. Deployment & Operations

* Deploy PharmaTracCore as the root contract.
* Deploy sub-contracts (`Drug`, `SupplyChain`, `Compliance`, `Emergency`).
* Authorize sub-contracts in PharmaTracCore.
* Register initial participants (manufacturers, distributors, pharmacies, regulators).
* Establish off-chain indexing services (e.g., The Graph) for querying events.
* Integrate front-end dApp for role-based dashboards.

---

## 11. Testing & Validation

* **Unit Testing:** entity registration, contract authorization, role enforcement.
* **Integration Testing:** drug creation → transfer → dispensing → recall.
* **Security Testing:** role abuse, reentrancy, unauthorized access.
* **Simulation:** regulator recall event affecting downstream pharmacy dispensing.

---

## 12. Benefits

* Transparency for patients, manufacturers, and regulators.
* Fraud prevention through immutable drug provenance.
* Rapid response to recalls.
* Reduced counterfeit risks.
* Compliance-friendly design.

---

## 13. Future Extensions

* Integration with IoT devices for shipment tracking.
* Zero-knowledge proofs for privacy-preserving compliance.
* Tokenized incentives for pharmacies/distributors maintaining standards.
* Interoperability with healthcare records.

---

**End of Document**
