class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/homebrew-sechub"  # Update with your actual project URL
    url "https://github.com/OmarNour14/homebrew-sechub/archive/refs/tags/v1.0.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "2476f3d3144bf2781262d5af2f4f1dcb52bf4fabde98b13248f11ae1d59c7340"  # Generate this with `shasum -a 256 filename`
  
    def install
        bin.install "homebrew-sechub-1.0.0/sechub.sh" => "sechub"
      end
  
    test do
      system "#{bin}/sechub", "--help"  # Replace with a command that verifies installation
    end
  end
  