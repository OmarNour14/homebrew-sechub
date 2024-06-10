class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/homebrew-sechub"  # Update with your actual project URL
    url "https://github.com/OmarNour14/homebrew-sechub/archive/refs/tags/v1.4.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "7f430c64e22422e1bb440978a0b5b476ecdce5ee73874563f74a07f3466edaae"  # Generate this with `shasum -a 256 filename`
  
    def install
        bin.install "./sechub.sh" => "sechub"
      end
  
    test do
      system "#{bin}/sechub", "--help"  # Replace with a command that verifies installation
    end
  end
  