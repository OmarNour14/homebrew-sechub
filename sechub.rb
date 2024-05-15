class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/homebrew-sechub"  # Update with your actual project URL
    url "https://github.com/omarnour14/homebrew-sechub/archive/v.1.0.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "77146eb8dbad2747e4c9399ac9f26a161831828c1e61f68f856d656a0a5aea73"  # Generate this with `shasum -a 256 filename`
  
    def install
      bin.install "sechub"
    end
  
    test do
      system "#{bin}/sechub", "--help"  # Replace with a command that verifies installation
    end
  end
  