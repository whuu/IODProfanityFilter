Pod::Spec.new do |s|
  s.name = "IODProfanityFilter"
  s.version = "1.0.0"
  s.summary = "Basic profanity filter library for iOS and Mac OS X apps. Based on https://github.com/IslandOfDoom/IODProfanityFilter."
  s.homepage = "https://github.com/whuu/IODProfanityFilter.git"
  s.license = 'MIT'
  s.author = { "Island of Doom Software Inc." => "overlord@islandofdoom.com", "whuu" => "whuu@gazeta.pl" }
  s.source = { :git => "https://github.com/whuu/IODProfanityFilter.git", :branch => "develop" }
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.source_files = 'IODProfanityFilter/Classes', 'IODProfanityFilter/Classes/**/*.{h,m}'
  s.resources = "IODProfanityFilter/Resources/*"
  s.requires_arc = true
end