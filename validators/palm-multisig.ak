use aiken/transaction.{OutputReference, ScriptContext}
use aiken/transaction/value.{AssetName}
use palm_multisig/palm_multisig_validator.{
  palm_multisig_mint_validator, palm_multisig_validator,
}
use palm_multisig/types.{MultisigDatum, MultisigRedeemer}

// Main emissions contract entry point
validator(multisig_singleton_name: AssetName, utxo_ref: OutputReference) {
  pub fn palm_multisig(
    datum: MultisigDatum,
    redeemer: MultisigRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    palm_multisig_validator(multisig_singleton_name, datum, redeemer, ctx)
  }

  pub fn palm_multisig_mint(
    redeemer: MultisigRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    palm_multisig_mint_validator(
      multisig_singleton_name,
      redeemer,
      ctx,
      utxo_ref,
    )
  }
}
