module JsonTest (tests) where

import Harness
import Ideonomy.Json

tests :: [Test]
tests =
  [ test "round trip keeps key order and integers" $ do
      let v = Object [("b", Int 1), ("a", Array [Double 0.5, String "x\"y\n", Null, Bool True])]
      assertEq "render" "{\"b\":1,\"a\":[0.5,\"x\\\"y\\n\",null,true]}" (render v)
  , test "parse rejects trailing garbage" $ assertLeft "trailing" (parse "{} x")
  , test "parse handles unicode escapes and surrogates" $
      assertEq "surrogate" (Right (String "\128512é")) (parse "\"\\ud83d\\ude00\\u00e9\"")
  , test "indent matches python layout" $
      assertEq "indent" "{\n \"a\": [\n  1,\n  2\n ],\n \"b\": {}\n}" (renderIndent 1 (Object [("a", Array [Int 1, Int 2]), ("b", Object [])]))
  , test "doubles print like python repr" $ do
      let cases = [(0.05, "0.05"), (1.0, "1.0"), (1e-5, "1e-05"), (1.5e16, "1.5e+16"), (123.456, "123.456")]
      assertEq "doubles" (map snd cases) [render (Double d) | (d, _) <- cases]
  , test "sortKeys is recursive" $
      assertEq "sorted" "{\"a\":{\"x\":1,\"y\":2},\"b\":0}" (renderSorted (Object [("b", Int 0), ("a", Object [("y", Int 2), ("x", Int 1)])]))
  ]
