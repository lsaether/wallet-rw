# wallet-rw
Rewrite of the Parity Wallet that was itself rewritten after the [$31MM hacks](https://medium.freecodecamp.org/a-hacker-stole-31m-of-ether-how-it-happened-and-what-it-means-for-ethereum-9e5dc29e33ce).
The goal is to make the contract more readable and more modular and therefore easier to debug and audit.

# Contracts
- Creator.sol - Contains the logic for creating contracts from inside the multisig wallet.
- DayLimit.sol - Inheritable contract that sets a limit to the amount that can be spent.
- MultiOwned.sol - Inheritable contract that implements the logic for multiple owners.
- MultiSig.sol - Interface contract for the Wallet.
- Wallet.sol - Master contract that ties together all the pieces into a multisig wallet software.

# TODO
- Abstract MultiOwned.sol logic out into a libray.
