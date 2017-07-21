pragma solidity ^0.4.11;

import MultiOwned from './MultiOwned.sol';

/*
 * DayLimit.sol
 * Based on the Parity Wallet by Gav Wood.
 *
 * Inheritable contract that enables methods to be 
 * protected by placing a linear limit (specifiable)
 * on a particular resource per calendar day.
 */
contract DayLimit is MultiOwned {

    // Constructor stores the initial daily limit and 
    // records the present day's index.
    function DayLimit(uint _limit) {
        m_dailyLimit = _limit;
        m_lastDay = today();
    }

    // Sets the daily limit. Needs many of the owners to
    // confirm.
    function setDailyLimit(uint _newLimit) 
        onlyManyOwners(sha3(msg.data)) external {
        m_dailyLimit = _newLimit;
    }
    
    // Resets the amount already spent today.
    function resetSpentToday() 
        onlyManyOwners(sha3(msg.data)) external {
        m_spentToday = 0;
    }

    // Internals

    // Check to see if there at least `_value` left in
    // the daily spend limit today. If there is, subtract
    // it and return true.
    function underLimit(uint _value)
        internal onlyOwner returns (bool) {
        // Reset the spend limit if we're on a different
        // since last time.
        if (today() > m_lastDay) {
            m_spentToday = 0;
            m_lastDay = today();
        }
        // Check to see if there's enough left - if so,
        // subtract and return true.
        if (m_spentToday + _value >= m_spentToday 
            && m_spentToday + _value <= m_dailyLimit) {
            m_spentToday += _value;
            return true;
        }
        return false;
    }

    // Determines today's index.
    function today() private constant returns (uint) {
        return now / 1 days;
    }

    uint public m_dailyLimit;
    uint public m_spentToday;
    uint public m_lastDay;
}