#
#  Be sure to run `pod spec lint JZLocationConverter-Swift.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "JZLocationConverterSwift"
  s.version      = "1.0.0"
  s.summary      = "WGS-84世界标准坐标、GCJ-02中国国测局(火星坐标)、BD-09百度坐标系转换"

  s.homepage     = "https://github.com/JackZhouCn/JZLocationConverter-Swift"

  s.license      = "MIT"

  s.author    = "JackZhouCn"
  s.social_media_url   = "https://twitter.com/JackZhou__"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/JackZhouCn/JZLocationConverter-Swift.git", :tag => "1.0.0" }

  s.source_files  = "JZLocationConverterDemo/JZLocationConverter/**/*.swift"


  s.resource  = "JZLocationConverterDemo/JZLocationConverter/GCJ02.json"


end
