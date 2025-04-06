use cardano/address.{Address, Credential, Script}
use cardano/assets.{add, from_lovelace, zero}
use cardano/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
}
use palm_multisig/palm_multisig_validator.{palm_multisig_mint_validator}
use palm_multisig/tests/global_test_variables.{
  alice_address_hash, bob_address_hash, charlie_address_hash,
  multisig_contract_hash, multisig_singleton_name, one_ada, owner_address_hash,
}
use palm_multisig/types.{Genesis, MultisigDatum, MultisigRedeemer}
use sundae/multisig.{Signature}

// Test for failure case of genesis creation with wrong threshold
test create_genesis_wrong_threshold() fail {
  let threshold_amount = 2
  let signatures =
    [
      Signature(alice_address_hash),
      Signature(bob_address_hash),
      Signature(charlie_address_hash),
    ]

  let owner_address =
    Address {
      payment_credential: Credential.VerificationKey(owner_address_hash),
      stake_credential: None,
    }

  let owner_input_output_ref =
    OutputReference {
      transaction_id: #"dcb9788326b92481d5bb0e1de8d85ecfec619947880c43d422aa0a672c79dc2c",
      output_index: 0,
    }

  let owner_input_utxo_details =
    Output {
      address: owner_address,
      value: from_lovelace(one_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let owner_input =
    Input {
      output_reference: owner_input_output_ref,
      output: owner_input_utxo_details,
    }

  let multisig_output_datum = MultisigDatum { signatures, threshold_amount }

  let multisig_output_datum_casted: Data = multisig_output_datum

  let multisig_output =
    Output {
      address: Address {
        payment_credential: Script(multisig_contract_hash),
        stake_credential: None,
      },
      value: from_lovelace(one_ada)
        |> add(multisig_contract_hash, multisig_singleton_name, 1),
      datum: InlineDatum(multisig_output_datum_casted),
      reference_script: None,
    }

  let tx =
    transaction.placeholder
      |> fn(transaction) {
          Transaction {
            ..transaction,
            inputs: [owner_input],
            outputs: [multisig_output],
            mint: zero
              |> add(multisig_contract_hash, multisig_singleton_name, 1),
          }
        }

  let redeemer =
    MultisigRedeemer {
      // does not match the threshold amount in redeemer
      action: Genesis(threshold_amount + 1, signatures),
    }

  palm_multisig_mint_validator(
    multisig_singleton_name,
    redeemer,
    tx,
    multisig_contract_hash,
    owner_input_output_ref,
  )
}
