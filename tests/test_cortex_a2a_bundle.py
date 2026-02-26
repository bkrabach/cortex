"""Tests for bundles/cortex-a2a.md — dedicated A2A session bundle for autonomous agent-to-agent responder."""

import pathlib
import re

import pytest
import yaml

REPO_ROOT = pathlib.Path(__file__).parent.parent
BUNDLES_DIR = REPO_ROOT / "bundles"
CORTEX_A2A_FILE = BUNDLES_DIR / "cortex-a2a.md"


@pytest.fixture
def raw_content():
    """Load the raw file content."""
    return CORTEX_A2A_FILE.read_text()


@pytest.fixture
def frontmatter(raw_content):
    """Extract and parse YAML frontmatter from the bundle file."""
    match = re.match(r"^---\n(.*?)\n---", raw_content, re.DOTALL)
    assert match, "File must have YAML frontmatter delimited by ---"
    return yaml.safe_load(match.group(1))


@pytest.fixture
def body(raw_content):
    """Extract markdown body (after frontmatter)."""
    match = re.match(r"^---\n.*?\n---\n(.*)", raw_content, re.DOTALL)
    assert match, "File must have content after frontmatter"
    return match.group(1)


@pytest.fixture
def lower_body(body):
    """Lower-cased body for case-insensitive checks."""
    return body.lower()


# ── Directory and File Existence ──────────────────────────────────────────


class TestFileExists:
    def test_bundles_directory_exists(self):
        assert BUNDLES_DIR.is_dir(), "bundles/ directory must exist"

    def test_cortex_a2a_file_exists(self):
        assert CORTEX_A2A_FILE.is_file(), "bundles/cortex-a2a.md must exist"


# ── YAML Frontmatter: Bundle Identity ────────────────────────────────────


class TestBundleIdentity:
    def test_bundle_name(self, frontmatter):
        assert frontmatter["bundle"]["name"] == "cortex-a2a"

    def test_bundle_version(self, frontmatter):
        assert frontmatter["bundle"]["version"] == "1.0.0"


# ── YAML Frontmatter: Includes ───────────────────────────────────────────


class TestIncludes:
    def test_has_includes(self, frontmatter):
        assert "includes" in frontmatter, "Must have includes section"

    def test_includes_foundation(self, raw_content):
        assert "amplifier-foundation" in raw_content

    def test_includes_a2a_behavior(self, raw_content):
        assert (
            "git+https://github.com/microsoft/amplifier-bundle-a2a@main" in raw_content
        )
        assert "behaviors/a2a.yaml" in raw_content


# ── YAML Frontmatter: Session Config ─────────────────────────────────────


class TestSessionConfig:
    def test_has_session(self, frontmatter):
        assert "session" in frontmatter

    def test_orchestrator_loop_streaming(self, frontmatter):
        session = frontmatter["session"]
        assert session.get("orchestrator") == "loop-streaming"

    def test_context_simple(self, frontmatter):
        session = frontmatter["session"]
        assert session.get("context") == "context-simple"


# ── YAML Frontmatter: Provider ───────────────────────────────────────────


class TestProvider:
    def test_has_providers(self, frontmatter):
        assert "providers" in frontmatter

    def test_provider_anthropic(self, raw_content):
        assert "provider-anthropic" in raw_content

    def test_model_claude_sonnet(self, raw_content):
        assert "claude-sonnet-4-5" in raw_content


# ── YAML Frontmatter: Hooks (A2A Server) ─────────────────────────────────


class TestHooksA2AServer:
    @pytest.fixture
    def hooks(self, frontmatter):
        return frontmatter.get("hooks", {})

    @pytest.fixture
    def a2a_hook_config(self, hooks):
        """Find the hooks-a2a-server entry and return its config."""
        for hook_entry in hooks if isinstance(hooks, list) else [hooks]:
            if isinstance(hook_entry, dict):
                # Could be {"hooks-a2a-server": {config}} or {"name": "hooks-a2a-server", "config": {...}}
                if "hooks-a2a-server" in hook_entry:
                    return hook_entry["hooks-a2a-server"]
                if hook_entry.get("name") == "hooks-a2a-server":
                    return hook_entry.get("config", {})
        pytest.fail("hooks-a2a-server not found in hooks")

    def test_has_hooks(self, frontmatter):
        assert "hooks" in frontmatter

    def test_port_8214(self, a2a_hook_config):
        assert a2a_hook_config["port"] == 8214

    def test_agent_name_cortex(self, a2a_hook_config):
        assert a2a_hook_config["agent_name"] == "cortex"

    def test_agent_description(self, a2a_hook_config):
        desc = a2a_hook_config["agent_description"]
        assert "attention" in desc.lower()
        assert "notification" in desc.lower()

    def test_has_5_agent_skills(self, a2a_hook_config):
        skills = a2a_hook_config["agent_skills"]
        expected = [
            "attention-state",
            "notification-score",
            "focus-mode-status",
            "notification-history",
            "notification-content-search",
        ]
        for skill in expected:
            assert skill in skills, f"Missing skill: {skill}"

    def test_realtime_response_false(self, a2a_hook_config):
        assert a2a_hook_config["realtime_response"] is False

    def test_mdns_false(self, a2a_hook_config):
        discovery = a2a_hook_config.get("discovery", {})
        assert discovery.get("mdns") is False

    def test_has_4_known_agents(self, a2a_hook_config):
        known = a2a_hook_config["known_agents"]
        assert len(known) == 4

    def test_known_agent_ai_os(self, a2a_hook_config):
        known = a2a_hook_config["known_agents"]
        ai_os = [a for a in known if a.get("name") == "ai-os"]
        assert len(ai_os) == 1
        assert "8210" in ai_os[0]["url"]
        assert ai_os[0]["tier"] == "trusted"

    def test_known_agent_lifeline(self, a2a_hook_config):
        known = a2a_hook_config["known_agents"]
        lifeline = [a for a in known if a.get("name") == "lifeline"]
        assert len(lifeline) == 1
        assert "8211" in lifeline[0]["url"]
        assert lifeline[0]["tier"] == "trusted"

    def test_known_agent_lifeline_demo(self, a2a_hook_config):
        known = a2a_hook_config["known_agents"]
        demo = [a for a in known if a.get("name") == "lifeline-demo"]
        assert len(demo) == 1
        assert "8212" in demo[0]["url"]
        assert demo[0]["tier"] == "trusted"

    def test_known_agent_hive_slack(self, a2a_hook_config):
        known = a2a_hook_config["known_agents"]
        hive = [a for a in known if a.get("name") == "hive-slack"]
        assert len(hive) == 1
        assert "8213" in hive[0]["url"]
        assert hive[0]["tier"] == "trusted"


# ── YAML Frontmatter: Tools ──────────────────────────────────────────────


class TestTools:
    def test_has_tools(self, frontmatter):
        assert "tools" in frontmatter

    def test_has_tool_a2a(self, raw_content):
        assert "tool-a2a" in raw_content

    def test_has_tool_filesystem(self, raw_content):
        assert "tool-filesystem" in raw_content

    def test_filesystem_config_path(self, raw_content):
        # tool-filesystem should have write access to {server_root}/config
        assert "config" in raw_content


# ── Markdown Body: System Prompt Sections ─────────────────────────────────


class TestSystemPromptIdentity:
    """Section 1: Cortex A2A Responder header."""

    def test_has_cortex_a2a_responder_header(self, body):
        assert "Cortex A2A Responder" in body

    def test_mentions_autonomous(self, lower_body):
        assert "autonomous" in lower_body


class TestSystemPromptOperation:
    """Section 2: How You Operate."""

    def test_has_how_you_operate_section(self, body):
        assert "How You Operate" in body

    def test_mentions_receives_messages_from_peers(self, lower_body):
        assert "peers" in lower_body or "peer" in lower_body

    def test_mentions_no_human_interaction(self, lower_body):
        assert "no human" in lower_body or "without human" in lower_body

    def test_mentions_autonomous_answers(self, lower_body):
        assert "autonomous" in lower_body

    def test_mentions_concise_responses(self, lower_body):
        assert "concise" in lower_body

    def test_mentions_data_rich(self, lower_body):
        assert "data-rich" in lower_body or "data rich" in lower_body


class TestSystemPromptQueryHandling:
    """Section 3: Handling Incoming Queries."""

    def test_has_handling_incoming_queries_section(self, body):
        assert "Handling Incoming Queries" in body

    def test_mentions_notification_history(self, lower_body):
        assert "notification history" in lower_body

    def test_mentions_attention_state(self, lower_body):
        assert "attention state" in lower_body

    def test_mentions_notification_content_search(self, lower_body):
        assert (
            "notification content search" in lower_body
            or "content search" in lower_body
        )

    def test_mentions_focus_mode(self, lower_body):
        assert "focus mode" in lower_body


class TestSystemPromptProactiveBroadcasting:
    """Section 4: Proactive Broadcasting."""

    def test_has_proactive_broadcasting_section(self, body):
        assert "Proactive Broadcasting" in body

    def test_mentions_score_threshold(self, body):
        assert "0.9" in body

    def test_mentions_a2a_tool(self, lower_body):
        assert "a2a" in lower_body

    def test_mentions_ai_os_target(self, body):
        assert "ai-os" in body

    def test_mentions_proactive_trigger_rules(self, lower_body):
        assert "proactive" in lower_body and "trigger" in lower_body


class TestSystemPromptConfigFiles:
    """Section 5: Configuration Files."""

    def test_has_configuration_files_section(self, body):
        assert "Configuration Files" in body or "Configuration" in body

    def test_mentions_attention_rules_path(self, body):
        assert "config/attention-rules.md" in body

    def test_mentions_a2a_network_path(self, body):
        assert "context/a2a-network.md" in body


class TestSystemPromptCommonBase:
    """Include of common system base."""

    def test_includes_common_system_base(self, body):
        assert "common-system-base.md" in body
