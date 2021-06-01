use "ponytest"
use "../velle"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_StubTest)

  fun @runtime_override_defaults(rto: RuntimeOptions) =>
    rto.ponynoblock = true

class _StubTest is UnitTest
  fun name(): String =>
    "some tests are needed"

   fun apply(h: TestHelper) =>
    h.assert_true(true)
