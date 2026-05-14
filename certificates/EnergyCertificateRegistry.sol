// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../access/EnergyAccessControl.sol";

contract EnergyCertificateRegistry is EnergyAccessControl {

    //Enums
    enum BatchStatus {
        Pending,
        Approved,
        Rejected,
        Cancelled
    }

    enum EnergySource {
        Solar,
        Wind,
        Hydro,
        Biomass,
        Other
    }

    struct EnergyPeriod {
        uint64 startsAt;
        uint64 endsAt;
    }

    struct EnergyLocation {
        int32 lat;
        int32 lng;
    }

    // Structs
    struct EnergyBatch {
        uint256 id;
        address producer;
        uint128 amount;
        EnergySource source;
        EnergyPeriod period;
        EnergyLocation location;
        bytes32 documentHash;
        BatchStatus status;
        uint64 createdAt;
        uint64 auditedAt;
        address auditor;
        bytes32 rejectionReasonHash;
    }

    // Memory
    uint256 private batchCounter;
    mapping(uint256 => EnergyBatch) public batches;
    mapping(address => uint256[]) public producerBatches;
    mapping(EnergySource => uint256[]) public sourceBatches;

    // Events
    event BatchSubmitted(uint256 indexed id, address indexed producerBy);
    event BatchApproved(uint256 indexed id, address indexed auditedBy);
    event BatchRejected(uint256 indexed id, address indexed auditedBy);
    event BatchCancelled(uint256 indexed id, address indexed auditedBy);
    event BatchMetadataUpdated(uint256 indexed batchId, address indexed updatedBy);


    // Errors
    error InvalidBatch();
    error InvalidAmount();
    error InvalidDocumentHash();
    error BatchNotPending();
    error BatchNotFound();
    error ProducerCannotAuditOwnBatch();
    error UnauthorizedProducer();
    error UnauthorizedAuditor();

    function _requireValidBatch(uint256 batchId) internal view {
        if (batchId == 0 || batchId > batchCounter) {
            revert InvalidBatch();
        }
    }

    // Functions
    function submitBatch(
        uint128 amount,
        EnergySource source,
        EnergyPeriod calldata period,
        EnergyLocation calldata location,
        bytes32 documentHash
    ) external onlyProducer whenNotPaused returns (uint256) {
        if (amount == 0) {
            revert InvalidAmount();
        }

        if (documentHash == bytes32(0)) {
            revert InvalidDocumentHash();
        }

        if (period.startsAt == 0 || period.endsAt <= period.startsAt) {
            revert InvalidBatch();
        }

        batchCounter++;

        uint256 batchId = batchCounter;

        batches[batchId] = EnergyBatch({
            id: batchId,
            producer: msg.sender,
            amount: amount,
            source: source,
            period: EnergyPeriod({
                startsAt: period.startsAt,
                endsAt: period.endsAt
            }),
            location: EnergyLocation({
                lat: location.lat,
                lng: location.lng
            }),
            documentHash: documentHash,
            status: BatchStatus.Pending,
            createdAt: uint64(block.timestamp),
            auditedAt: 0,
            auditor: address(0),
            rejectionReasonHash: bytes32(0)
        });

        producerBatches[msg.sender].push(batchId);
        sourceBatches[source].push(batchId);

        emit BatchSubmitted(
            batchId,
            msg.sender
        );

        return batchId;
    }

    function approveBatch(uint256 batchId) external onlyAuditor whenNotPaused {

        _requireValidBatch(batchId);

        EnergyBatch storage batch = batches[batchId];

        if(batch.producer == msg.sender) {
            revert ProducerCannotAuditOwnBatch();
        }

        if(batch.status != BatchStatus.Pending) {
            revert BatchNotPending();
        }
        batch.auditedAt = uint64(block.timestamp);
        batch.auditor = msg.sender;

        batch.status = BatchStatus.Approved;

        emit BatchApproved(
            batchId,
            msg.sender
        );

        // Implementar saldo no ledger quando o EnergyCertificateLedger for criado.
    }

    function rejectBatch(uint256 batchId) external onlyAuditor whenNotPaused {

        _requireValidBatch(batchId);

        EnergyBatch storage batch = batches[batchId];

        if(batch.producer == msg.sender) {
            revert ProducerCannotAuditOwnBatch();
        }

        if(batch.status != BatchStatus.Pending) {
            revert BatchNotPending();
        }
        batch.auditedAt = uint64(block.timestamp);
        batch.auditor = msg.sender;

        batch.status = BatchStatus.Rejected;

        emit BatchRejected(
            batchId,
            msg.sender
        );
    }

    function cancelBatch(uint256 batchId) external onlyProducer whenNotPaused {

        _requireValidBatch(batchId);

        EnergyBatch storage batch = batches[batchId];

        if(batch.producer != msg.sender) {
            revert UnauthorizedProducer();
        }

        if(batch.status != BatchStatus.Pending) {
            revert BatchNotPending();
        }
        batch.auditedAt = uint64(block.timestamp);
        batch.auditor = msg.sender;

        batch.status = BatchStatus.Cancelled;

        emit BatchCancelled(
            batchId,
            msg.sender
        );
    }

    function updateBatchMetadata(
        uint256 batchId,
        uint128 amount,
        EnergySource source,
        EnergyPeriod calldata period,
        EnergyLocation calldata location,
        bytes32 documentHash
    ) external onlyProducer whenNotPaused {

        _requireValidBatch(batchId);

        EnergyBatch storage batch = batches[batchId];

        if (batch.producer == address(0)) {
            revert BatchNotFound();
        }

        if (batch.producer != msg.sender) {
            revert UnauthorizedProducer();
        }

        if (batch.status != BatchStatus.Pending) {
            revert BatchNotPending();
        }

        if (amount == 0) {
            revert InvalidAmount();
        }

        if (documentHash == bytes32(0)) {
            revert InvalidDocumentHash();
        }

        batch.amount = amount;
        batch.source = source;
        batch.period = EnergyPeriod({
            startsAt: period.startsAt,
            endsAt: period.endsAt
        });
        batch.location = EnergyLocation({
            lat: location.lat,
            lng: location.lng
        });
        batch.documentHash = documentHash;

        emit BatchMetadataUpdated(
            batchId,
            msg.sender
        );
    }

    function getBatch(uint256 batchId) external view returns(EnergyBatch memory){

        _requireValidBatch(batchId);

        EnergyBatch storage batch = batches[batchId];

        return batch;
    }


    function getProducerBatches(address producerId) external view returns(uint256[] memory){
        if (producerId == address(0)) {
            revert InvalidAccount();
        }

        return producerBatches[producerId];
    }

    function getBatchStatus(uint256 batchId) external view returns(BatchStatus){
        _requireValidBatch(batchId);

        EnergyBatch storage batch = batches[batchId];

        return batch.status;
    }

    function exists(uint256 batchId) external view returns(bool){

        _requireValidBatch(batchId);

        if (batchId == 0 || batchId > batchCounter) {
            return true;
        } else {
            return false;
        }
    }

}