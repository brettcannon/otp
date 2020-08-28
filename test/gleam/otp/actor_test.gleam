import gleam/otp/actor.{Continue}
import gleam/otp/process.{Pid}
import gleam/otp/system
import gleam/dynamic.{Dynamic}
import gleam/should
import gleam/result

pub fn get_state_test() {
  assert Ok(channel) =
    actor.new("Test state", fn(_msg, state) { Continue(state) })

  channel
  |> process.pid
  |> system.get_state
  |> should.equal(dynamic.from("Test state"))
}

external fn get_status(Pid) -> Dynamic =
  "sys" "get_status"

pub fn get_status_test() {
  assert Ok(channel) = actor.new(Nil, fn(_msg, state) { Continue(state) })

  channel
  |> process.pid
  |> get_status
  // TODO: assert something about the response
}

pub fn failed_init_test() {
  actor.Spec(
    init: fn() { Error(process.Normal) },
    loop: fn(_msg, state) { Continue(state) },
    init_timeout: 10,
  )
  |> actor.start
  |> result.is_error
  |> should.be_true
}

pub fn suspend_resume_test() {
  assert Ok(channel) =
    actor.new("Test state", fn(_msg, state) { Continue(state) })

  // Suspend process
  channel
  |> process.pid
  |> system.suspend
  |> should.equal(Nil)

  // System messages are still handled
  channel
  |> process.pid
  |> system.get_state
  |> should.equal(dynamic.from("Test state"))

  // TODO: test normal messages are not handled.
  // Resume process
  channel
  |> process.pid
  |> system.resume
  |> should.equal(Nil)
}

pub fn channel_test() {
  assert Ok(channel) = actor.new("state 1", fn(msg, _state) { Continue(msg) })

  channel
  |> process.pid
  |> system.get_state()
  |> should.equal(dynamic.from("state 1"))

  actor.send(channel, "state 2")

  channel
  |> process.pid
  |> system.get_state()
  |> should.equal(dynamic.from("state 2"))
}
