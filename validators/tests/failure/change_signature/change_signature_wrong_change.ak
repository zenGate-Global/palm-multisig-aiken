use cardano/address.{Address, Script}
use cardano/assets.{add, from_lovelace, zero}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use palm_multisig/palm_multisig_validator.{palm_multisig_validator}
use palm_multisig/tests/global_test_variables.{
  alice_address_hash, bob_address_hash, charlie_address_hash,
  multisig_contract_hash, multisig_singleton_name, one_ada,
}
use palm_multisig/types.{ChangeSignatures, MultisigDatum, MultisigRedeemer}
use sundae/multisig.{Signature}

// Test for failure case of multisig changing signatures but threshold is being changed instead
test change_signatures_wrong_change() fail {
  let existing_threshold_amount = 2
  let signatures =
    [
      Signature(alice_address_hash),
      Signature(bob_address_hash),
      Signature(charlie_address_hash),
    ]

  let new_threshold_amount = 3

  let multisig_input_datum =
    MultisigDatum { signatures, threshold_amount: existing_threshold_amount }

  let multisig_input_datum_casted: Data = multisig_input_datum

  let multisig_input_utxo_details =
    Output {
      address: Address {
        payment_credential: Script(multisig_contract_hash),
        stake_credential: None,
      },
      value: from_lovelace(one_ada)
        |> add(multisig_contract_hash, multisig_singleton_name, 1),
      datum: InlineDatum(multisig_input_datum_casted),
      reference_script: None,
    }

  let multisig_input_output_ref =
    OutputReference {
      transaction_id: #"dcb9788326b92481d5bb0e1de8d85ecfec619947880c43d422aa0a672c79dc2c",
      output_index: 1,
    }

  let multisig_input =
    Input {
      output_reference: multisig_input_output_ref,
      output: multisig_input_utxo_details,
    }

  let multisig_output_datum =
    MultisigDatum { signatures, threshold_amount: new_threshold_amount }

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
            inputs: [multisig_input],
            outputs: [multisig_output],
            extra_signatories: [
              bob_address_hash, charlie_address_hash, alice_address_hash,
            ],
            mint: zero,
          }
        }

  let redeemer = MultisigRedeemer { action: ChangeSignatures }

  palm_multisig_validator(
    multisig_singleton_name,
    multisig_input_datum,
    redeemer,
    tx,
    multisig_input.output_reference,
  )
}
