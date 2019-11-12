
Pod::Spec.new do |s|
  s.name         = "RNCustomCrop"
  s.version      = "1.0.0"
  s.summary      = "RNCustomCrop"
  s.description  = <<-DESC
                  RNCustomCrop
                   DESC
  s.homepage     = "https://github.com/Michaelvilleneuve/react-native-perspective-image-cropper"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/author/RNCustomCrop.git", :tag => "master" }
  s.source_files  = "RNCustomCrop/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  