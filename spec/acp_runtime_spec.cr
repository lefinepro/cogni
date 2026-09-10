require "./spec_helper"

describe Ocawe::Workflow::ACPRuntime do
  it "keeps object configuration unchanged" do
    config = JSON.parse({"command" => "codex-acp", "args" => ["--stdio"]}.to_json)

    Ocawe::Workflow::ACPRuntime.normalize(config).to_json.should eq(config.to_json)
  end

  it "accepts a command shorthand for any ACP agent" do
    config = Ocawe::Workflow::ACPRuntime.normalize(JSON.parse("claude-code-acp".to_json))

    config["command"].as_s.should eq("claude-code-acp")
  end

  it "accepts the enabled shorthand" do
    config = Ocawe::Workflow::ACPRuntime.normalize(JSON.parse("true"))

    config.as_h.should be_empty
  end

  it "rejects unsupported scalar configuration" do
    expect_raises(Exception) do
      Ocawe::Workflow::ACPRuntime.normalize(JSON.parse("42"))
    end
  end

  it "allows a Cawfile to use the exec reference as the ACP command" do
    workflow = Ocawe::Workflow.create_workflow("native-acp-runtime", "native ACP runtime")

    workflow.exec("codex-acp", runtime: {"acp" => true}).commit
  end
end
