// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;


contract EnergyCertificateLedger  {

    // Structs
    struct Balance {
        uint256 available;
        uint256 locked;
        uint256 consumed;
        uint256 totalMinted;
    }

    struct TransferRecord {
        uint256 id;
        address from;
        address to;
        uint256 amount;
        uint256 batchId;
        bytes32 reason;
        uint64 createdAt;
    }

    // Storage
    mapping(address => Balance) public balances;
    mapping(address => mapping(uint256 => Balance)) public balancesByAccountAndBatch;
    mapping(uint256 => bool) public mintedBatches;
    uint256 private transferCounter;
    mapping(uint256 => TransferRecord) public transferRecords;
    mapping(address => uint256[]) public transferHistory;


    // Events
    event CertificateMinted(address mintedBy, uint256 batchId, uint256 amount);
    event CertificateLocked();
    event CertificateUnlocked();
    event CertificateTransferred();
    event CertificateConsumed();
    event CertificateBurned();

    // Erros
    error InsufficientAvailableBalance();
    error InsufficientLockedBalance();
    error InvalidAmount();
    error InvalidAccount();
    error UnauthorizedLedgerOperator();
    error BatchBalanceNotFound();
    error BatchAlreadyMinted();

    // Functions
    function mintFromApprovedBatch(
        address account,
        uint256 batchId,
        uint256 amount
    ) external {
        if(account == address(0)){
            revert InvalidAccount();
        } 
        if(amount == 0){
            revert InvalidAmount();
        } 
        if(mintedBatches[batchId]){
            revert BatchAlreadyMinted();
        }

        mintedBatches[batchId] = true;

        balances[account].available += amount;
        balances[account].totalMinted += amount;

        balancesByAccountAndBatch[account][batchId].available += amount;
        balancesByAccountAndBatch[account][batchId].totalMinted += amount;

        emit CertificateMinted(account, batchId, amount);
    }

    function lockBalance(
        address account, 
        uint256 batchId, 
        uint256 amount
    ) external {

        if(account == address(0)){
            revert InvalidAccount();
        } 

        if(amount == 0){
            revert InvalidAmount();
        }

        if (balances[account].available < amount){
            revert InsufficientAvailableBalance();
        }

        balances[account].available -= amount;
        balances[account].locked += amount;

        balancesByAccountAndBatch[account][batchId].available -= amount;
        balancesByAccountAndBatch[account][batchId].locked += amount;
    }
    
    // unlockBalance(...)
    // transferAvailable(...)
    // transferLocked(...)
    // consume(...)
    // burn(...)

    // getAvailableBalance(...)
    // getLockedBalance(...)
    // getConsumedBalance(...)
    // getTotalBalance(...)
    // getBatchBalance(...)
    // getTransferRecord(...)
}