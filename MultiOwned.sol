pragma solidity ^0.4.11;

/*
 * Mulitowned.sol
 * Based on the Parity Wallet contract by Gav Wood.
 *
 * Inheritable contract that enables methods to be protected
 * by requiring the acquiescence of a single or, crucially, 
 * each of a number of designated owners.
 */
contract MultiOwned {

    // Struct for the status of a pending operation.
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

    // This contract has six types of events:
    // It can accept a confirmation, in which case we record
    // the owner and operation (hash) alongside it.
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    // These are for change of ownership.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
    // This is if the required number of signatures change.
    event RequirementChanged(uint newRequirement);

    // Single-sig modifier.
    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    // Multi-sig modifier: This operation must have an
    // intrinsic hash in order that later attempts can be 
    // realized as the same underlying operation.
    modifier onlyManyOwners(bytes32 _operation) {
        require(confirmAndCheck(_operation));
        _;
    }

    // Pass in the number of required sigs to the constructor
    // and select the addresses capable of executing them.
    function MultiOwned(address[] _owners, uint _required) {
        require(_required > 0);
        require(_owners.length >= _required);
        m_numOwners = _owners.length;
        
        uint i = 0;
        while (i < _owners.length) {
            m_owners[1 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 1 + i;
            ++i;
        }
        m_required = _required;
    }

    // Revokes a prior confirmation of the given operation.
    function revoke(bytes32 _operation) external {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // Make sure they are an owner.
        require(ownerIndex != 0);
        uint ownerIndexBit = 2 ** ownerIndex;
        var pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            Revoke(msg.sender, _operation);
        }
    }

    // Replaces an owner `_from` with another `_to`.
    function changeOwner(address _from, address _to)
        onlyManyOwners(sha3(msg.data)) external {
        require(!isOwner(_to));
        uint ownerIndex = m_ownerIndex[uint(_from)];
        assert(ownerIndex != 0);

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
        }

    function removeOwner(address _owner) 
        onlyManyOwners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        assert(ownerIndex != 0);
        assert(m_numOwners - 1 >= m_required);

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners(); // ensures that m_numOwners is
        // equal to the number of owners and always points
        // to the optimal free slot.
        OwnerRemoved(_owner);
        }
    
    function changeRequirement(uint _newRequired)
        onlyManyOwners(sha3(msg.data)) external {
        require(_newRequired != 0);
        assert(m_numOwners >= _newRequired);
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
        }

    // Gets an owner by 0-indexed position (using numOwners
    // as the count).
    function getOwner(uint ownerIndex) 
        external constant returns (address) {
        return address(m_owners[ownerIndex + 1]);
        }

    function isOwner(address _addr) returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }

    function hasConfirmed(bytes32 _operation, address _owner)
        constant returns (bool) {
        var pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

        // Verify that they are an owner.
        assert(ownerIndex != 0);

        // Determine the bit to set.
        uint ownerIndexBit = 2 ** ownerIndex;
        return !(pending.ownersDone & ownerIndexBit == 0);
    }
    
    // Internals

    function confirmAndCheck(bytes32 _operation)
        internal returns (bool) {
        // Determine what index the present sender is:
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // Verify that they are an owner.
        assert(ownerIndex != 0);

        var pending = m_pending[_operation];
        // If we are not yet working on this operation,
        // switch over to it and reset the confirmation status.
        if (pending.yetNeeded == 0) {
            // Reset count.
            pending.yetNeeded = m_required;
            // Reset which owners have confirmed (none) -
            // set out bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
        // Determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        // Make sure that us (the msg.sender) have not
        // confirmed this operation previously.
        if (pending.ownersDone & ownerIndexBit == 0) {
            Confirmation(msg.sender, _operation);
            // ok - check if count is enough to go ahead.
            if (pending.yetNeeded <= 1) {
                // enough confirms: reset and run interior.
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            } 
            else 
            {
                // not enough: record that this owner in
                // particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
    }

    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
            while (free < m_numOwners && m_owners[free] != 0) 
            free++;
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0)
            m_numOwners--;
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            if (m_pendingIndex[i] != 0)
                delete m_pending[m_pendingIndex[i]];
        delete m_pendingIndex;
    }

    // The number of owners that must confirm before the 
    // operation is run.
    uint public m_required;
    // The pointer used to find a free slot in m_owners.
    uint public m_numOwners;

    // List of owners.
    uint[256] m_owners;
    uint constant c_maxOwners = 250;
    // Index on the list of owners to allow reverse lookup.
    mapping(uint => uint) m_ownersIndex;
    // The ongoing operations.
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;
}