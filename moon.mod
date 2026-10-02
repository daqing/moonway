// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "daqing/moonway"

version = "0.11.6"

readme = "README.mbt.md"

repository = "https://github.com/daqing/moonway"

license = "MIT"

keywords = [ "web", "framework", "fullstack" ]

preferred_target = "native"

description = "A full-stack web framework for MoonBit"

import {
  "moonbitlang/async@0.22.4",
  "mizchi/sqlite@0.3.1",
  "moonbitlang/x@0.5.5",
}
