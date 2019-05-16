require "json"

package = JSON.parse(File.read(File.join(__dir__, "../package.json")))

Pod::Spec.new do |s|
  s.name         = "RNCustomCrop"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.author       = { "author" => package["author"] }
  s.platform     = :ios, "7.0"
  s.source       = { :git => package.dig(:repository, :url), :tag => "master" }
  s.source_files = "CustomCropManager.{h,m,mm}"
  s.requires_arc = true

  s.dependency "React"
end
