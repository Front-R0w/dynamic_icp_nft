// Import the necessary packages
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import List "mo:base/List";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Types "./src/nft/Types";
import Iter "mo:base/Iter";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Time "mo:base/Time";


// Define a shared actor class called 'Dip721NFT' that takes a 'Principal' ID as the custodian value and is initialized with the types for the Dip721NonFungibleToken.
shared actor class Dip721NFT(custodian: Principal, init : Types.Dip721NonFungibleToken) = Self {
  stable var transactionId: Types.TransactionId = 0;
  stable var nfts = List.nil<Types.Nft>();
  stable var custodians = List.make<Principal>(custodian);
  stable var logo : Types.LogoResult = init.logo;
  stable var name : Text = init.name;
  stable var symbol : Text = init.symbol;
  stable var maxLimit : Nat16 = init.maxLimit;
  stable var createdAt : Nat64 = init.created_at;
  stable var updatedAt : Nat64 = 0;
  stable var approvals : List.List<(Types.TokenId, Principal)> = List.nil();
  stable var approvedBy : List.List<(Types.TokenId, Principal)> = List.nil();
  stable var approvedAt : Nat64 = 0;
  stable var globalApprovals : List.List<(Principal, Principal, Bool)> = List.nil();

  // Define a 'null_address' variable
  let null_address : Principal = Principal.fromText("aaaaa-aa");

  // Define a public function called 'balanceOfDip721' that returns the current balance of NFTs for the current user: 
  public query func balanceOfDip721(user: Principal) : async Nat64 {
    return Nat64.fromNat(
      List.size(
        List.filter(nfts, func(token: Types.Nft) : Bool { token.owner == user })
      )
    );
  };

  // Returns the Metadata of the NFT canister which includes custodians, logo, name, symbol
  public query func getMetadata() : async Types.Metadata {
    return {
      logo = logo;
      name = name;
      created_at = createdAt;
      updated_at = updatedAt;
      custodians = custodians;
      symbol = symbol;
    };
  };

  // Define a public function called 'stats' that Returns the Stats of the NFT canister which includes cycles, totalSupply, totalTransactions, totalUniqueHolders.
  public query func statsDip721() : async Types.Stats {
    let cycles = Cycles.balance(); // Get the current cycle balance of the canister
    let totalSupply = List.size(nfts); // Total supply of NFTs
    let totalTransactions = transactionId;

    // Initialise an empty list for unique holders
    var uniqueHolders: List.List<Principal> = List.nil();

    // Iterate through all NFTs to collect unique owners
    for (nft in Iter.fromList(nfts)) {
      let isUnique = List.all(uniqueHolders, func (owner: Principal): Bool {
        owner != nft.owner
      });
      if (isUnique) {
        uniqueHolders := List.push(nft.owner, uniqueHolders);
      }
    };

    let totalUniqueHolders = List.size(uniqueHolders); // Total number of unique NFT holders


    return {
      cycles = cycles;
      total_transactions = totalTransactions;
      total_unique_holders = totalUniqueHolders;
      total_supply = totalSupply;
    };
  };

  // Define a public function called 'setLogo' that sets the logo of the NFT canister - Caller must be the custodian of the NFT canister
  public shared({caller}) func setLogoDip721(newLogoData: Text) : async () {
    // Check if the caller is a custodian
    let isCustodian = List.some(custodians, func(c: Principal): Bool {
      c == caller
    });

    if (isCustodian) {
      // Update the logo with new Base64 encoded data
      logo := {logo_type = logo.logo_type; data = newLogoData};
    } else {
      // Throw an error or ignore if the caller is not a custodian
      throw Error.reject("Caller is not the custodian.");
    }
  };

  // Define a public function called 'setName' that sets the name of the NFT canister - Caller must be the custodian of the NFT canister
  public shared({caller}) func setNameDip721(newName: Text) : async () {
    // Check if the caller is a custodian
    let isCustodian = List.some(custodians, func(c: Principal): Bool {
      c == caller
    });

    if (isCustodian) {
      // Update the name with the new name
      name := newName;
    } else {
      // Throw an error or ignore if the caller is not a custodian
      throw Error.reject("Caller is not the custodian.");
    }
  };

  // Define a public function called 'setSymbol' that sets the name of the NFT canister - Caller must be the custodian of the NFT canister
  public shared({caller}) func setSymbolDip721(newSymbol: Text) : async () {
    // Check if the caller is a custodian
    let isCustodian = List.some(custodians, func(c: Principal): Bool {
      c == caller
    });

    if (isCustodian) {
      // Update the symbol with the new symbol
      symbol := newSymbol;
    } else {
      // Throw an error or ignore if the caller is not a custodian
      throw Error.reject("Caller is not the custodian.");
    }
  };

  // Define a public function called 'custodians' that returns a list of principals that represents the custodians (or admins) of the NFT canister
  public query func getCustodiansDip721() : async [Principal] {
    return List.toArray(custodians);
  };

  // Define a public function called 'setCustodians' that sets the list of custodians for the NFT canister - Caller must be the custodian of the NFT canister
  public shared({caller}) func setCustodiansDip721(newCustodians: List.List<Principal>) : async () {
    // Check if the caller is a custodian
    let isCustodian = List.some(custodians, func(c: Principal): Bool {
      c == caller
    });

    if (isCustodian) {
      // Update the list of custodians with the new list
      custodians := newCustodians;
    } else {
      // Throw an error or ignore if the caller is not a custodian
      throw Error.reject("Caller is not the custodian.");
    }
  };

  // Define a public function called 'cycles' that returns the current cycles balance of the NFT canister
  public query func getCyclesDip721() : async Nat {
    return Cycles.balance();
  };

  // Define a public function called 'totalUniqueHolders' that return total unique user's NFT holders of NFT canister
  public query func getTotalUniqueHoldersDip721() : async Nat {
    // Initialise an empty list for unique holders
    var uniqueHolders: List.List<Principal> = List.nil();

    // Iterate through all NFTs to collect unique owners
    for (nft in Iter.fromList(nfts)) {
      let isUnique = List.all(uniqueHolders, func (owner: Principal): Bool {
        owner != nft.owner
      });
      if (isUnique) {
        uniqueHolders := List.push(nft.owner, uniqueHolders);
      }
    };

    return List.size(uniqueHolders); // Total number of unique NFT holders
  };


  // Define a public function called 'ownerOfDip721' that returns the principal that owns an NFT: 
  public query func ownerOfDip721(token_id: Types.TokenId) : async Types.OwnerResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case (null) {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.owner);
      };
    };
  };

  // Define a shared function called 'safeTransferFromDip721' that provides functionality for transferring NFTs and checks if the transfer is from the 'null_address', and errors if it is:
  public shared({ caller }) func safeTransferFromDip721(from: Principal, to: Principal, token_id: Types.TokenId) : async Types.TxReceipt {  
    if (to == null_address) {
      return #Err(#ZeroAddress);
    } else {
      return transferFrom(from, to, token_id, caller);
    };
  };

  // Define a shared function called 'transferFromDip721' that provides functionality for transferring NFTs without checking if the transfer is from the 'null_address':
  public shared({ caller }) func transferFromDip721(from: Principal, to: Principal, token_id: Types.TokenId) : async Types.TxReceipt {
    return transferFrom(from, to, token_id, caller);
  };

  func transferFrom(from: Principal, to: Principal, token_id: Types.TokenId, caller: Principal) : Types.TxReceipt {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        if (
          caller != token.owner and
          not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })
        ) {
          return #Err(#Unauthorized);
        } else if (Principal.notEqual(from, token.owner)) {
          return #Err(#Other);
        } else {
          nfts := List.map(nfts, func (item : Types.Nft) : Types.Nft {
            if (item.id == token.id) {
              let update : Types.Nft = {
                owner = to;
                id = item.id;
                metadata = token.metadata;
              };
              return update;
            } else {
              return item;
            };
          });
          transactionId += 1;
          return #Ok(transactionId);   
        };
      };
    };
  };

  // Define a public function that queries and returns the supported interfaces:
  public query func supportedInterfacesDip721() : async [Types.InterfaceId] {
    return [#TransferNotification, #Burn, #Mint];
  };

 // Define a public function that queries and returns the NFT's logo:
  public query func logoDip721() : async Types.LogoResult {
    return logo;
  };

  // Define a public function that queries and returns the NFT's name:
  public query func nameDip721() : async Text {
    return name;
  };

  // Define a public function that queries and returns the NFT's symbol:
  public query func symbolDip721() : async Text {
    return symbol;
  };

  // Define a public function that queries and returns the NFT's total supply value:
  public query func totalSupplyDip721() : async Nat64 {
    return Nat64.fromNat(
      List.size(nfts)
    );
  };

  // Define a public function that queries and returns the NFT's metadata:
  public query func getMetadataDip721(token_id: Types.TokenId) : async Types.MetadataResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.metadata);
      }
    };
  };

  // Define a public function that queries and returns the NFT's max limit value:
  public query func getMaxLimitDip721() : async Nat16 {
    return maxLimit;
  };

  // Define a public function that returns the NFT's metadata for the current user:
  public func getMetadataForUserDip721(user: Principal) : async Types.ExtendedMetadataResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.owner == user });
    switch (item) {
      case null {
        return #Err(#Other);
      };
      case (?token) {
        return #Ok({
          metadata_desc = token.metadata;
          token_id = token.id;
        });
      }
    };
  };

  // Define a public function that queries and returns the token IDs owned by the current user:
  public query func getTokenIdsForUserDip721(user: Principal) : async [Types.TokenId] {
    let items = List.filter(nfts, func(token: Types.Nft) : Bool { token.owner == user });
    let tokenIds = List.map(items, func (item : Types.Nft) : Types.TokenId { item.id });
    return List.toArray(tokenIds);
  };

  // Define a public function that returns the list of the token IDs of the NFTs associated with operator
  public query func operatorTokenIdentifiersDip721(operator: Principal) : async Types.Result<List.List<Nat64>, Types.NftError> {
    // check if the operator is a valid principal
    if (Principal.equal(operator, null_address)) {
      return #Err(#InvalidOperator);
    } else {
      // Filter the NFTs associated with the operator
      let operatorNfts = List.filter(nfts, func (nft: Types.Nft) : Bool {
        // Check if the NFT is associated with the operator
        return Principal.equal(nft.owner, operator);
      });
      let tokenIds = List.map(operatorNfts, func (nft: Types.Nft) : Nat64 { nft.id });
      return #Ok(tokenIds);
    }
  };

  // Define a public function that returns the list of the token metadata of the NFTs associated with the owner
  public query func operatorTokenMetadataDip721(operator: Principal) : async Types.ExtendedMetadataNFTResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.owner == operator });
    switch (item) {
      case null {
        return #Err(#InvalidOperator);
      };
      case (?token) {
        return #Ok({
          metadata_desc = token.metadata;
          token_id = token.id;
        });
      }
    };
  };

  // Define a function to approve an operator for a specific token
  public shared({caller}) func approveDip721(operator: Principal, token_id: Types.TokenId) : async Types.Result<Nat, Types.NftError> {
    // Check if the caller is the owner of the token
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case (null) {
        // Token ID does not exist
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        if (token.owner != caller) {
          // Caller is not the owner of the token
          return #Err(#Unauthorized);
        };
        if (operator == caller) {
          // Self-approval is not allowed
          return #Err(#Other);
        };
        // Check if there's an existing approval and remove it
        approvals := List.filter(approvals, func (appr: (Types.TokenId, Principal)) : Bool {
          (appr.0 != token_id) or (appr.1 != operator)
        });
        // Add the new approval
        approvals := List.push((token_id, operator), approvals);
        // Increment transaction ID for the approval action
        transactionId += 1;
        return #Ok(transactionId);
      };
    };
  };

  // Define a function to set approval for all NFTs owned by the caller
  public shared({caller}) func setApprovalForAllDip721(operator: Principal, is_approved: Bool) : async Types.Result<Nat, Types.NftError> {
    if (operator == caller) {
      // Prevent self-approval
      return #Err(#Other);
    };
    
    // Check if there's an existing global approval for the caller and operator, and update or remove it
    let existingApproval = List.find(globalApprovals, func (appr: (Principal, Principal, Bool)) : Bool {
      appr.0 == caller and appr.1 == operator
    });

    switch (existingApproval) {
      case (null) {
        // If no existing approval is found and `is_approved` is true, add the new approval
        if (is_approved) {
          globalApprovals := List.push((caller, operator, is_approved), globalApprovals);
        };
      };
      case (?approval) {
        // If an existing approval is found, update or remove it based on `is_approved`
        globalApprovals := List.filter(globalApprovals, func (appr: (Principal, Principal, Bool)) : Bool {
          (appr.0 != caller or appr.1 != operator)
        });
        if (is_approved) {
          globalApprovals := List.push((caller, operator, is_approved), globalApprovals);
        };
      };
    };

    // Increment transaction ID for the approval action
    transactionId += 1;
    return #Ok(transactionId);
  };

  // Define a function to check if an operator is approved for all tokens owned by an owner
  public query func isApprovedForAll(owner: Principal, operator: Principal) : async Types.Result<Bool, Types.NftError> {
    // Search in globalApprovals if there is an entry that matches the owner and operator with a true approval
    let isApproved = List.some(globalApprovals, func (appr: (Principal, Principal, Bool)) : Bool {
      appr.0 == owner and appr.1 == operator and appr.2
    });

    return #Ok(isApproved);
  };


  // Define a public function that mints the NFT token:
  public shared({ caller }) func mintDip721(to: Principal, metadata: Types.MetadataDesc) : async Types.MintReceipt {
    let newId = Nat64.fromNat(List.size(nfts));

    let nft : Types.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
    };

    nfts := List.push(nft, nfts);

    transactionId += 1;

    return #Ok({
      token_id = newId;
      id = transactionId;
    });
  };

  // Update image URL for a specific NFT
  public shared({ caller }) func updateNftImageUrl(newImageUrl: Text) : async Types.TxReceipt {
    // Authorization check: Only allow certain principals to update the image URL
    if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Unauthorized);
    };

    // Function to update the image metadata for an NFT
    func image_metadata_update(key_val: Types.MetadataKeyVal) : Types.MetadataKeyVal {
      if (key_val.key != "image") {
        return key_val;
      } else {
        return {
          key = "image";
          val = #TextContent(newImageUrl)
        };
      };
    };
    
    // Update the imageUrl for all NFTs
    nfts := List.map(nfts, func (item : Types.Nft) : Types.Nft {
      let new_metadata = [{
        purpose = item.metadata[0].purpose;
        key_val_data = Array.map<Types.MetadataKeyVal, Types.MetadataKeyVal>(item.metadata[0].key_val_data, image_metadata_update);
        data = item.metadata[0].data;
      }];

      let update : Types.Nft = {
        owner = item.owner;
        id = item.id;
        metadata = new_metadata;
      };
      return update;
    });
  
    // Record this transaction with an ID or take other actions
    transactionId += 1;
    
    return #Ok(transactionId);
  };

  // Function to return the image URL of a specific NFT
  public query func getImageUrlOfNft(token_id: Types.TokenId) : async Types.Result<Types.MetadataVal, Types.ApiError> {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case (null) {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        let key_vals : [Types.MetadataKeyVal] = token.metadata[0].key_val_data;
        for (key_val in Iter.fromArray(key_vals)) {
          if (key_val.key == "image") {
            return #Ok(key_val.val); 
          }
        };
        return #Err(#Other);
      };
    };
  };
}
