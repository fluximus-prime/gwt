import gleeunit
import gleeunit/should
import gleam/dynamic
import gwt
import birl

const signing_secret = "gleam"

pub fn main() {
  gleeunit.main()
}

pub fn encode_decode_unsigned_jwt_test() {
  let jwt_string =
    gwt.new()
    |> gwt.set_subject("1234567890")
    |> gwt.set_audience("0987654321")
    |> gwt.set_not_before(1_704_043_160)
    |> gwt.set_expiration(1_704_046_160)
    |> gwt.set_jwt_id("2468")
    |> gwt.to_string()

  let maybe_jwt = gwt.from_string(jwt_string)

  maybe_jwt
  |> should.be_ok()

  let assert Ok(jwt) = gwt.from_string(jwt_string)

  gwt.get_subject(jwt)
  |> should.equal(Ok("1234567890"))

  jwt
  |> gwt.get_payload_claim("aud", dynamic.string)
  |> should.equal(Ok("0987654321"))

  jwt
  |> gwt.get_payload_claim("iss", dynamic.string)
  |> should.equal(Error(Nil))
}

pub fn encode_decode_signed_jwt_test() {
  let jwt_string =
    gwt.new()
    |> gwt.set_subject("1234567890")
    |> gwt.set_audience("0987654321")
    |> gwt.to_signed_string(gwt.HS256, signing_secret)

  gwt.from_signed_string(jwt_string, "bad secret")
  |> should.be_error

  gwt.from_signed_string(jwt_string, "bad secret")
  |> should.equal(Error(gwt.InvalidSignature))

  let maybe_jwt = gwt.from_signed_string(jwt_string, signing_secret)
  maybe_jwt
  |> should.be_ok()

  let assert Ok(jwt) = gwt.from_signed_string(jwt_string, signing_secret)

  gwt.get_subject(jwt)
  |> should.equal(Ok("1234567890"))

  jwt
  |> gwt.get_payload_claim("aud", dynamic.string)
  |> should.equal(Ok("0987654321"))

  jwt
  |> gwt.get_payload_claim("iss", dynamic.string)
  |> should.equal(Error(Nil))
}

pub fn exp_jwt_test() {
  gwt.new()
  |> gwt.set_subject("1234567890")
  |> gwt.set_audience("0987654321")
  |> gwt.set_expiration(
    {
      birl.now()
      |> birl.to_unix()
    }
    + 100_000,
  )
  |> gwt.to_signed_string(gwt.HS256, signing_secret)
  |> gwt.from_signed_string(signing_secret)
  |> should.be_ok()

  gwt.new()
  |> gwt.set_subject("1234567890")
  |> gwt.set_audience("0987654321")
  |> gwt.set_expiration(0)
  |> gwt.to_signed_string(gwt.HS256, signing_secret)
  |> gwt.from_signed_string(signing_secret)
  |> should.equal(Error(gwt.TokenExpired))
}

pub fn nbf_jwt_test() {
  gwt.new()
  |> gwt.set_subject("1234567890")
  |> gwt.set_audience("0987654321")
  |> gwt.set_not_before(
    {
      birl.now()
      |> birl.to_unix()
    }
    + 100_000,
  )
  |> gwt.to_signed_string(gwt.HS256, signing_secret)
  |> gwt.from_signed_string(signing_secret)
  |> should.equal(Error(gwt.TokenNotValidYet))

  gwt.new()
  |> gwt.set_subject("1234567890")
  |> gwt.set_audience("0987654321")
  |> gwt.set_not_before(0)
  |> gwt.to_signed_string(gwt.HS256, signing_secret)
  |> gwt.from_signed_string(signing_secret)
  |> should.be_ok()
}
