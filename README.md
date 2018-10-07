# EndpointProcedure


[![CI Status](https://img.shields.io/travis/sviatoslav/EndpointProcedure.svg?style=for-the-badge)](https://travis-ci.org/sviatoslav/EndpointProcedure)
[![Swift](https://img.shields.io/badge/Swift-4.2-orange.svg?style=for-the-badge)](https://swift.org)
[![License](https://img.shields.io/github/license/sviatoslav/EndpointProcedure.svg?style=for-the-badge)](https://github.com/sviatoslav/EndpointProcedure/blob/master/LICENSE)
[![Coverage](https://img.shields.io/codecov/c/github/sviatoslav/EndpointProcedure.svg?style=for-the-badge)](https://codecov.io/gh/sviatoslav/EndpointProcedure)

<!--
[![Version](https://img.shields.io/cocoapods/v/EndpointProcedure.svg?style=flat)](http://cocoapods.org/pods/EndpointProcedure)
[
[![Platform](https://img.shields.io/cocoapods/p/EndpointProcedure.svg?style=flat)](http://cocoapods.org/pods/EndpointProcedure)-->

`EndpointProcedure` is flexible typesafe bridge between network and application model.
 It's based on [`ProcedureKit`](https://github.com/procedurekit/procedurekit) framework.

 `EndpointProcedure` itself does not perform any requests and does not parse the response, it chains procedures and transfers output of one procedure to the next one and uses output of last procedure as own output.

 Data flow looks as follows:

 Loading -> Validation -> Deserialization -> Interception -> Mapping
 - Loading: loads `HTTPResponseData` from any source.
 - Validation: validates `HTTPResponseData`
 - Deserialization: converts loaded `Data` to `Any`
 - Interception: converts deserialized object to format expected by mapping
 - Mapping: Converts `Any` to `Result`

<!--## Requirements-->

<!--## Installation

EndpointProcedure is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "EndpointProcedure"
```-->
<!--
## Author

Sviatoslav Yakymiv, sviatoslav.yakymiv@gmail.com-->

## License

EndpointProcedure is available under the MIT license. See the LICENSE file for more info.
