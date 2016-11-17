#
# Be sure to run `pod lib lint RNSync.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = "rnsync"
    s.version          = "1.0.0"
    s.summary          = "A React Native compatible version of Cloudant Sync"

    s.homepage         = "https://github.com/pwcremin/RNSync"

    s.license          = 'MIT'
    s.author           = { "Patrick Cremin" => "pwcremin@gmail.com" }
    s.platform     = :ios, '7.0'

    s.source           = { :git => "https://github.com/pwcremin/RNSync.git", :tag => s.version.to_s }

    s.source_files = 'RNSync/**'
    s.public_header_files = 'RNSync/**/*.h'

    s.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/../../node_modules/react-native/React/**" ' }
    #s.requires_arc = true

    s.dependency 'CDTDatastore'
end
