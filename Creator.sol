pragma solidity ^0.4.11;

/*
 * Creator.sol
 * Based on the Parity Wallet by Gav Wood.
 *
 * Inheritable contract that allows to create a contract.
 */
contract creator {
    function doCreate(uint _value, bytes _code)
        internal returns (address o_addr) {
        bool failed;
        assembly {
            o_addr := create(_value, add(_code, 0x20), mload(_code))
            failed := iszero(extcodesize(o_addr))
        }
        require(!failed);
        }
}