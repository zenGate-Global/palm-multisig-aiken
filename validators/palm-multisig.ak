use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use palm_multisig/palm_multisig_validator.{
  palm_multisig_mint_validator, palm_multisig_validator,
}
use palm_multisig/types.{MultisigDatum, MultisigRedeemer}

// Main emissions contract entry point
validator palm_multisig(
  multisig_singleton_name: AssetName,
  utxo_ref: OutputReference,
) {
  spend(
    datum_opt: Option<MultisigDatum>,
    redeemer: MultisigRedeemer,
    output_ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt
    palm_multisig_validator(
      multisig_singleton_name,
      datum,
      redeemer,
      tx,
      output_ref,
    )
  }

  mint(redeemer: MultisigRedeemer, policy_id: PolicyId, tx: Transaction) {
    palm_multisig_mint_validator(
      multisig_singleton_name,
      redeemer,
      tx,
      policy_id,
      utxo_ref,
    )
  }

  else(_) {
    fail
  }
}
