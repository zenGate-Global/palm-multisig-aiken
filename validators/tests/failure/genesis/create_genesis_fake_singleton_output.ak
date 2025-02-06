use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, OutputReference, ScriptContext,
  Transaction, TransactionId,
}
use aiken/transaction/credential.{
  Address, ScriptCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{add, from_lovelace, to_minted_value, zero}
use palm_multisig/palm_multisig_validator.{palm_multisig_mint_validator}
use palm_multisig/tests/global_test_variables.{
  alice_address_hash, bob_address_hash, charlie_address_hash,
  dummy_token_asset_name, dummy_token_policy_id, multisig_contract_hash,
  multisig_singleton_name, one_ada, owner_address_hash,
}
use palm_multisig/types.{Genesis, MultisigDatum, MultisigRedeemer}
use sundae/multisig.{Signature}

//  Test for failure case of genesis creation due to fake singleton output
test create_genesis_fake_singleton_output() fail {
  let threshold_amount = 2
  let signatures =
    [
      Signature(alice_address_hash),
      Signature(bob_address_hash),
      Signature(charlie_address_hash),
    ]

  let owner_address =
    Address {
      payment_credential: VerificationKeyCredential(owner_address_hash),
      stake_credential: None,
    }

  let owner_input_output_ref =
    OutputReference {
      transaction_id: TransactionId(
        #"dcb9788326b92481d5bb0e1de8d85ecfec619947880c43d422aa0a672c79dc2c",
      ),
      output_index: 0,
    }

  let owner_input_utxo_details =
    Output {
      address: owner_address,
      value: from_lovelace(one_ada)
        |> add(dummy_token_policy_id, dummy_token_asset_name, 1),
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
        payment_credential: ScriptCredential(multisig_contract_hash),
        stake_credential: None,
      },
      value: from_lovelace(one_ada) // output does not get the singleton!!
        |> add(dummy_token_policy_id, dummy_token_asset_name, 1),
      datum: InlineDatum(multisig_output_datum_casted),
      reference_script: None,
    }

  let context =
    ScriptContext {
      purpose: Mint(multisig_contract_hash),
      transaction: transaction.placeholder()
        |> fn(transaction) {
            Transaction {
              ..transaction,
              inputs: [owner_input],
              outputs: [multisig_output],
              mint: zero()
                |> add(multisig_contract_hash, multisig_singleton_name, 1)
                |> to_minted_value(),
            }
          },
    }

  let redeemer =
    MultisigRedeemer { action: Genesis(threshold_amount, signatures) }

  palm_multisig_mint_validator(
    multisig_singleton_name,
    redeemer,
    context,
    owner_input_output_ref,
  )
}
