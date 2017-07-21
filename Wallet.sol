pragma solidity ^0.4.11;

import MultiOwned from './MultiOwned.sol';
import DayLimit from './DayLimit.sol';
import MultiSig from './MultiSig.sol';
import Creator from './Creator.sol';

/*
 * Wallet.sol
 * Based on the Parity Wallet by Gav Wood.
 *
 * 
 */
 contract Wallet is MultiOwned,
                    DayLimit,
                    MultiSig,
                    Creator {

    struct Transaction {
        address to;
        uint value;
        bytes data;
    }

    function Wallet(address[] _owners, 
                    uint _required, 
                    uint _daylimit) 
        MultiOwned(_owners, _required)
        DayLimit(_daylimit) {
    }

    function delete(address _to) 
        onlyManyOwners(sha3(msg.data)) external {
        selfdestruct(_to);
    }

    function () payable {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    function execute(address _to, uint _value, bytes _data)
        external onlyOwner returns (bytes32 o_hash) {
        // Make sure we are under the daily limit.
        if ((_data.length == 0 && underLimit(_value))
            || m_required == 1) {
            // yes- just execute the call
            address created;
            if (_to == 0) {
                created = create(_value, _data);
            } else {
                require(_to.call.value(_value)(_data));
            }
            SingleTransact(msg.sender, _value, _to, _data, created);
        } else {
            // Determine our operation hash.
            o_hash = sha3(msg.data, block.number);
            // Store if it's new.
            if (m_txs[o_hash].to == 0 
                && m_txs[o_hash].value == 0
                && m_txs[o_hash].data.length ==0) {
                m_txs[o_hash].to = _to;
                m_txs[o_hash].value = _value;
                m_txs[o_hash].data = _data;
            }
            if (!confirm(o_hash)) {
                ConfrimationNeeded(o_hash, 
                                   msg.sender,
                                   _value,
                                   _to,
                                   _data);
            }
        }
    }

    function create(uint _value, bytes _code)
        internal returns (address o_addr) {
        return doCreate(_value, _code);
    }

    function confirm(bytes32 _h)
        onlyManyOwners(_h) returns (bool o_success) {
        if (m_txs[_h].to != 0
            || m_txs[_h].value != 0
            || m_txs[_h].data.length != 0) {
            address created;
            if (m_txs[_h].to == 0) {
                created = create(m_txs[_h].value, m_txs[_h].data);
            } else {
                require(m_txs[_h].to.call.value(m_txs[_h].value)(m_txs[_h].data));
            }

            MultiTransact(msg.sender, 
                          _h, 
                          m_txs[_h].value,
                          m_txs[_h].to,
                          m_txs[_h].data,
                          created);
            delete m_txs[_h];
            return true;
        }
    }

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i <length; ++i)
            delete m_txs[m_pendingIndex[i]];
        super.clearPending();
    }

    mapping (bytes32 => Transaction) m_txs;
}