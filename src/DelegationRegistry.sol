// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**

Opinionated:
- fully onchain, no EIP712 signatures
- fully immutable, no admin powers
- fully standalone, no external dependencies
- fully identifiable, clear method names
- reusable global registry w/ same address across multiple EVM chains

Why?
Onchain is critical for smart contract composability that can't produce a signature.
Immutable is critical for any public good that will stand the test of time.
Standalone is critical for ensuring the guarantees will stay valid.
Identifiable is critical to avoid phishing scams when people are using vaults to interact with the registry.
Reusable is critical so new projects can bootstrap off existing network effects.

Use an ERC-165-esque hash list for specific permissions. Start out with claim permissions but can expand to more later.

TODO: can we get onchain enumeration?
TODO: can we get all-at-once revocation?
TODO: can we get timelocked delegation for selling off airdrop rights?
TODO: does the ens fuse wrapper match what we're doing here?

*/


contract DelegationRegistry {

    mapping(bytes32 => address) delegations;

    event DelegateForAll(address _vault, address _delegate, bytes32 role);
    event DelegateForCollection(address _vault, address _delegate, bytes32 role, address _collection);
    event DelegateForToken(address _vault, address _delegate, bytes32 role, address _collection, uint256 _tokenId);


    ///////////
    // WRITE //
    ///////////

    function delegateForAll(address _delegate, bytes32 _role) external {
        bytes32 delegateHash = keccak256(abi.encodePacked(_role, msg.sender));
        delegations[delegateHash] = _delegate;
        emit DelegateForAll(msg.sender, _delegate, _role);
    }

    function delegateForCollection(address _delegate, bytes32 _role, address _collection) external {
        bytes32 delegateHash = keccak256(abi.encodePacked(_role, msg.sender, _collection));
        delegations[delegateHash] = _delegate;
        emit DelegateForCollection(msg.sender, _delegate, _role, _collection);
    }

    function delegateForToken(address _delegate, bytes32 _role, address _collection, uint256 _tokenId) external {
        bytes32 delegateHash = keccak256(abi.encodePacked(_role, msg.sender, _collection, _tokenId));
        delegations[delegateHash] = _delegate;
        emit DelegateForToken(msg.sender, _delegate, _role, _collection, _tokenId);
    }

    //////////
    // READ //
    //////////

    function getDelegateForAll(bytes32 _role, address _vault) public view returns (address) {
        bytes32 delegateHash = keccak256(abi.encodePacked(_role, _vault));
        return delegations[delegateHash];
    }

    function getDelegateForCollection(bytes32 _role, address _vault, address _collection) public view returns (address) {
        bytes32 delegateHash = keccak256(abi.encodePacked(_vault, _collection));
        address delegate = delegations[delegateHash];
        return delegate != address(0x0) ? delegate : getDelegateForAll(_role, _vault);
    }
    
    function getDelegateForToken(bytes32 _role, address _vault, address _collection, uint256 _tokenId) public view returns (address) {
        bytes32 delegateHash = keccak256(abi.encodePacked(_vault, _collection, _tokenId));
        address delegate = delegations[delegateHash];
        return delegate != address(0x0) ? delegate : getDelegateForCollection(_role, _vault, _collection);
    }
}