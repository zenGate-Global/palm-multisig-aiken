use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{AssetName, PolicyId, Value}
use cardano/transaction.{Input, Output, OutputReference, Transaction}
use palm_multisig/persistance.{valid_datum_recreation}
use palm_multisig/types.{Genesis, MultisigDatum, MultisigRedeemer}
use palm_multisig/utils.{filter_outputs_by_token, get_inline_datum}
use sundae/multisig.{AtLeast, satisfied}

pub fn palm_multisig_validator(
  multisig_singleton_name: AssetName,
  datum: MultisigDatum,
  redeemer: MultisigRedeemer,
  tx: Transaction,
  my_output_reference: OutputReference,
) -> Bool {
  and {
    satisfied(
      AtLeast { required: datum.threshold_amount, scripts: datum.signatures },
      tx.extra_signatories,
      tx.validity_range,
      tx.withdrawals,
    )?,
    valid_multisig_change(
      multisig_singleton_name,
      datum,
      redeemer,
      my_output_reference,
      tx,
    )?,
  }
}

pub fn palm_multisig_mint_validator(
  multisig_singleton_name: AssetName,
  redeemer: MultisigRedeemer,
  tx: Transaction,
  self_policy_id: PolicyId,
  utxo_ref: OutputReference,
) -> Bool {
  let Transaction { inputs, mint, .. } = tx

  when redeemer.action is {
    Genesis(threshold_amount, signatures) -> {
      expect list.any(inputs, fn(input) { input.output_reference == utxo_ref })

      expect [output]: List<Output> =
        tx.outputs
          |> transaction.find_script_outputs(self_policy_id)

      expect [_] =
        filter_outputs_by_token(
          [output],
          self_policy_id,
          multisig_singleton_name,
        )

      expect [Pair(minted_asset_name, amount)] =
        mint
          |> assets.tokens(self_policy_id)
          |> dict.to_pairs()

      expect MultisigDatum {
        threshold_amount: initial_threshold_amount,
        signatures: initial_signatures,
      }: MultisigDatum = get_inline_datum(output.datum)

      let output_tokens: Value = assets.without_lovelace(output.value)

      let one_token_in_output = list.length(assets.flatten(output_tokens)) == 1

      let one_token_minted = amount == 1

      and {
        one_token_in_output?,
        one_token_minted?,
        (minted_asset_name == multisig_singleton_name)?,
        (initial_threshold_amount == threshold_amount)?,
        (initial_signatures == signatures)?,
      }
    }

    _ -> False
  }
}

fn valid_multisig_change(
  multisig_singleton_name: AssetName,
  datum: MultisigDatum,
  redeemer: MultisigRedeemer,
  my_output_reference: OutputReference,
  tx: Transaction,
) -> Bool {
  //Find the input guarded by this validator
  expect Some(self) =
    tx.inputs
      |> transaction.find_input(my_output_reference)

  expect Script(self_script) = self.output.address.payment_credential
  let self_tokens: Value = assets.without_lovelace(self.output.value)

  expect [Pair(multisig_singleton_policy_id, _)] =
    self_tokens
      |> assets.to_dict()
      |> dict.to_pairs()

  expect [recreated_self_box]: List<Output> =
    tx.outputs
      |> transaction.find_script_outputs(self_script)

  let recreated_self_box_singleton_amount: Int =
    assets.quantity_of(
      recreated_self_box.value,
      multisig_singleton_policy_id,
      multisig_singleton_name,
    )

  let recreated_self_box_tokens: Value =
    assets.without_lovelace(recreated_self_box.value)

  let exactly_one_token_in_recreated_self =
    list.length(assets.flatten(recreated_self_box_tokens)) == 1
  let valid_singleton_transfer = recreated_self_box_singleton_amount == 1

  and {
    valid_singleton_transfer?,
    exactly_one_token_in_recreated_self?,
    valid_datum_recreation(datum, recreated_self_box, redeemer)?,
  }
}
