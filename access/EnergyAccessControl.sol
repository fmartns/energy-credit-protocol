// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

contract EnergyAccessControl {

    // Roles
    address public owner;
    mapping(address => bool) public auditors;
    mapping(address => bool) public producers;
    mapping(address => bool) public operators;
    bool public paused;

    // Events
    event OwnershipTransferred(address indexed account, address indexed transferredBy);
    event AuditorGranted(address indexed account, address indexed grantedBy);
    event AuditorRevoked(address indexed account, address indexed revokedBy);
    event ProducerGranted(address indexed account, address indexed grantedBy);
    event ProducerRevoked(address indexed account, address indexed revokedBy);
    event OperatorGranted(address indexed account, address indexed grantedBy);
    event OperatorRevoked(address indexed account, address indexed revokedBy);
    event ProtocolPaused(address indexed pausedBy);
    event ProtocolUnpaused(address indexed unpausedBy);

    // Erros
    error Unauthorized();
    error InvalidAccount();
    error AlreadyHasRole();
    error RoleNotFound();
    error ProtocolIsPaused();
    error ProtocolIsNotPaused();

    // Modifiers
    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyAuditor(){
        if(!auditors[msg.sender]){
            revert Unauthorized();
        }
        _;
    }

    modifier onlyProducer(){
        if(!producers[msg.sender]){
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOperador(){
        if(!operators[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    modifier whenNotPaused(){
        if(paused) {
            revert ProtocolIsPaused();
        }
        _;
    }

    modifier whenPaused(){
        if(!paused) {
            revert ProtocolIsNotPaused();
        }
        _;
    }

    // Functions
    constructor(){
        owner = msg.sender;
    }

    function transferOwnership(address account) external onlyOwner whenPaused {
        if(account == address(0)){
            revert InvalidAccount();
        }
        owner = account;

        emit OwnershipTransferred(account, msg.sender);
    }

    function grantAuditor(address account) external onlyOwner whenPaused {
        
        if(account == address(0)){
            revert InvalidAccount();
        }

        if(auditors[account]){
            revert AlreadyHasRole();
        }

        auditors[account] = true;

        emit AuditorGranted(account, msg.sender);
    }

    function revokeAuditor(address account) external onlyOwner whenPaused {
        
        if(account == address(0)){
            revert InvalidAccount();
        }

        if(!auditors[account]){
            revert RoleNotFound();
        }

        auditors[account] = false;

        emit AuditorRevoked(account, msg.sender);
    }

    function isAuditor(address account) external view returns(bool){
        return auditors[account];
    }

    function grantProducer(address account) external onlyOwner whenPaused {
        
        if(account == address(0)){
            revert InvalidAccount();
        }

        if(producers[account]){
            revert AlreadyHasRole();
        }

        producers[account] = true;

        emit ProducerGranted(account, msg.sender);
    }

    function revokeProducer(address account) external onlyOwner whenPaused {
        
        if(account == address(0)){
            revert InvalidAccount();
        }

        if(!producers[account]){
            revert RoleNotFound();
        }

        producers[account] = false;

        emit ProducerRevoked(account, msg.sender);
    }

    function isProducer(address account) external view returns(bool){
        return producers[account];
    }

    function grantOperator(address account) external onlyOwner whenPaused {
        
        if(account == address(0)){
            revert InvalidAccount();
        }

        if(operators[account]){
            revert AlreadyHasRole();
        }

        operators[account] = true;

        emit OperatorGranted(account, msg.sender);
    }

    function revokeOperator(address account) external onlyOwner whenPaused {
        
        if(account == address(0)){
            revert InvalidAccount();
        }

        if(!operators[account]){
            revert RoleNotFound();
        }

        operators[account] = false;

        emit OperatorRevoked(account, msg.sender);
    }

    function isOperator(address account) external view returns(bool){
        return operators[account];
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;

        emit ProtocolPaused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;

        emit ProtocolUnpaused(msg.sender);
    }

    function isPaused() external view returns(bool){
        return paused;
    }

}