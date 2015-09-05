Pod::Spec.new do |s|
  s.name = 'KeePassKit'
  s.version = '0.1.0'
  s.license = 'GPLv3'
  s.summary = 'KeePass Database loading, storing and manipulation framework'
  s.homepage = 'https://github.com/mstarke/KeePassKit'
  s.authors = 'Michael Starke'
  s.source = { :git => 'https://github.com/mstarke/KeePassKit.git', :tag => s.version }

  s.ios.deployment_target = '7.0'

  s.source_files = '**/*.{h,m}'
  s.private_header_files = 'Categories/NSData+CommonCrypto.h', 'Utilites/KPKXmlUtilities.h'

  s.requires_arc = true
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }

  s.library = 'z'
  s.dependency 'KissXML'
end
