
Pod::Spec.new do |s|
  s.name         = "RNStompWS"
  s.version      = "1.0.0"
  s.summary      = "RNStompWS"
  s.description  = <<-DESC
                  RNStompWS
                   DESC
  s.homepage     = "https://github.com/creamcookie/react-native-stomp-websocket"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/creamcookie/react-native-stomp-websocket.git", :tag => "master" }
  s.source_files  = "**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

