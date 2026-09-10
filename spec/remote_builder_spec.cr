require "spec"
require "../src/cli/remote_builder"

class RemoteBuilderProbe < OcaweCore::CLI::RemoteBuilder
  def script : String
    remote_script
  end
end

describe OcaweCore::CLI::RemoteBuilder do
  it "keeps remote deploys locked and addon-source aware" do
    script = RemoteBuilderProbe.new(Dir.current).script

    script.should contain("lock_file=\"/tmp/ocawe-${service}-${hash}.lock\"")
    script.should contain("addon_manifest=\"/var/lib/rancher/k3s/server/manifests/ocawe-${service}.yaml\"")
    script.should contain("run_privileged env SERVICE=\"$service\" IMAGE=\"$image\" perl -0pi -e")
    script.should contain("run_privileged install -m 0644 \"$addon_tmp\" \"$addon_manifest\"")
    script.should contain("\"${kubectl_cmd[@]}\" \"${kubectl_args[@]}\" apply -f \"$addon_manifest\"")
    script.should contain("start_mode=\"${10}\"")
    script.should contain("s{(^[ ]{8}- args:)")
  end

  it "accepts a workflow path selector for a remote dry run" do
    options = OcaweCore::CLI::RemoteBuilder::Options.new(
      host: "fake-host",
      dry_run: true,
    )

    OcaweCore::CLI::RemoteBuilder.new(Dir.current).build("caws/01-simple", options).should be_true
  end
end
