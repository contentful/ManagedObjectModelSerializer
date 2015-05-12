Pod::Spec.new do |s|
  s.name         = "ManagedObjectModelSerializer"
  s.version      = "0.1"
  s.summary      = "A framework for serializing an in-memory `NSManagedObjectModel`."
  s.homepage     = "https://github.com/contentful/ManagedObjectModelSerializer"
  s.license      = "MIT"

  s.authors          = { "Boris Bügling" => "boris@buegling.com" }
  s.social_media_url = 'https://twitter.com/contentful'
  s.source = { :git => "https://github.com/contentful/ManagedObjectModelSerializer.git",
               :tag => s.version }

  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.9'

  s.source_files = "Code/{EntitySerializer,ModelSerializer,XMLTools}.swift"
  s.requires_arc = true

  s.dependency 'ECoXiS'
  s.dependency 'SwiftShell'
end
