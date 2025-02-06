use aiken/dict
use aiken/list
use aiken/transaction.{
  Input, Mint, Output, OutputReference, ScriptContext, Spend, Transaction,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value.{AssetName, Value}
use palm_multisig/persistance.{valid_datum_recreation}
use palm_multisig/types.{Genesis, MultisigDatum, MultisigRedeemer}
use palm_multisig/utils.{filter_outputs_by_token, get_inline_datum}
use sundae/multisig.{AtLeast, satisfied}

pub fn palm_multisig_validator(
  multisig_singleton_name: AssetName,
  datum: MultisigDatum,
  redeemer: MultisigRedeemer,
  ctx: ScriptContext,
) -> Bool {
  when ctx.purpose is {
    Spend(my_output_reference) -> and {
        satisfied(
          AtLeast {
            required: datum.threshold_amount,
            scripts: datum.signatures,
          },
          ctx.transaction.extra_signatories,
          ctx.transaction.validity_range,
          ctx.transaction.withdrawals,
        )?,
        valid_multisig_change(
          multisig_singleton_name,
          datum,
          redeemer,
          my_output_reference,
          ctx,
        )?,
      }
    _ -> False
  }
}

pub fn palm_multisig_mint_validator(
  multisig_singleton_name: AssetName,
  redeemer: MultisigRedeemer,
  ctx: ScriptContext,
  utxo_ref: OutputReference,
) -> Bool {
  when ctx.purpose is {
    Mint(self_policy_id) -> {
      let Transaction { inputs, mint, .. } = ctx.transaction

      let mint = value.from_minted_value(mint)

      when redeemer.action is {
        Genesis(threshold_amount, signatures) -> {
          expect
            list.any(inputs, fn(input) { input.output_reference == utxo_ref })

          expect [output]: List<Output> =
            ctx.transaction.outputs
              |> transaction.find_script_outputs(self_policy_id)

          expect [_] =
            filter_outputs_by_token(
              [output],
              self_policy_id,
              multisig_singleton_name,
            )

          expect [Pair(minted_asset_name, amount)] =
            mint
              |> value.tokens(self_policy_id)
              |> dict.to_pairs()

          expect MultisigDatum {
            threshold_amount: initial_threshold_amount,
            signatures: initial_signatures,
          }: MultisigDatum = get_inline_datum(output.datum)

          let output_tokens: Value = value.without_lovelace(output.value)

          let one_token_in_output =
            list.length(value.flatten(output_tokens)) == 1

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
    _ -> False
  }
}

fn valid_multisig_change(
  multisig_singleton_name: AssetName,
  datum: MultisigDatum,
  redeemer: MultisigRedeemer,
  my_output_reference: OutputReference,
  ctx: ScriptContext,
) -> Bool {
  //Find the input guarded by this validator
  expect Some(self) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  expect ScriptCredential(self_script) = self.output.address.payment_credential
  let self_tokens: Value = value.without_lovelace(self.output.value)

  expect [Pair(multisig_singleton_policy_id, _)] =
    self_tokens
      |> value.to_dict()
      |> dict.to_pairs()

  expect [recreated_self_box]: List<Output> =
    ctx.transaction.outputs
      |> transaction.find_script_outputs(self_script)

  let recreated_self_box_singleton_amount: Int =
    value.quantity_of(
      recreated_self_box.value,
      multisig_singleton_policy_id,
      multisig_singleton_name,
    )

  let recreated_self_box_tokens: Value =
    value.without_lovelace(recreated_self_box.value)

  let exactly_one_token_in_recreated_self =
    list.length(value.flatten(recreated_self_box_tokens)) == 1
  let valid_singleton_transfer = recreated_self_box_singleton_amount == 1

  and {
    valid_singleton_transfer?,
    exactly_one_token_in_recreated_self?,
    valid_datum_recreation(datum, recreated_self_box, redeemer)?,
  }
}
