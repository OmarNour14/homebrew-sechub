class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/homebrew-sechub"  # Update with your actual project URL
    url "https://github.com/OmarNour14/homebrew-sechub/archive/refs/tags/v1.0.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "f95cf5e45c6af4de2371bf49c7b975ddf4ed11a4e6ab08084cbeab03c979b07a"  # Generate this with `shasum -a 256 filename`
  
    def install
        bin.install "./sechub.sh" => "sechub"
      end
  
    test do
      system "#{bin}/sechub", "--help"  # Replace with a command that verifies installation
    end
  end
  