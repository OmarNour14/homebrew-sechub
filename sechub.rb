class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/homebrew-sechub"  # Update with your actual project URL
    url "https://github.com/OmarNour14/homebrew-sechub/archive/refs/tags/v1.5.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "5600859c0718dd4dc9664fa4ec406caa23d69c5722bce6668089a1fc94c08f9d"  # Generate this with `shasum -a 256 filename`
  
    def install
        bin.install "./sechub.sh" => "sechub"
      end
  
    test do
      system "#{bin}/sechub", "--help"  # Replace with a command that verifies installation
    end
  end
  