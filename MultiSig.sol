pragma solidity ^0.4.11;

/*
 * MultiSig.sol
 * Based on the Parity Wallet by Gav Wood.
 *
 * Interface contract for multisig proxy contracts.
 */
contract MultiSig {

    // Funds have arrived in the wallet.
    event Deposit(address from, uint value);
    // Single transaction going out of the wallet (records
    // who signed it, how much and where it's going).
    event SingleTransact(address owner, 
                         uint value, 
                         address to, 
                         bytes data, 
                         address created);
    // Multi-sig transaction going out of this wallet 
    // (records who signed it last, the operation hash, 
    // how much and where it's going).
    event Multitransact(address owner, 
                        bytes32 operation, 
                        uint value, 
                        address to, 
                        bytes data, 
                        address created);
    // Confirmation still needed for transaction.
    event ConfirmationNeeded(bytes32 operation, 
                             address initiator, 
                             uint value, 
                             address to, 
                             bytes data);
    
    function changeOwner(address _from, address _to) 
        external;

    function execute(address _to, uint _value, bytes _data)
        external returns (bytes32 o_hash);

    function confirm(bytes32 _h) returns (bool o_success);
}