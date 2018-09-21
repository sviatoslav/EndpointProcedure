#
# Be sure to run `pod lib lint EndpointProcedure.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EndpointProcedure'
  s.version          = '0.1.0'
  s.summary          = 'Typesafe flexible networking framework based on ProcedureKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
EndpointProcedure connects your API with application model.
                       DESC

  s.homepage         = 'https://github.com/sviatoslav/EndpointProcedure'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sviatoslav Yakymiv' => 'sviatoslav.yakymiv@gmail.com' }
  s.source           = { :git => 'https://github.com/sviatoslav/EndpointProcedure.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/iakymiv'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/Core/**/*'

  # Ensure the correct version of Swift is used
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }

  # Defaul spec is 'Core'
  s.default_subspec   = 'Core'

  # s.resource_bundles = {
  #   'EndpointProcedure' => ['EndpointProcedure/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ProcedureKit', '4.0.0.beta.6'
end
